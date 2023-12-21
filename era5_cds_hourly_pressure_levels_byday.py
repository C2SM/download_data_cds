#!/usr/bin/env python

# *******************************************************************************
#                         U S E R  *  O P T I O N S
# *******************************************************************************

variables = ['cc', 'r', 'u', 'v']

startyr=1980
endyr=1980
#month_list=['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12']
month_list=['12']
path=f'/net/atmos/data/era5_cds/original/'
overwrite=False

# -------------------------------------------------
# Getting libraries and utilities
# -------------------------------------------------
import os
import json
import cdsapi
import logging
import calendar

# -------------------------------------------------
# Create a simple logger
# -------------------------------------------------

logging.basicConfig(format='%(asctime)s | %(levelname)s : %(message)s',
                     level=logging.INFO)
logger = logging.getLogger()

# -------------------------------------------------
# Loading ERA5 variables's information as 
# python Dictionary from JSON file
# -------------------------------------------------
long_names = list()
old_names = list()
units = list()
with open('ERA5_variables.json', 'r') as jf:
    era5 = json.load(jf)

    for vname in variables:
        # Variable's long-name, old_name and unit
        vlong = era5[vname][0]
        vunit = era5[vname][1]
        vparam = era5[vname][2]

        long_names.append(vlong)
        units.append(vunit)
        old_names.append(f'var{vparam}')

logger.info(f'ERA5 variable info red from json file.')
logger.info(f'longnames: {long_names},')
logger.info(f'units: {units},')
logger.info(f'oldnames: {old_names}.')

# -------------------------------------------------
# Create directories if do not exist yet
# -------------------------------------------------
grib_path=f'{path}/grib/3D'
workdir=f'{path}/work/3D'
os.makedirs(path, exist_ok=True)
os.makedirs(workdir, exist_ok=True)

# -------------------------------------------------
# Actual CDS request
# -------------------------------------------------

c = cdsapi.Client()

for year in range(startyr, endyr+1):
    print(year)
    for month in month_list:
        print(month)
        num_days = calendar.monthrange(year, int(month))[1]
        days = [*range(1, num_days+1)]
        for day in days:
            day_str=f'{day:02d}'
            print(day_str)
            grib_file=f'{workdir}/Z_1hr_era5_{year}{month}{day_str}.grib'
            if not os.path.isfile(f'{grib_file}') or overwrite:  
                c.retrieve(
                    'reanalysis-era5-pressure-levels',
                    {
                        'product_type': 'reanalysis',
                        'format': 'grib',
                        'variable': long_names,
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
                    grib_file)        

            os.system(f'cdo -f nc4 copy {grib_file} {workdir}/Z_1hr_era5_{year}{month}{day_str}.nc')

            for v, varname in enumerate(variables):
                archive=f'{path}/{varname}/1hr/{year}/{month}'
                os.makedirs(archive, exist_ok=True)

                print(f'{old_names[v]}')
                print(f'{workdir}/Z_1hr_era5_{year}{month}{day_str}.nc')
                print(f'{workdir}/{old_names[v]}_1hr_era5_{year}{month}{day_str}.nc')
                os.system(f'ncks -v {old_names[v]} {workdir}/Z_1hr_era5_{year}{month}{day_str}.nc {workdir}/{old_names[v]}_1hr_era5_{year}{month}{day_str}.nc')

                os.system(f'ncatted -a long_name,{old_names[v]},c,c,"{long_names[v]}" {workdir}/{old_names[v]}_1hr_era5_{year}{month}{day_str}.nc {workdir}/{old_names[v]}_1hr_era5_{year}{month}{day_str}_ncatted.nc')
                os.system(f'ncatted -a units,{old_names[v]},c,c,"{units[v]}" {workdir}/{old_names[v]}_1hr_era5_{year}{month}{day_str}_ncatted.nc {workdir}/{old_names[v]}_1hr_era5_{year}{month}{day_str}_ncatted2.nc')
                os.system(f'cdo setname,{varname} {workdir}/{old_names[v]}_1hr_era5_{year}{month}{day_str}.nc {archive}/{varname}_1hr_era5_{year}{month}{day_str}.nc')

            #os.system(f'rm {workdir}/*')
