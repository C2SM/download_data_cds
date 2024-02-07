#!/bin/bash
# File Name: calc_day_mon.sh
# Author: ruth.lorenz@c2sm.ethz.ch 
# Created: 13/01/22
# Modified: Wed Sep 13 14:38:03 2023
# Purpose : calculate monthly means for derived variables calculated
#           using calc_variable_from_other_variable.py

###-------------------------------------------------------
printf -v date '%(%Y-%m-%d_%H%M%S)T' -1
logfile="calc_mon_era5_derive_vars_v2_$date.log"
{
##-----------------------##
## load required modules ##
##-----------------------##
#module load netcdf/4.7.4
module load nco/5.1.8
module load cdo/2.3.0

##---------------------##
## user specifications ##
##-------------------- ##
DATA="era5_cds"
data="era5"
variable="hurs"
# aggregation method, depends on variable (mean, sum, max, min)
agg_method="mean"


## years which need to be processed
syear=1980
eyear=1985

archive=/net/atmos/data/${DATA}
version=v2

outdir=${archive}/processed/${version}

# set chunksizes for lat and lon
lat_ck="45"
lon_ck="22"

for VARI in $variable
do
    echo "Processing variable $VARI, with aggregation method $agg_method."
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
            name_mon=${outdir}/${VARI}/mon/native/${YEAR}/${VARI}_mon_${data}_${YEAR}${MONTH}.nc
            name_day=${outdir}/${VARI}/day/native/${YEAR}/${VARI}_day_${data}_${YEAR}${MONTH}.nc

            if [[ ${agg_method} = "mean" ]]; then
                cdo monmean ${name_day} ${name_mon}
            elif [[ ${agg_method} = "sum" ]]; then
                cdo monsum ${name_day} ${name_mon}
            elif [[ ${agg_method} = "max" ]]; then    
                cdo monmax ${name_day} ${name_mon}
            elif [[ ${agg_method} = "min" ]]; then
                cdo monmin ${name_day} ${name_mon}
            fi
        done

        # clean up workdir
        #rm ${workdir}/*
    done

done


} 2>&1 | tee logfiles/${logfile}
