#!/usr/bin/env python

# -------------------------------------------------
# Getting libraries and utilities
# -------------------------------------------------
import os
import sys
import json
import cdsapi
import logging
import calendar
import xarray as xr
import glob

# -------------------------------------------------
# Create a simple logger
# -------------------------------------------------

logging.basicConfig(format='%(asctime)s | %(levelname)s : %(message)s',
                     level=logging.INFO)
logger = logging.getLogger()

# -------------------------------------------------
# Read Config
# -------------------------------------------------

def read_config():
    __location__ = os.path.realpath(
        os.path.join(os.getcwd(), 'configs'))

    config = {}
    with open(os.path.join(__location__, 'Config.ini'), 'r') as f:
        for line in f:
            if '=' in line:
                k,v = line.split('=', 1)
                if '"' in v:
                    c = v.replace('"', '').strip()
                    if ',' in c:
                        c = c.split(',')
                elif 'True' in v:
                    c = True
                elif 'False' in v:
                    c = False
                else:
                    c = int(v)
                config[k.strip()] = c

    return config


# -------------------------------------------------
# Read ERA5 info from JSON file
# -------------------------------------------------

def read_era5_info(vname):
    '''
    Loading ERA5 variables's information as 
    python Dictionary from JSON file

    Input:
    a string with the ERA5 variable short name to be processed
 
    Return:
    dict with variable infos
    '''
    era5_info = dict()

    with open('ERA5_variables.json', 'r') as jf:
        era5 = json.load(jf)

        # Variable's long-name, param and unit
        vlong = era5[vname][0]
        vunit = era5[vname][1]
        vparam = era5[vname][2]
        vcmip = era5[vname][6]
        unitcmip = era5[vname][7]

        era5_info["short_name"] = vname
        era5_info["long_name"] = vlong
        era5_info["unit"] = vunit
        era5_info["param"] = vparam
        era5_info["cmip_name"] = vcmip
        era5_info["cmip_unit"] = unitcmip

    return era5_info


# -------------------------------------------------
# Read CMIP6 info from JSON file
# -------------------------------------------------
def read_cmip_info(cmip_name):
    '''
    Loading CMIP variables's information from JSON file

    Input:
    A short CMIP variable name such as "tas"
 
    Return:
    standrtad_name and long_name of that variable
    '''

    with open("/net/co2/c2sm/rlorenz/scripts/cmip6-cmor-tables/Tables/CMIP6_Amon.json") as jf_cmip:
        cmip6 = json.load(jf_cmip)

        cmip_standard_name = cmip6["variable_entry"][cmip_name]["standard_name"]
        cmip_long_name = cmip6["variable_entry"][cmip_name]["long_name"]

    return (cmip_standard_name, cmip_long_name)


def convert_netcdf_add_era5_info(grib_file, workdir, era5_info, year, month):
    '''
    Convert grib file to netcdf and add meaningful metadata
    '''

    tmpfile = f'{workdir}/tmp_var{era5_info["param"]}_era5'
    tmp_outfile = f'{workdir}/{era5_info["short_name"]}_era5_{year}{month}.nc'
    os.system(f'cdo -f nc4 copy {grib_file} {tmpfile}.nc')
    os.system(f'ncatted -O -a units,var{era5_info["param"]},c,c,"{era5_info["unit"]}" {tmpfile}.nc {tmpfile}_ncatted.nc')
    os.system(f'cdo setname,{era5_info["short_name"]} {tmpfile}_ncatted.nc {tmp_outfile}')

    return tmp_outfile


def convert_cc(tmp_outfile, workdir, era5_info, year, month):

    os.system(f'cdo mulc,100 {tmp_outfile} {workdir}/{era5_info["short_name"]}_era5_{year}{month}_mulc.nc')
    os.system(f'rm {workdir}/{era5_info["short_name"]}_era5_{year}{month}.nc')
    os.system(f'ncatted -a units,{era5_info["short_name"]},m,c,"{era5_info["cmip_unit"]}" {workdir}/{era5_info["short_name"]}_era5_{year}{month}_mulc.nc {tmp_outfile}')

    return tmp_outfile

