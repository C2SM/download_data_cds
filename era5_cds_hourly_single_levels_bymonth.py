#!/usr/bin/env python

import os
import cdsapi

c = cdsapi.Client()

var='2t'
oldname='var167'
long_name='2m_temperature'
units='K'
startyr=2022
endyr=2022
path=f'/net/atmos/data/era5_cds/original/{var}/1hr/'

for year in range(startyr, endyr+1):
    for month in ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12']:
        archive=f'{path}/{year}'
        if (os.access(archive, os.F_OK) == False):
            os.makedirs(archive)   
        c.retrieve(
            'reanalysis-era5-single-levels',
            {
                'product_type': 'reanalysis',
                'format': 'grib',
                'variable': f'{long_name}',
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
                    '00:00', '01:00', '02:00',
                    '03:00', '04:00', '05:00',
                    '06:00', '07:00', '08:00',
                    '09:00', '10:00', '11:00',
                    '12:00', '13:00', '14:00',
                    '15:00', '16:00', '17:00',
                    '18:00', '19:00', '20:00',
                    '21:00', '22:00', '23:00',
                ],
            },
        f'{archive}/{oldname}_1hr_era5_{year}{month}.grib')

        os.system(f'cdo -f nc copy {archive}/{oldname}_1hr_era5_{year}{month}.grib {archive}/{oldname}_1hr_era5_{year}{month}.nc')
        os.system(f'ncatted -a standard_name,{oldname},c,c,{long_name} {archive}/{oldname}_1hr_era5_{year}{month}.nc {archive}/{oldname}_1hr_era5_{year}{month}_ncatted.nc')
        os.system(f'ncatted -a units,{oldname},c,c,{units} {archive}/{oldname}_1hr_era5_{year}{month}_ncatted.nc {archive}/{oldname}_1hr_era5_{year}{month}_ncatted2.nc')
        os.system(f'cdo setname,{var} {archive}/{oldname}_1hr_era5_{year}{month}.nc {archive}/{var}_1hr_era5_{year}{month}.nc')
        os.system(f'rm {archive}/{oldname}_1hr_era5_{year}{month}*')
