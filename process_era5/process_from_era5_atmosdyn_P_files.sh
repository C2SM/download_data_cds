#!/bin/bash
# File Name: process_from_era5_atmosdyn_P_files.sh
# Author:  Ruth Lorenz
# Created: 27/09/2023
# Modified: Wed Sep 27 17:17:03 2023
# Purpose : process data from files stored in /net/thermo/atmosdyn/era5/cdf
# 	(data downloaded by Michael Sprenger), e.g. temperature
# 	at plev (T)  

###-------------------------------------------------------
printf -v date '%(%Y-%m-%d_%H%M%S)T' -1
logfile="process_from_era5_atmosdyn_P_files_$date.log"
{
##-----------------------##
## load required modules ##
##-----------------------##
module load netcdf
module load nco
module load cdo

##---------------------##
## user specifications ##
##-------------------- ##
data_in="era5"
data_out="era5_cds"
variable_in="T"
variable_out="ta"
agg_method="mean"

path_in="/net/thermo/atmosdyn/era5/cdf"

## years which need to be processed
syear=2022
eyear=2022

archive=/net/atmos/data/${data_out}
version=v2

outdir=${archive}/processed/${version}

echo "Processing variable ${variable_in} to variable ${variable_out} with aggregation method $agg_method."
VARI=${variable_out}
workdir=${outdir}/work/${VARI}

## create directories if do not exist yet
mkdir -p ${outdir}/${VARI}/day/native
mkdir -p ${outdir}/${VARI}/mon/native
mkdir -p ${workdir}

for YEAR in $(seq ${syear} ${eyear})
do
    echo $YEAR

    for MONTH in $(seq -w 01 12)
    do
        echo $MONTH

        name_mon=${outdir}/${VARI}/mon/native/${VARI}_mon_${data_in}_${YEAR}${MONTH}.nc
        name_day=${outdir}/${VARI}/day/native/${VARI}_day_${data_in}_${YEAR}${MONTH}.nc

        name_in1=${path_in}/${YEAR}/${MONTH}/P${YEAR}${MONTH}*

        for FILE in ${name_in1}
        do
            base=$(basename "$FILE")
            new_filename=$(echo "$base" | tr P T)
            ncks -v ${variable_in} ${FILE} ${workdir}/${new_filename}.nc
        done
        # concatenate all files for one month
        ncrcat ${workdir}/T${YEAR}${MONTH}*.nc ${workdir}/T${YEAR}${MONTH}.nc
        # calculate daily means
        if [[ $agg_method == "mean" ]]
        then
            cdo daymean ${workdir}/T${YEAR}${MONTH}.nc ${workdir}/${variable_in}_day_${YEAR}${MONTH}.nc
        else
            echo "aggregation method $agg_method not implemented."
            exit
        fi
    done
    # change variable name to cmip name
    cdo chname,${variable_in},${variable_out} ${workdir}/${variable_in}_day_${YEAR}${MONTH}.nc ${name_day}

    if [[ $agg_method == "mean" ]]
    then
        cdo monmean ${name_day} ${name_mon}
    else
        echo "aggregation method $agg_method not implemented."
        exit
    fi        
done

}

