#!/bin/bash
# File Name: calc_mon_from_day.sh
# Author: ruth.lorenz@c2sm.ethz.ch 
# Created: 12/04/22
# Modified: Wed Apr 12 09:55:03 2023
# Purpose : calculate monthly means, sums, etc.
#           from original day data (e.g. cerra-land tp )

###-------------------------------------------------------
printf -v date '%(%Y-%m-%d_%H%M%S)T' -1
logfile="calc_mon_$date.log"
{
##-----------------------##
## load required modules ##
##-----------------------##
module load netcdf
module load nco/4.5.3
module load cdo

##---------------------##
## user specifications ##
##-------------------- ##
data="cerra-land"
variable="tp"
# aggregation method, depends on variable (mean, sum, max, min)
agg_method="mean"
# forecast or analysis? in case of forecast time needs to be shifted
# because time "date 00:00:00" contains forecast data of "day before 21:00:00 to 24:00:00"
product_type="analysis"

## years which need to be processed
syear=1985
eyear=2020

archive=/net/atmos/data/${data}
version=v1

outdir=${archive}/processed/${version}


for VARI in $variable
do
    echo "Processing variable $VARI, $product_type, with aggregation method $agg_method."
    workdir=${outdir}/work/${VARI}
    ## create directories if do not exist yet
    mkdir -p ${outdir}/${VARI}/mon/native

    for YEAR in $(seq ${syear} ${eyear})
    do
        echo $YEAR

        name_in=${archive}/original/${VARI}/${VARI}_day_${data}_${YEAR}.nc
        name_mon=${outdir}/${VARI}/mon/native/${VARI}_mon_${data}_${YEAR}.nc

        if [[ ${agg_method} = "mean" ]]; then
            cdo monmean ${name_in} ${name_mon}
        elif [[ ${agg_method} = "sum" ]]; then
            cdo monsum ${name_in} ${name_mon}
        elif [[ ${agg_method} = "max" ]]; then
            cdo monmax ${name_in} ${name_mon}
        elif [[ ${agg_method} = "min" ]]; then
            cdo monmin ${name_in} ${name_mon}
        fi
    done

done


} 2>&1 | tee logfiles/${logfile}