def convert_era5_to_cmip(tmp_outfile, outfile, workdir, era5_info, cmip_info, year, month):

    tmpfile = f'{workdir}/{era5_info["short_name"]}_era5_{year}{month}'
    os.system(f'ncatted -O -a long_name,{era5_info["short_name"]},c,c,"{cmip_info[1]}" {tmp_outfile} {tmpfile}_ncatted2.nc')
    os.system(f'ncatted -O -a standard_name,{era5_info["short_name"]},c,c,"{cmip_info[0]}" {tmpfile}_ncatted2.nc {tmpfile}_ncatted3.nc')
    os.system(f'ncks -O -4 -D 4 --cnk_plc=g3d --cnk_dmn=time,1 --cnk_dmn=plev,{plev} --cnk_dmn=lat,{lat_chk} --cnk_dmn=lon,{lon_chk} {tmpfile}_ncatted3.nc {tmpfile}_chunked.nc')
    os.system(f'ncrename -v {era5_info["short_name"]},{era5_info["cmip_name"]} {tmpfile}_chunked.nc {outfile}')

    return outfile


# -------------------------------------------------

def main():

    # -------------------------------------------------
    # Read config
    # -------------------------------------------------
    # read config file
    cfg = read_config()
    logger.info(f'Read configuration is: {cfg}')
    print(f'Read configuration is: {cfg}')

    # put read content from config into variables for easier use
    variables=cfg["variables"]
    path = cfg["path"]
    path_proc = cfg["path_proc"]
    work_path = cfg["work_path"]

    startyr=cfg["startyr"]
    endyr=cfg["endyr"]
    overwrite=cfg["overwrite"]
    time_chk=cfg["time_chk"]
    lat_chk=cfg["lat_chk"]
    lon_chk=cfg["lon_chk"]

    # -------------------------------------------------
    # Create directories if do not exist yet
    # -------------------------------------------------
    os.makedirs(work_path, exist_ok=True)
    os.makedirs(path_proc, exist_ok=True)



    for v, var in enumerate(variables):
        grib_path = f'{path}/{var}'

        # -------------------------------------------------
        # read ERA5_variables.json
        # -------------------------------------------------
        era5_info = read_era5_info(var)
        logger.info(f'ERA5 variable info red from json file.')
        logger.info(f'longname: {era5_info["long_name"]},')
        logger.info(f'unit: {era5_info["unit"]},')
        logger.info(f'oldname: var{era5_info["param"]},')
        logger.info(f'cmipname: {era5_info["cmip_name"]},')
        logger.info(f'cmipunit: {era5_info["cmip_unit"]}.')

        # read cmip standard_name and long_name from cmip6-cmor-tables
        cmip_info = read_cmip_info(era5_info["cmip_name"])

        for year in range(startyr, endyr+1):
            logger.info(f'Processing year {year}.')
            proc_archive=f'{path_proc}/{era5_info["cmip_name"]}/day/native/{year}'
            os.makedirs(proc_archive, exist_ok=True)
            for month in month_list:
                grib_file = f'{grib_path}/E5pl00_1D_{year}-{month}_{era5_info["param"]}.grb'
                outfile = f'{proc_archive}/{era5_info["cmip_name"]}_day_era5_{year}{month}.nc'

                tmp_outfile = convert_netcdf_add_era5_info(grib_file, work_path, era5_info, year, month)

                # check if unit needs to be changed from era5 variable to cmip variable
                if (era5_info["unit"] != era5_info["cmip_unit"]):
                    if var == "cc":
                        logger.info(f'Unit for cc needs to be changed from {era5_info["unit"]} to {era5_info["cmip_unit"]}.')

                        tmp_outfile = convert_cc(tmp_outfile, workpath, era5_info, year, month)
                    else:
                        logger.error(f'Conversion of unit for variable {var} is not implemented!')
                        sys.exit(1)

                # extract number of p-levels for chunking
                with xr.open_dataset(f'{tmp_outfile}') as ds:
                    plev = ds.sizes['plev']

                outfile_name = convert_era5_to_cmip(tmp_outfile, outfile, workpath, era5_info, cmip_info, year, month)
                
                logger.info(f'File {outfile_name} written.')
        # -------------------------------------------------
        # Clean up
        # -------------------------------------------------
        os.system(f'rm {workdir}/{var}_*')
    #os.system(f'rm {grib_path}/*')

if __name__ == "__main__":
    main()
