#!/bin/bash
# File Name: rename_all_files_in_folder.sh
# Author: Ruth Lorenz 
# Created: 22/03/2023
# Modified: 
# Purpose: convert grib to netcdf and rename files

archive=/net/atmos/data/ERA5/original/100u/1hr
year_start=1941
year_end=2022
oldname=var246
var=100u

YEAR=$year_start
while [  $YEAR -le $year_end ]; do
    #loop over years
    echo "Processing year $YEAR"
    files=${archive}/${YEAR}/${oldname}_1hr_era5_${YEAR}??.grib
    for MONTH in 01 02 03 04 05 06 07 08 09 10 11 12
    do
        cdo -f nc copy ${archive}/${YEAR}/${oldname}_1hr_era5_${YEAR}${MONTH}.grib ${archive}/${YEAR}/${oldname}_1hr_era5_${YEAR}${MONTH}.nc
        cdo chname,${oldname},${var} ${archive}/${YEAR}/${oldname}_1hr_era5_${YEAR}${MONTH}.nc ${archive}/${YEAR}/${var}_1hr_era5_${YEAR}${MONTH}.nc
        rm ${archive}/${YEAR}/${oldname}_1hr_era5_${YEAR}${MONTH}.*

    done
    let YEAR=YEAR+1
done #year