#!/usr/bin/env python

# *******************************************************************************
#                         U S E R  *  O P T I O N S
# *******************************************************************************

variables = ['2d']

startyr=1986
endyr=1986
#month_list=['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12']
month_list=['08',]
path=f'/net/atmos/data/era5-land_cds/original/'
overwrite=True

# -------------------------------------------------
# Getting libraries and utilities
# -------------------------------------------------
import os
import json
import cdsapi
import logging

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

logger.info(f'ERA5-Land variable info red from json file.')
logger.info(f'longnames: {long_names},')
logger.info(f'units: {units},')
logger.info(f'oldnames: {old_names}.')

# -------------------------------------------------
# Create directories if do not exist yet
# -------------------------------------------------
grib_path=f'{path}/grib'
workdir=f'{path}/work'
os.makedirs(path, exist_ok=True)
os.makedirs(workdir, exist_ok=True)

# -------------------------------------------------
# Actual CDS request
# -------------------------------------------------

for year in range(startyr, endyr+1):
    for month in month_list:
        archive=f'{grib_path}/{year}'
        if (os.access(archive, os.F_OK) == False):
            os.makedirs(archive)
        grib_file = f'{archive}/variables_1hr_era5-land_{year}{month}.grib'
        nc_file = f'{workdir}/variables_1hr_era5-land_{year}{month}.nc'
        if not os.path.isfile(f'{grib_file}') or overwrite:
            dataset = "reanalysis-era5-land"
            request = {
                'variable': long_names,
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
                "data_format": "grib",
                "download_format": "unarchived"
            }
            client = cdsapi.Client()
            client.retrieve(dataset, request, f'{grib_file}')

        # convert grib file to netcdf
        os.system(f'cdo -f nc copy {grib_file} {nc_file}')

        # extract individual variables and change metadata
        for v, var in enumerate(variables):
            path_out=f'{path}/{var}/1hr/{year}'
            os.makedirs(path_out, exist_ok=True)

            os.system(f'ncks -v {old_names[v]} {nc_file} {workdir}/{old_names[v]}_1hr_era5-land_{year}{month}.nc')
            os.system(f'ncatted -a long_name,{old_names[v]},c,c,{long_names[v]} {workdir}/{old_names[v]}_1hr_era5-land_{year}{month}.nc {workdir}/{old_names[v]}_1hr_era5-land_{year}{month}_ncatted.nc')
            os.system(f'ncatted -a units,{old_names[v]},c,c,"{units[v]}" {workdir}/{old_names[v]}_1hr_era5-land_{year}{month}_ncatted.nc {workdir}/{old_names[v]}_1hr_era5-land_{year}{month}_ncatted2.nc')
            os.system(f'cdo setname,{var} {workdir}/{old_names[v]}_1hr_era5-land_{year}{month}_ncatted2.nc {path_out}/{var}_1hr_era5-land_{year}{month}.nc')
        os.system(f'rm {workdir}/*_1hr_era5-land_{year}{month}*.nc')
