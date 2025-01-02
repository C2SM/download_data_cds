#!/usr/bin/env python

import os
import cdsapi

var='sp'
long_name='surface_pressure'
startyr=1986
endyr=2021
archive=f'/net/atmos/data/cerra/original/{var}'

if (os.access(archive, os.F_OK) == False):
    os.makedirs(archive)

for year in range(startyr, endyr+1):
    grib_file = f'{archive}/{var}_3hr_cerra_{year}.grib'
    ncfile = f'{archive}/{var}_3hr_cerra_{year}.nc'

    dataset = "reanalysis-cerra-single-levels"
    request = {
        "variable": [f'{long_name}'],
        "level_type": "surface_or_atmosphere",
        "data_type": ["reanalysis"],
        "product_type": ["analysis"],
        "year": [f'{year}'],
        'month': [
            '01', '02', '03',
            '04', '05', '06',
            '07', '08', '09',
            '10', '11', '12',
        ],
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

    os.system(f'cdo -f nc copy {grib_file} {ncfile}')
    os.system(f'rm {grib_file}')
