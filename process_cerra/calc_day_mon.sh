#!/bin/bash
# File Name: calc_day_mon.sh
# Author: ruth.lorenz@c2sm.ethz.ch
# Created: 13/01/22
# Modified: Mon Jun 23 09:09:04 2025
# Purpose : calculate daily and monthly means, sums, etc.
#           from original 3hr data

###-------------------------------------------------------
printf -v date '%(%Y-%m-%d_%H%M%S)T' -1
logfile="calc_day_mon_$date.log"
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
variable="sd"
# aggregation method, depends on variable (mean, sum, max, min)
agg_method="mean"
# forecast or analysis? in case of forecast time needs to be shifted
# because time "date 00:00:00" contains forecast data of "day before 21:00:00 to 24:00:00"
product_type="forecast"

## years which need to be processed
syear=1985
eyear=2020

archive=/net/atmos/data/${data}
version=v1

#outdir=${archive}/processed/${version}
outdir=/net/dust/c2sm-data/rlorenz/cerra-land_cds/processed/${version}

for VARI in $variable
do
    echo "Processing variable $VARI, $product_type, with aggregation method $agg_method."
    workdir=${outdir}/work/${VARI}
    ## create directories if do not exist yet
    mkdir -p ${outdir}/${VARI}/day/native
    mkdir -p ${outdir}/${VARI}/mon/native
    mkdir -p ${workdir}

    for YEAR in $(seq ${syear} ${eyear})
    do
        echo $YEAR

        name_in=${archive}/original/${VARI}/${VARI}_3hr_${data}_${YEAR}.nc
        name_day=${outdir}/${VARI}/day/native/${VARI}_day_${agg_method}_${data}_${YEAR}.nc
        name_mon=${outdir}/${VARI}/mon/native/${VARI}_mon_${agg_method}_${data}_${YEAR}.nc
        tmp=${workdir}/tmpfile_${YEAR}.nc

        if [[ ${product_type} = "forecast" ]]; then
            # -> last timestep is next day 00:00:00 and contains data from day before
            # at end of the year the first timestep from the next year is already included in each file
            cdo shifttime,-1hour ${name_in} ${tmp}

        else
            cp ${name_in} ${tmp}
        fi

        if [[ ${agg_method} = "mean" ]]; then
            if [[ ${product_type} != "forecast" ]]; then
                cdo daymean ${name_in} ${name_day}
                cdo monmean ${name_day} ${name_mon}
            else
                echo "Method is ${agg_method} but product is ${product_type}."
                cdo daymean ${tmp} ${name_day}
                cdo monmean ${name_day} ${name_mon}
            fi
        elif [[ ${agg_method} = "sum" ]]; then
            # variables which are sums over days should be forecast
            if [[ ${product_type} != "forecast" ]]; then
                echo "Method is ${agg_method} but product is ${product_type}."
                echo "Variables which are sums over days should be forecast."
                exit
            fi
            cdo daysum ${tmp} ${name_day}
            cdo monsum ${name_day} ${name_mon}
        elif [[ ${agg_method} = "max" ]]; then
            # variables which are max over days should be forecast
            if [[ ${product_type} != "forecast" ]]; then
                echo "Method is ${agg_method} but product is ${product_type}."
                echo "Variables which are max over days should be forecast."
                exit
            fi
            cdo daymax ${tmp} ${name_day}
            cdo monmax ${name_day} ${name_mon}
        elif [[ ${agg_method} = "min" ]]; then
            # variables which are min over days should be forecast
            if [[ ${product_type} != "forecast" ]]; then
                echo "Method is ${agg_method} but product is ${product_type}."
                echo "Variables which are min over days should be forecast."
                exit
            fi
            cdo daymin ${tmp} ${name_day}

        fi
    done
    # clean up workdir
    #rm ${workdir}/*
done


} 2>&1 | tee logfiles/${logfile}
