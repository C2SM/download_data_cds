#!/usr/bin/env python

import os
import cdsapi

var='gph300'
long_name='geopotential'
startyr=1985
endyr=2021
path=f'/net/atmos/data/cerra/original/{var}'


c = cdsapi.Client()

for year in range(startyr, endyr+1):
    for month in ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12']:
        archive=f'{path}/{year}'
        if (os.access(archive, os.F_OK) == False):
            os.makedirs(archive)        
        c.retrieve(
        'reanalysis-cerra-pressure-levels',
        {
            'format': 'grib',
            'variable': f'{long_name}',
            'pressure_level': '300',
            'data_type': 'reanalysis',
            'product_type': 'analysis',
            'year': f'{year}',
            'month': f'{month}',
            'day': [
                '01', '02', '03',
                '04', '05', '06',
                '07', '08', '09',
                '10', '11', '12',
                '13', '14', '15',
                '16', '17', '18',
                '19', '20', '21',
                '22', '23', '24',
                '25', '26', '27',
                '28', '29', '30',
                '31',
            ],
            'time': [
                '00:00', '03:00', '06:00',
                '09:00', '12:00', '15:00',
                '18:00', '21:00',
            ],
        },
        f'{archive}/{var}_3hr_cerra_{month}{year}.grib')

        os.system(f'cdo -f nc copy {archive}/{var}_3hr_cerra_{month}{year}.grib {archive}/{var}_3hr_cerra_{month}{year}.nc')
        os.system(f'rm {archive}/{var}_3hr_cerra_{month}{year}.grib')