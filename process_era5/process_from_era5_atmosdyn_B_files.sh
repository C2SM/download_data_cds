#!/bin/bash
# File Name: process_from_era5_atmosdyn_B_files.sh
# Author:  Ruth Lorenz
# Created: 27/09/2023
# Modified: Fri Dec  8 17:29:09 2023
# Purpose : process data from files stored in /net/thermo/atmosdyn/era5/cdf
# 	(data downloaded by Michael Sprenger), e.g. temperature
# 	at surface (T)  

###-------------------------------------------------------
printf -v date '%(%Y-%m-%d_%H%M%S)T' -1
logfile="process_from_era5_atmosdyn_B_files_$date.log"
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
variable_in="MSL"
variable_out="psl"
agg_method="mean"

path_in="/net/thermo/atmosdyn/era5/cdf"

## years which need to be processed
syear=1950
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
            name_in1=${path_in}/${YEAR}/${MONTH}/B${YEAR}${MONTH}${DAY}*

            for FILE in ${name_in1}
            do
                base=$(basename "$FILE")
                new_filename=$(echo "$base" | tr B T)
                ncks -v ${variable_in} ${FILE} ${workdir}/${new_filename}.nc
            done
            # concatenate all files for one day
            ncrcat ${workdir}/T${YEAR}${MONTH}${DAY}*.nc ${workdir}/T${YEAR}${MONTH}${DAY}.nc
            # calculate daily means
            if [[ $agg_method == "mean" ]]
            then
                cdo daymean ${workdir}/T${YEAR}${MONTH}${DAY}.nc ${workdir}/${variable_in}_day_${YEAR}${MONTH}${DAY}.nc
            else
                echo "aggregation method $agg_method not implemented."
                exit
            fi
            # clean up
            rm ${workdir}/T${YEAR}${MONTH}${DAY}.nc
            rm ${workdir}/T${YEAR}${MONTH}${DAY}*.nc

            # change variable name to cmip name
            cdo chname,${variable_in},${variable_out} ${workdir}/${variable_in}_day_${YEAR}${MONTH}${DAY}.nc ${workdir}/tmp_${variable_out}_day_${YEAR}${MONTH}${DAY}.nc
        
            if [[ $agg_method != "sum" ]]
            then
                comment="Daily data aggregated as ${agg_method} over calendar day 00:00:00 to 23:00:00.\n"
            else
                comment="Daily data aggregated as ${agg_method} over calendar day.\n
                        Time was shifted by -1sec beforehand to include all data from 1:00:00 to 24:00:00 \n
                        sinde fluxes are aggregated over the hour in original data.\n"
            fi
            ncatted -O -a comment,global,a,c,"$comment" ${workdir}/tmp_${variable_out}_day_${YEAR}${MONTH}${DAY}.nc ${workdir}/${variable_out}_day_${YEAR}${MONTH}${DAY}.nc 

            rm ${workdir}/tmp_*.nc
        done
        # concatenate all days per month and chunk data into small lat,lon blocks
        ncrcat -O -4 -D 4 --cnk_plc=g3d --cnk_dmn=time,1 --cnk_dmn=lat,46 --cnk_dmn=lon,22 ${workdir}/${variable_out}_day_${YEAR}${MONTH}*.nc  ${name_day}

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

