#!/usr/bin/env python

import os
import cdsapi
from pathlib import Path
import argparse
from functions.file_util import read_cerra_info

def main():
    # -------------------------------------------------
    # Parse command line input
    # -------------------------------------------------
    parser = argparse.ArgumentParser(
        description="Download CERRA data from the CDS API and convert from GRIB to NetCDF format."
    )
    parser.add_argument(
        "-v",
        "--variable",
        help="Name of the variable to download and process",
        required=True,
    )

    parser.add_argument(
        "-start",
        "--start_year",
        help="Start year for data download (inclusive)",
        required=True,
    )

    parser.add_argument(
        "-end",
        "--end_year",
        help="End year for data download (inclusive)",
        required=True,
    )
    parser.add_argument(
        "-o",
        "--overwrite",
        help="Whether to overwrite existing files (default: False)",
        action="store_true",
    )

    args = parser.parse_args()

    var=args.variable
    cerra_info = read_cerra_info(var)
    long_name = cerra_info['long_name']

    levels=["100", "200", "300", "500", "700", "1000", "2000", "3000", "5000",
        "7000", "10000", "15000", "20000", "25000", "30000", "40000",
        "50000", "60000", "70000", "75000", "80000", "82500",
        "85000", "87500", "90000", "92500", "95000", "97500", "100000"]
    startyr=int(args.start_year)
    endyr=int(args.end_year)
    path=f'/net/atmos/data/cerra/original/{var}'

    dataset = "reanalysis-cerra-pressure-levels"

    for year in range(startyr, endyr+1):
        for month in ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12']:
        #for month in ['10', '11', '12']:
            archive=f'{path}/{year}'
            grib_file = f'{archive}/{var}_3hr_cerra_{month}{year}.grib'
            ncfile = f'{archive}/{var}_3hr_cerra_{month}{year}.nc'

            if (os.access(archive, os.F_OK) == False):
                os.makedirs(archive)

            if not os.path.isfile(ncfile) or args.overwrite:
                request = {
                    "variable": [f"{long_name}"],
                    "pressure_level": levels,
                    "data_type": ["reanalysis"],
                    "product_type": ["analysis"],
                    "year": [f"{year}"],
                    "month": [f"{month}"],
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
                    "data_format": "grib"
                }
                client = cdsapi.Client()
                client.retrieve(dataset, request, grib_file)

                os.system(f'cdo -f nc4 sorttaxis {grib_file} {ncfile}')
                #os.system(f'rm {grib_file}')

if __name__ == "__main__":
    main()