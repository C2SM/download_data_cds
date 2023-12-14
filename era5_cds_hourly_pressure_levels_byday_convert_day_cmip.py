#!/usr/bin/env python

# *******************************************************************************
#                         U S E R  *  O P T I O N S
# *******************************************************************************

variables = ['cc']

startyr=1980
endyr=1980
#month_list=['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12']
month_list=['12']
path=f'/net/atmos/data/era5_cds/original/'
path_proc=f'/net/atmos/data/era5_cds/processed/v2/'
overwrite=False
time_chk=1
lat_chk=46
lon_chk=22

# -------------------------------------------------
# Getting libraries and utilities
# -------------------------------------------------
import os
import sys
import json
import cdsapi
import logging
import calendar
import xarray

# -------------------------------------------------
# Create a simple logger
# -------------------------------------------------

logging.basicConfig(format='%(asctime)s | %(levelname)s : %(message)s',
                     level=logging.INFO)
logger = logging.getLogger()


def read_era5_info(variable_list):
    '''
    Loading ERA5 variables's information as 
    python Dictionary from JSON file

    Input:
    a list with all the ERA5 variable short names to be processed
 
    Return:
    lists with variable infos
    '''
    long_names = list()
    old_names = list()
    units = list()
    cmip_names = list()
    cmip_units = list()

    with open('ERA5_variables.json', 'r') as jf:
        era5 = json.load(jf)

        for vname in variable_list:
            # Variable's long-name, old_name and unit
            vlong = era5[vname][0]
            vunit = era5[vname][1]
            vparam = era5[vname][2]
            vcmip = era5[vname][6]
            unitcmip = era5[vname][7]

            long_names.append(vlong)
            units.append(vunit)
            old_names.append(f'var{vparam}')
            cmip_names.append(vcmip)
            cmip_units.append(unitcmip)

    return long_names, units, old_names, cmip_names, cmip_units


