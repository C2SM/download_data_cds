#!/usr/bin/env python

import os
import cdsapi

c = cdsapi.Client()

var='2t'
oldname='var167'
long_name='2m_temperature'
startyr=2023
endyr=2024
archive=f'/net/atmos/data/ERA5/original/{var}/mon/'

if (os.access(archive, os.F_OK) == False):
    os.makedirs(archive)

for year in range(startyr, endyr+1):
    grib_file = f'{archive}/{oldname}_mon_era5_{year}.grib'
    dataset = "reanalysis-era5-single-levels-monthly-means"
    request = {
        "product_type": ["monthly_averaged_reanalysis"],
        "variable": [
            f'{long_name}'
        ],
        "year": [f'{year}'],
        "month": [
            "01", "02", "03",
            "04", "05", "06",
            "07", "08", "09",
            "10", "11", "12"
        ],
        "time": ["00:00"],
        "data_format": "grib",
        "download_format": "unarchived"
        }
    client = cdsapi.Client()
    client.retrieve(dataset, request, grib_file)

    os.system(f'cdo -f nc copy {grib_file} {archive}/{oldname}_mon_era5_{year}.nc')
    os.system(f'cdo chname,{oldname},{var} {archive}/{oldname}_mon_era5_{year}.nc {archive}/{var}_mon_era5_{year}.nc')
    os.system(f'rm {archive}/{oldname}_mon_era5_{year}.*')