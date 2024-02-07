#!/bin/bash
# File Name: process_from_era5_atmosdyn_H_files.sh
# Author:  Ruth Lorenz
# Created: 27/09/2023
# Modified: Wed Sep 27 17:17:03 2023
# Purpose : process data from files stored in /net/thermo/atmosdyn/era5/cdf
# 	(data downloaded by Michael Sprenger), e.g. temperature
# 	at plev (T)  

###-------------------------------------------------------
printf -v date '%(%Y-%m-%d_%H%M%S)T' -1
logfile="process_from_era5_atmosdyn_H_files_$date.log"
{
##-----------------------##
## load required modules ##
##-----------------------##
module load netcdf/4.7.4
module load nco/5.1.8
module load cdo/2.3.0

##---------------------##
## user specifications ##
##-------------------- ##
data_in="era5"
data_out="era5_cds"
variable_in="Z"
variable_out="zg500"
agg_method="mean"

path_in="/net/thermo/atmosdyn/era5/cdf"

## years which need to be processed
syear=1971
eyear=2022

archive=/net/atmos/data/${data_out}
version=v2

outdir=${archive}/processed/${version}

echo "Processing variable ${variable_in} to variable ${variable_out} with aggregation method $agg_method."
VARI=${variable_out}
workdir=${outdir}/work/${VARI}

## create directories if do not exist yet

mkdir -p ${workdir}

for YEAR in $(seq ${syear} ${eyear})
do
    echo $YEAR
    mkdir -p ${outdir}/${VARI}/day/native/${YEAR}
    mkdir -p ${outdir}/${VARI}/mon/native/${YEAR}

    for MONTH in $(seq -w 01 12)
    do
        echo $MONTH

        name_mon=${outdir}/${VARI}/mon/native/${YEAR}/${VARI}_mon_${data_in}_${YEAR}${MONTH}.nc
        name_day=${outdir}/${VARI}/day/native/${YEAR}/${VARI}_day_${data_in}_${YEAR}${MONTH}.nc

        for DAY in $(seq -w 01 31)
        do
            name_in1=${path_in}/${YEAR}/${MONTH}/H${YEAR}${MONTH}${DAY}*

            for FILE in ${name_in1}
            do
                base=$(basename "$FILE")
                new_filename=$(echo "$base" | tr H Z)
                ncks -v ${variable_in} ${FILE} ${workdir}/${new_filename}.nc
                new_filename2=$(echo "$new_filename" | tr Z Z500)
                cdo chname,zg,zg500 -sellevel,50000 ${workdir}/${new_filename}.nc ${workdir}/${new_filename2}.nc
            done
            # concatenate all files for one day
            ncrcat ${workdir}/Z500${YEAR}${MONTH}${DAY}*.nc ${workdir}/Z500${YEAR}${MONTH}${DAY}.nc
            # calculate daily means
            if [[ $agg_method == "mean" ]]
            then
                cdo daymean ${workdir}/Z500${YEAR}${MONTH}${DAY}.nc ${workdir}/${variable_in}500_day_${YEAR}${MONTH}${DAY}.nc
            else
                echo "aggregation method $agg_method not implemented."
                exit
            fi
            # clean up
            rm ${workdir}/Z${YEAR}${MONTH}${DAY}.nc
            rm ${workdir}/Z${YEAR}${MONTH}${DAY}*.nc
            rm ${workdir}/Z500${YEAR}${MONTH}${DAY}.nc
            rm ${workdir}/Z500${YEAR}${MONTH}${DAY}*.nc

            # change variable name to cmip name
            cdo chname,${variable_in},${variable_out} ${workdir}/${variable_in}_day_${YEAR}${MONTH}${DAY}.nc ${workdir}/${variable_out}_day_${YEAR}${MONTH}${DAY}.nc
            # determine number of p-levels if plev variable is not set yet, for chunking later on
            if [ -v ${plev} ]; then
                plev_info=$(ncdump -h "${workdir}/${variable_out}_day_${YEAR}${MONTH}${DAY}.nc" | grep "plev")
                plev=$(echo "$plev_info" | awk 'NR==1 {print $3;}')
            fi
        done

        # concatenate all days per month and chunk
        ncrcat -O -4 -D 4 --cnk_plc=g3d --cnk_dmn=time,1 --cnk_dmn=plev,$plev --cnk_dmn=lat,46 --cnk_dmn=lon,22 ${workdir}/${variable_out}_day_${YEAR}${MONTH}*.nc  ${name_day}

        if [[ $agg_method == "mean" ]]
        then
            cdo monmean ${name_day} ${name_mon}
        else
            echo "aggregation method $agg_method not implemented."
            exit
        fi
    done
   
done

}

