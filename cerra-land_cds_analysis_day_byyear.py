#!/usr/bin/env python

import os
import cdsapi

c = cdsapi.Client()

var='tp'
long_name='total_precipitation'
startyr=1985
endyr=2021
archive=f'/net/atmos/data/cerra-land/original/{var}'

if (os.access(archive, os.F_OK) == False):
    os.makedirs(archive)

for year in range(startyr, endyr+1):
    c.retrieve(
        'reanalysis-cerra-land',
        {
            'format': 'grib',
            'variable': f'{long_name}',
            'level_type': 'surface',
            'product_type': 'analysis',
            'year': f'{year}',
            'month': [
                '01', '02', '03',
                '04', '05', '06',
                '07', '08', '09',
                '10', '11', '12',
            ],
            'day': [
                '01', '02', '03',
                '04', '05', '06',
                '07', '08', '09',
                '10', '11', '12',
                '13', '14', '15',
                '16', '17', '18',
                '19', '20', '21',
                '22', '23', '24',o
                '25', '26', '27',
                '28', '29', '30',
                '31',
            ],
            'time': '06:00',
        },
        f'{archive}/{var}_day_cerra-land_{year}.grib')

    os.system(f'cdo -f nc copy {archive}/{var}_day_cerra-land_{year}.grib {archive}/{var}_day_cerra-land_{year}.nc')
    os.system(f'rm {archive}/{var}_day_cerra-land_{year}.grib')