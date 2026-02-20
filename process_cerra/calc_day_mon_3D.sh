#!/bin/bash
# File Name: calc_day_mon_*D.sh
# Author: ruth.lorenz@c2sm.ethz.ch
# Created: 13/01/22
# Modified: Thu Jun 26 15:54:52 2025
# Purpose : calculate daily and monthly means, sums, etc.
#           from original 3hr data for 3D variables (pa levels)

###-------------------------------------------------------
printf -v date '%(%Y-%m-%d_%H%M%S)T' -1
logfile="calc_3D_$date.log"
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

variable="gph300"
# aggregation method, depends on variable (mean, sum, max, min)
agg_method="mean"

## years which need to be processed
syear=1985
eyear=2023

archive=/net/atmos/data/cerra
version=v1

outdir=${archive}/processed/${version}


for VARI in $variable
do
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
            name_in=${archive}/original/${VARI}/${YEAR}/${VARI}_3hr_cerra_${MONTH}${YEAR}.nc
            name_day=${workdir}/${VARI}_day_cerra_${MONTH}${YEAR}.nc
            name_mon=${workdir}/${VARI}_mon_cerra_${MONTH}${YEAR}.nc

            if [[ ${agg_method}=="mean" ]]; then
                echo "Calculating daily and monthly means for $YEAR, $MONTH."
                cdo daymean ${name_in} ${name_day}
                cdo monmean ${name_day} ${name_mon}
            elif [[ ${agg_method}=="sum" ]]; then
                cdo daysum ${name_in} ${name_day}
                cdo monsum ${name_day} ${name_mon}
            elif [[ ${agg_method}=="max" ]]; then
                cdo daymax ${name_in} ${name_day}
                cdo monmax ${name_day} ${name_mon}
            elif [[ ${agg_method}=="min" ]]; then
                cdo daymin ${name_in} ${name_day}
                cdo monmin ${name_day} ${name_mon}
            fi
        done
        # Concatenate daily and monthly files into yearly files
        cdo mergetime ${workdir}/${VARI}_day_cerra_??${YEAR}.nc ${outdir}/${VARI}/day/native/${VARI}_day_cerra_${YEAR}.nc
        cdo mergetime ${workdir}/${VARI}_mon_cerra_??${YEAR}.nc ${outdir}/${VARI}/mon/native/${VARI}_mon_cerra_${YEAR}.nc

        # Delete files by month
        #rm ${workdir}/${VARI}_day_cerra_??${YEAR}.nc
        #rm ${workdir}/${VARI}_mon_cerra_??${YEAR}.nc
    done

done


} 2>&1 | tee logfiles/${logfile}
