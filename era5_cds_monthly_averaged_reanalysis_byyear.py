#!/usr/bin/env python

import os
import cdsapi

c = cdsapi.Client()

var='10si'
oldname='var207'
long_name='10m_wind_speed'
startyr=1940
endyr=2022
archive=f'/net/atmos/data/ERA5/original/{var}/mon/'

if (os.access(archive, os.F_OK) == False):
    os.makedirs(archive)

for year in range(startyr, endyr+1):
    c.retrieve(
        'reanalysis-era5-single-levels-monthly-means',
        {
            'format': 'grib',
            'product_type': 'monthly_averaged_reanalysis',
            'variable': f'{long_name}',
            'year': f'{year}',
            'month': [
                '01', '02', '03',
                '04', '05', '06',
                '07', '08', '09',
                '10', '11', '12',
            ],
            'time': '00:00',
        },
        f'{archive}/{oldname}_mon_era5_{year}.grib')

    os.system(f'cdo -f nc copy {archive}/{oldname}_mon_era5_{year}.grib {archive}/{oldname}_mon_era5_{year}.nc')
    os.system(f'cdo chname,{oldname},{var} {archive}/{oldname}_mon_era5_{year}.nc {archive}/{var}_mon_era5_{year}.nc')
    os.system(f'rm {archive}/{oldname}_mon_era5_{year}.*')