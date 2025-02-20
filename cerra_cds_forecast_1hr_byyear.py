#!/usr/bin/env python

import os
import cdsapi

var='tp'
long_name='total_precipitation'
startyr=1986
endyr=2021
month_list=['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12']
archive=f'/net/atmos/data/cerra/original/{var}'
workdir=f'/net/atmos/data/cerra/original/{var}/work'

overwrite = False

if (os.access(archive, os.F_OK) == False):
    os.makedirs(archive)
if (os.access(workdir, os.F_OK) == False):
    os.makedirs(workdir)

dataset = "reanalysis-cerra-single-levels"

for year in range(startyr, endyr+1):
    for month in month_list:

        request = {
            "variable": [f'{long_name}'],
            "level_type": "surface_or_atmosphere",
            "data_type": ["reanalysis"],
            "product_type": "forecast",
            "year": [f'{year}'],
            "month": [f'{month}'],
            "day": [
                "01", "02", "03",
                "04", "05", "06",
                "07", "08", "09",
                "10", "11", "12",
                "13", "14", "15",
                "16", "17", "18",
                "19", "20", "21",
                "22", "23", "24",
                "25", "26", "27",
                "28", "29", "30",
                "31"
            ],
            "time": [
                "00:00", "03:00", "06:00",
                "09:00", "12:00", "15:00",
                "18:00", "21:00"
            ],
            "leadtime_hour": [
                "1",
                "2",
                "3"
            ],
            "data_format": "grib"
        }
        grib_file= f'{workdir}/{var}_1hr_cerra_{year}{month}.grib'
        #tmpfile = f'{workdir}/{var}_1hr_cerra_{year}{month}_setgridregular.grib'
        ncfile = f'{archive}/{var}_1hr_cerra_{year}{month}.nc'
        if not os.path.isfile(grib_file) or overwrite:
            client = cdsapi.Client()
            client.retrieve(dataset, request, grib_file)

        if not os.path.isfile(ncfile) or overwrite:
            #os.system(f"cdo -t ecmwf -setgridtype,regular {grib_file} {tmpfile}")
            #os.system(f"grib_to_netcdf -o  {ncfile} {grib_file}")
            os.system(f"cdo -f nc copy {grib_file} {ncfile}")
            #os.system(f'rm {grib_file}')