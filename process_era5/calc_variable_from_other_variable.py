#!/usr/bin/env python3
# -*- coding: utf-8 -*-
'''
File Name : calc_variable_from_other_variable.py
Author: Ruth Lorenz (ruth.lorenz@c2sm.ethz.ch)
Created: 08/12/2023
Purpose: some variables do not exist in ERA5 but in CMIP
	those variables need to be calculated from other variables
	that do exist in ERA5
'''

import xarray as xr
import numpy as np
import glob
import logging
import os
import time
from datetime import datetime


####################
### INPUT        ###
####################

indir = "/net/atmos/data/era5_cds/processed/v2/"
variables_in = ["d2m", "tas"]
variable_out = "hurs"
freq = "day"
grid = "native"
syear=1941
eyear=1979
time_chk=1
lat_chk=46
lon_chk=22

outdir = f"{indir}{variable_out}/{freq}/{grid}/"

if not os.path.exists(outdir):
    os.makedirs(outdir)

# Define logfile and logger
seconds = time.time()
local_time = time.localtime(seconds)
# Name the logfile after first of all inputs
LOG_FILENAME = (f'logfiles/logging_calc_{variable_out}'
                f'_{local_time.tm_year}{local_time.tm_mon}'
                f'{local_time.tm_mday}{local_time.tm_hour}{local_time.tm_min}'
                f'.out')

logging.basicConfig(filename=LOG_FILENAME,
                    filemode='w',
                    format='%(levelname)s %(asctime)s: %(message)s',
                    level=logging.INFO)
logger = logging.getLogger(__name__)

def compute_wind_from_u_v(u_comp, v_comp):
    '''
    Calculates Wind Speed from U and V components

    Input:
    u_comp: U Wind component
    v_comp: V Wind component

    Returns:
    Wind speed in m s-1 
    '''

    u_square = np.square(u_comp)
    v_square = np.square(v_comp)
    uv_sum = np.add(u_square, v_square)
                
    sfcW = np.sqrt(uv_sum)

    return sfcW

def calculate_rlds_from_strd_str(strd, str):
	'''
	Calculate long-wave downwelling radiation at surface

	Input:
	strd: Surface long-wave (thermal) radiation downwards
	str: Surface net long-wave (thermal) radiation

	Returns:
	rlds (Surface Downwelling Longwave Radiation ) in W m-2
	'''
	
	return np.subtract(strd, str)


def calculate_relative_humidity(dewpoint_temp, temperature):
	'''
	Calculate relative humidity from dew point temperature and temperature
	https://journals.ametsoc.org/view/journals/bams/86/2/bams-86-2-225.xml?tab_body=fulltext-display

	Input:
	dewpoint_temp: dewpoint temperature at 2m
	temperature: temperaturea at 2m

	Returns:
	hurs: relative humidity at 2m
	'''
    # Constants for the calculation
	A1 = 17.625
	B1 = 243.04
	C1 = 610.94

	t = 273.15

	temperature_C = temperature - t
	dewpoint_temp_C = dewpoint_temp - t

	# Calculate saturation vapor pressure
	alpha = ((A1 * temperature_C) / (B1 + temperature_C))
	saturation_vapor_pressure = C1 * np.exp(alpha)

	# Calculate actual vapor pressure
	beta = ((A1 * dewpoint_temp_C) / (B1 + dewpoint_temp_C))
	actual_vapor_pressure = C1 * np.exp(beta)

	# Calculate relative humidity
	relative_humidity = (actual_vapor_pressure / saturation_vapor_pressure) * 100

	return relative_humidity


def main():

	t0 = datetime.now()

	# Read data
	# read first variable
	var = variables_in[0]

	for year in range(syear, eyear + 1):
		logger.info(f"Processing year {year}.")

		data_path = f'{indir}{var}/{freq}/{grid}/{year}'
		filename = f'{var}_{freq}_era5_*.nc'
		filelist = sorted(glob.glob(f'{data_path}/{filename}'))
		if len(filelist) == 0:
			logger.error('No matching files found for %s!', data_path)

		logger.info('%s files found, start processing:', len(filelist))
		for ifile in filelist:
			logger.info("Processing file %s", ifile)
			# find matching file with second variable
			ifile_2 = ifile.replace(var, variables_in[1])
			if os.path.isfile(ifile_2):
				logger.info("second file found")
			else:
				logger.warning("No matching second file found, continuing.")
				continue

			try:
				ds_1 = xr.open_dataset(ifile, chunks={'time':time_chk, 'lat':lat_chk, 'lon':lon_chk}, mask_and_scale=True)
				logger.info('Open data ifile')
			except OSError:
				logger.warning('Could not open file %s, continuing.', ifile)
				continue
			try:
				ds_2 = xr.open_dataset(ifile_2, chunks={'time':time_chk, 'lat':lat_chk, 'lon':lon_chk}, mask_and_scale=True)
				logger.info('Open data ifile_2')
			except OSError:
				logger.warning('Could not open file %s, continuing.', ifile_2)
				continue

			if len(variables_in) > 2:
				# find matching file with third variable
				ifile_3 = ifile.replace(var, variables_in[2])
				if os.path.isfile(ifile_3):
					logger.info("third file found")
				else:
					logger.warning("No matching third file found, continuing.")
					continue
				try:
					ds_3 = xr.open_dataset(ifile_3, chunks={'time':time_chk, 'lat':lat_chk, 'lon':lon_chk}, mask_and_scale=True)
					logger.info('Open data ifile_3')
				except OSError:
					logger.warning('Could not open file %s, continuing.', ifile_3)
					continue
				

			if variable_out == 'sfcWind':
				logger.info('Processing variable sfcWind')

				da_out = compute_wind_from_u_v(ds_1["uas"], ds_2["vas"])
				standard_name="wind_speed"
				long_name="Near-Surface Wind Speed"
				unit="m s-1"
			elif variable_out=="rlds":
				logger.info('Processing variable rlds')

				da_out = calculate_rlds_from_strd_str(ds_1["strd"], ds_2["rls"])
				standard_name="surface_downwelling_longwave_flux_in_air"
				long_name="Surface Downwelling Longwave Radiation"
				unit="W m-2"
			elif variable_out=="hurs":
				logger.info('Processing variable hurs')

				da_out = calculate_relative_humidity(ds_1["d2m"], ds_2["tas"])
				standard_name="relative_humidity"
				long_name="Near-Surface Relative Humidity"
				unit="%"
			else:
				logger.error("Not implemented output variable %s", variable_out)

			ds_2.close()
			if len(variables_in) > 2:
				ds_3.close()
				
			try:
				cell_methods = ds_1[var].attrs["cell_methods"]
			except KeyError:
				logger.warning("No cell_methods attribute!")
				cell_methods =  "unknown"

			dict_attr ={"standard_name": standard_name, "long_name": long_name, "units": unit,
						"cell_methods": cell_methods,
						"_FillValue": 1.e+20}

			ds_out = da_out.assign_attrs(dict_attr).to_dataset(name=variable_out)
			filename_out = ifile.replace(var , variable_out)

			year = filename_out.split('/')[10]
			outdir_year = f'{outdir}{year}'

			if not os.path.exists(outdir_year):
				os.makedirs(outdir_year)

			ds_out.to_netcdf(filename_out, encoding={variable_out: {"chunksizes": (time_chk, lat_chk, lon_chk)}})
			logger.info("Data written to %s", filename_out)

	dt = datetime.now() - t0
	logger.info('Success! All files processed, total duration: %s', dt)

if __name__ == '__main__':
    main()
