#!/usr/bin/env python

import os
import cdsapi
from convert_grib_netcdf import grib_to_netcdf

var='gph300'
long_name='geopotential'
level=['300']
startyr=2023
endyr=2023
path=f'/net/atmos/data/cerra/original/{var}'


for year in range(startyr, endyr+1):
    for month in ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12']:
    #for month in ['08', '09', '10', '11', '12']:
        archive=f'{path}/{year}'
        if (os.access(archive, os.F_OK) == False):
            os.makedirs(archive)
        grib_file = f'{archive}/{var}_3hr_cerra_{month}{year}.grib'
        ncfile = f'{archive}/{var}_3hr_cerra_{month}{year}.nc'

        if (os.access(archive, os.F_OK) == False):
            os.makedirs(archive)
        dataset = "reanalysis-cerra-pressure-levels"
        request = {
            "variable": [f"{long_name}"],
            "pressure_level": level,
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

        #os.system(f'cdo -f nc copy {grib_file} {ncfile}')
        #os.system(f'rm {grib_file}')
        grib_to_netcdf(grib_file, ncfile, variable_name=var)