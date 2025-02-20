#!/bin/bash
# File Name: calc_day_mon_3D_v2.sh
# Author: ruth.lorenz@c2sm.ethz.ch 
# Created: 13/01/22
# Modified: Fri Jul 14 17:43:30 2023
# Purpose : calculate daily and monthly means, sums, etc.
#           from original 3hr data for 3D variables (pa levels)
#           change variable names and units according to cmip

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
varin="z"
lev="100000"
varout="gph1000"
# aggregation method, depends on variable (mean, sum, max, min)
agg_method="mean"

## years which need to be processed
syear=1985
eyear=2021

archive=/net/atmos/data/cerra
version=v2

outdir=${archive}/processed/${version}


for VARI in $varin
do
    workdir=${outdir}/work/${VARI}
    ## create directories if do not exist yet
    mkdir -p ${outdir}/${varout}/day/native
    mkdir -p ${outdir}/${varout}/mon/native
    mkdir -p ${workdir}

    for YEAR in $(seq ${syear} ${eyear})
    do
        echo $YEAR
        for MONTH in $(seq -w 01 12)
        do
            echo $MONTH
            name_in=${archive}/original/${VARI}/${YEAR}/${VARI}_3hr_cerra_${MONTH}${YEAR}.nc
            name_day=${workdir}/${varout}_day_cerra_${MONTH}${YEAR}.nc
            name_mon=${workdir}/${varout}_mon_cerra_${MONTH}${YEAR}.nc

            # extract level
            cdo --reduce_dim sellevel,${lev} ${name_in} ${workdir}/${varout}_lev_tmp_${MONTH}${YEAR}.nc
            cdo chname,${VARI},${varout} ${workdir}/${varout}_lev_tmp_${MONTH}${YEAR}.nc ${workdir}/${varout}_${MONTH}${YEAR}.nc

            if [[ ${VARI} == "z" ]]; then
                echo 'Unit for z needs to be changed from m2/s2 to m.'
                # https://confluence.ecmwf.int/display/CKB/ERA5%3A+compute+pressure+and+geopotential+on+model+levels%2C+geopotential+height+and+geometric+height#ERA5:computepressureandgeopotentialonmodellevels,geopotentialheightandgeometricheight-Geopotentialheight
                # Earth's gravitational acceleration [m/s2]
                name_tmp=${workdir}/${varout}_tmp_${MONTH}${YEAR}
                const=9.80665 
                cdo divc,${const} ${workdir}/${varout}_${MONTH}${YEAR}.nc ${name_tmp}_divc.nc 
                ncatted -a units,${varout},m,c,"m" ${name_tmp}_divc.nc ${name_tmp}_ncatted.nc
                rm ${workdir}/${varout}_${MONTH}${YEAR}.nc
                mv ${name_tmp}_ncatted.nc ${workdir}/${varout}_${MONTH}${YEAR}.nc
            fi

            if [[ ${agg_method}=="mean" ]]; then
                echo "Calculating daily and monthly means for $YEAR, $MONTH."
                cdo daymean ${workdir}/${varout}_${MONTH}${YEAR}.nc ${name_day}
                cdo monmean ${name_day} ${name_mon}
            elif [[ ${agg_method}=="sum" ]]; then
                cdo daysum ${workdir}/${varout}_${MONTH}${YEAR}.nc ${name_day}
                cdo monsum ${name_day} ${name_mon}
            elif [[ ${agg_method}=="max" ]]; then
                cdo daymax ${workdir}/${varout}_${MONTH}${YEAR}.nc ${name_day}
                cdo monmax ${name_day} ${name_mon}
            elif [[ ${agg_method}=="min" ]]; then
                cdo daymin ${workdir}/${varout}_${MONTH}${YEAR}.nc ${name_day}
                cdo monmin ${name_day} ${name_mon}
            fi
        done
        # Concatenate daily and monthly files into yearly files
        cdo mergetime ${workdir}/${varout}_day_cerra_??${YEAR}.nc ${outdir}/${varout}/day/native/${varout}_day_cerra_${YEAR}.nc
        cdo mergetime ${workdir}/${varout}_mon_cerra_??${YEAR}.nc ${outdir}/${varout}/mon/native/${varout}_mon_cerra_${YEAR}.nc

        # Delete files by month
        rm ${workdir}/${varout}_day_cerra_??${YEAR}.nc
        rm ${workdir}/${varout}_mon_cerra_??${YEAR}.nc
    done

done


} 2>&1 | tee logfiles/${logfile}
