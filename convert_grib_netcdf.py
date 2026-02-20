import xarray as xr
import numpy as np
import re


def grib_to_netcdf(
    input_grib: str,
    output_nc: str,
    variable_name: str,
    calendar: str = "proleptic_gregorian"
    ):
    """
    Convert a GRIB file to NetCDF while preserving the exact time axis.
    Time is encoded as numeric hours since the GRIB reference time.
    """

    # --- Step 1: Load GRIB
    ds = xr.open_dataset(input_grib, engine="cfgrib",
                         backend_kwargs={"filter_by_keys": {"shortName": variable_name}})

    # --- Step 2: Get GRIB time units
    if "GRIB_units" in ds.time.attrs:
        units = ds.time.attrs["GRIB_units"]
    else:
        # fallback
        t0 = np.datetime64(ds.time.values.min(), "s")
        units = f"hours since {str(t0).replace('T',' ')}"
        print(f"[INFO] Using inferred units: {units}")

    # --- Step 3: extract reference datetime from units
    m = re.search(r"(\d{4}-\d{2}-\d{2}(?: \d{2}:\d{2}:\d{2})?)", units)
    if not m:
        raise ValueError(f"Could not parse reference time from units: {units}")

    ref_str = m.group(1)
    ref_dt64 = np.datetime64(ref_str.replace(" ", "T"))

    # --- Step 4: convert datetime64 → numeric hours
    hours = (ds.valid_time.values - ref_dt64) / np.timedelta64(1, "h")
    hours = hours.astype("float64")

    # --- Step 5: Replace time variable
    ds = ds.assign_coords(time=("time", hours))

    if "valid_time" in ds:
        ds = ds.drop_vars("valid_time")

    # --- Step 6: Set units + calendar as **attributes**
    ds.attrs["Conventions"] = "CF-1.10"
    ds["time"].attrs["standard_name"] = "time"
    ds["time"].attrs["units"] = units
    ds["time"].attrs["calendar"] = calendar
    ds["time"].attrs["long_name"] = "valid time"

    # time, lat, lon encoding without FillValues
    encoding = {variable_name: {"zlib": False, "shuffle": False},
        "time": {"_FillValue": None, "dtype": "d"},
        "longitude": {"_FillValue": None},
        "latitude": {"_FillValue": None}
    }

    # --- Step 7: Save NetCDF
    ds.to_netcdf(output_nc, unlimited_dims='time', engine="h5netcdf", encoding=encoding)

    print(f"Wrote NetCDF: {output_nc}")
    print(f"Time units: {units}")
    print(f"Calendar:   {calendar}")
    print(f"First times: {hours[:4]} ...")

    return