def main():

    # -------------------------------------------------
    # Create directories if do not exist yet
    # -------------------------------------------------
    grib_path=f'{path}/grib/3D'
    workdir=f'{path}/work/3D'
    os.makedirs(path, exist_ok=True)
    os.makedirs(grib_path, exist_ok=True)
    os.makedirs(workdir, exist_ok=True)

    # read ERA5_variables.json
    long_names, units, old_names, cmip_names, cmip_units = read_era5_info(variables)
    logger.info(f'ERA5 variable info red from json file.')
    logger.info(f'longnames: {long_names},')
    logger.info(f'units: {units},')
    logger.info(f'oldnames: {old_names},')
    logger.info(f'cmipnames: {cmip_names},')
    logger.info(f'cmipunits: {cmip_units}.')

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
                grib_file=f'{grib_path}/Z_1hr_era5_{year}{month}{day_str}.grib'
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

                    # extract single variables and add metadata and meaningful variable names
                    print(f'{old_names[v]}')
                    print(f'{workdir}/Z_1hr_era5_{year}{month}{day_str}.nc')
                    print(f'{workdir}/{old_names[v]}_1hr_era5_{year}{month}{day_str}.nc')
                    os.system(f'ncks -O -v {old_names[v]} {workdir}/Z_1hr_era5_{year}{month}{day_str}.nc {workdir}/{old_names[v]}_1hr_era5_{year}{month}{day_str}.nc')

                    os.system(f'ncatted -a long_name,{old_names[v]},c,c,"{long_names[v]}" {workdir}/{old_names[v]}_1hr_era5_{year}{month}{day_str}.nc {workdir}/{old_names[v]}_1hr_era5_{year}{month}{day_str}_ncatted.nc')
                    os.system(f'ncatted -a units,{old_names[v]},c,c,"{units[v]}" {workdir}/{old_names[v]}_1hr_era5_{year}{month}{day_str}_ncatted.nc {workdir}/{old_names[v]}_1hr_era5_{year}{month}{day_str}_ncatted2.nc')
                    os.system(f'cdo setname,{varname} {workdir}/{old_names[v]}_1hr_era5_{year}{month}{day_str}.nc {workdir}/{varname}_1hr_era5_{year}{month}{day_str}.nc')

                    # check if unit needs to be changed from era5 variable to cmip variable
                    if (units[v] != cmip_units[v]):
                        if varname == "cc":
                            logger.info(f'Unit for cc needs to be changed from {units[v]} to {cmip_units[v]}.')
                            os.system(f'cdo mulc,100 {workdir}/{varname}_1hr_era5_{year}{month}{day_str}.nc {workdir}/{varname}_1hr_era5_{year}{month}{day_str}_mulc.nc')
                            os.system(f'rm {workdir}/{varname}_1hr_era5_{year}{month}{day_str}.nc')
                            os.system(f'ncatted -a units,{varname},m,c,"{cmip_units[v]}" {workdir}/{varname}_1hr_era5_{year}{month}{day_str}_mulc.nc {workdir}/{varname}_1hr_era5_{year}{month}{day_str}.nc')
                        elif varname == "z":
                            logger.info(f'Unit for z needs to be changed from {units[v]} to {cmip_units[v]}.')
                            os.system(f'cdo sqrt {workdir}/{varname}_1hr_era5_{year}{month}{day_str}.nc {workdir}/{varname}_1hr_era5_{year}{month}{day_str}_sqrt.nc')
                            os.system(f'rm {workdir}/{varname}_1hr_era5_{year}{month}{day_str}.nc')
                            os.system(f'ncatted -a units,{varname},m,c,"{cmip_units[v]}" {workdir}/{varname}_1hr_era5_{year}{month}{day_str}_sqrt.nc {workdir}/{varname}_1hr_era5_{year}{month}{day_str}.nc')

                        else:
                            logger.error(f'Conversion of unit for variable {varname} is not implemented!')
                            sys.exit(1)

                    # calculate daily means
                    os.system(f'cdo daymean {archive}/{varname}_1hr_era5_{year}{month}{day_str}.nc  {workdir}/{varname}_daymean_era5_{year}{month}{day_str}.nc')

                    s=0
                    if not os.path.isfile(f'{workdir}/{varname}_daymean_era5_{year}{month}{day_str}.nc'):
                        logger.warning(f'{workdir}/{varname}_daymean_era5_{year}{month}{day_str}.nc was not processed properly!')
                    else:
                        # clean up 1-hr data
                        os.system(f'rm {workdir}/{varname}_1hr_era5_{year}{month}{day_str}.nc')
                        os.system(f'rm {workdir}/{old_names[v]}_1hr_era5_{year}{month}{day_str}.nc')

            os.system(f'rm {grib_file}')
            os.system(f'rm {workdir}/Z_1hr_era5_{year}{month}{day_str}.nc')


        # concatenate daily files for each month and convert to cmip standards
        proc_archive=f'{path_proc}/{varname}/day/native/{year}'
        os.makedirs(proc_archive, exist_ok=True)

        for v, varname in enumerate(variables):
            outfile=f'{path_archive}/{cmip_names[v]}_day_era5_{year}{month}.nc'
            name_day_work=f'{workdir}/{varname}_daymean_era5_{year}{month}'

            # check if all days for this month are available
            daily_files = glob.glob(f'{name_day_work}??.nc')
            num_days_month = calendar.monthrange(year, month)[1]
            if (len(daily_files) != num_days_month):
                logger.error(f'Not all files for year {year} and month {month} are there!')
                sys.exit(1)
            else:
                os.system(f'cdo timemerge {name_day_work}??.nc {name_day_work}.nc')

            # extract number of p-levels for chunking
            with xr.open_dataset(f'{name_day_work}.nc') as ds:
                plev = ds.sizes['plev']

            os.system(f'ncatted -O -h -a comment,global,m,c,"Daily data aggregated as mean over calendar day 00:00:00 to 23:00:00." {name_day_work}.nc {name_day_work}_ncatted.nc')
            os.system(f'ncks -O -4 -D 4 --cnk_plc=g3d --cnk_dmn=time,1 --cnk_dmn=plev,{plev} --cnk_dmn=lat,{lat_ck} --cnk_dmn=lon,{lon_ck} {name_day_work}_ncatted.nc {name_day_work}_chunked.nc')
            os.system(f'ncrename -v {varname},{cmip_names[v]} {name_day_work}_chunked.nc {outfile}')

        #os.system(f'rm {workdir}/*')

if __name__ == "__main__":
    main()