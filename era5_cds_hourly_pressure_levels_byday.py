#!/usr/bin/env python

import os
import cdsapi
import calendar

c = cdsapi.Client()

var=['cc', 'r']
oldname=['var248', 'var157']
long_name=['fraction_of_cloud_cover', 'relative_humidity']
units=['(0 - 1)', '%']
startyr=2022
endyr=2022
path=f'/net/atmos/data/era5_cds/original/'
workdir=f'{path}/work'

if (os.access(workdir, os.F_OK) == False):
    os.makedirs(workdir)

for year in range(startyr, endyr+1):
    print(year)
    for month in ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12']:
        print(month)
        num_days = calendar.monthrange(year, int(month))[1]
        days = [*range(1, num_days+1)]
        for day in days:
            day_str=f'{day:02d}'
            print(day_str)
            c.retrieve(
                'reanalysis-era5-pressure-levels',
                {
                    'product_type': 'reanalysis',
                    'format': 'grib',
                    'variable': long_name,
                    'pressure_level': [
                        '1', '2', '3',
                        '5', '7', '10',
                        '20', '30', '50',
                        '70', '100', '125',
                        '150', '175', '200',
                        '225', '250', '300',
                        '350', '400', '450',
                        '500', '550', '600',
                        '650', '700', '750',
                        '775', '800', '825',
                        '850', '875', '900',
                        '925', '950', '975',
                        '1000',
                    ],
                    'year': f'{year}',
                    'month': f'{month}',
                    'day': day_str,
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
                f'{workdir}/Z_1hr_era5_{year}{month}{day_str}.grib')        

            os.system(f'cdo -f nc copy {workdir}/Z_1hr_era5_{year}{month}{day_str}.grib {workdir}/Z_1hr_era5_{year}{month}{day_str}.nc')

            for v, varname in enumerate(var):
                path=f'/net/atmos/data/era5_cds/original/{varname}/1hr/'
                archive=f'{path}/{year}/{month}'
                if (os.access(archive, os.F_OK) == False):
                    os.makedirs(archive)
                print(f'{oldname[v]}')
                print(f'{workdir}/Z_1hr_era5_{year}{month}{day_str}.nc')
                print(f'{workdir}/{oldname[v]}_1hr_era5_{year}{month}{day_str}.nc')
                os.system(f'ncks -v {oldname[v]} {workdir}/Z_1hr_era5_{year}{month}{day_str}.nc {workdir}/{oldname[v]}_1hr_era5_{year}{month}{day_str}.nc')

                os.system(f'ncatted -a standard_name,{oldname[v]},c,c,"{long_name[v]}" {workdir}/{oldname[v]}_1hr_era5_{year}{month}{day_str}.nc {workdir}/{oldname[v]}_1hr_era5_{year}{month}{day_str}_ncatted.nc')
                os.system(f'ncatted -a units,{oldname[v]},c,c,"{units[v]}" {workdir}/{oldname[v]}_1hr_era5_{year}{month}{day_str}_ncatted.nc {workdir}/{oldname[v]}_1hr_era5_{year}{month}{day_str}_ncatted2.nc')
                os.system(f'cdo setname,{varname} {workdir}/{oldname[v]}_1hr_era5_{year}{month}{day_str}.nc {archive}/{varname}_1hr_era5_{year}{month}{day_str}.nc')

            #os.system(f'rm {workdir}/*')
