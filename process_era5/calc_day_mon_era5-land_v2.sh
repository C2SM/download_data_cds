#!/bin/bash
# File Name: calc_day_mon.sh
# Author: ruth.lorenz@c2sm.ethz.ch
# Created: 13/01/22
# Modified: Wed Sep 13 14:38:03 2023
# Purpose : calculate daily and monthly means, sums, etc.
#           from original 1hr data

###-------------------------------------------------------
printf -v date '%(%Y-%m-%d_%H%M%S)T' -1
logfile="calc_day_mon_era5-land_v2_$date.log"
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
DATA="era5-land_cds"
data="era5-land"
variable="2d"
variable_out="d2m"
long_name="2m_dew_point_temperature"
unit="K"
# aggregation method, depends on variable (mean, sum, max, min, inst)
agg_method="mean"
# forecast or analysis? in case of forecast time needs to be shifted
# because time "date 00:00:00" contains forecast data of "day before 23:00:00 to 24:00:00"
# in case of accumulated variables they are accumulated over a day -> only need 00:00:00 timestep for day before
# check how data was downloaded, true 1-hr values -> use agg_method="inst", only 00:00:00 downloaded, use agg_method="sum"
product_type="analysis"

## years which need to be processed
syear=1970
eyear=1970

archive=/net/atmos/data/${DATA}
version=v2

outdir=${archive}/processed/${version}

# set chunksizes for lat and lon
lat_ck="45"
lon_ck="22"


for VARI in $variable
do
    echo "Processing variable $VARI, $product_type, with aggregation method $agg_method."
    workdir=${outdir}/work/${VARI}
    ## create directories if do not exist yet
    mkdir -p ${outdir}/${variable_out}/day/native
    mkdir -p ${outdir}/${variable_out}/mon/native
    mkdir -p ${workdir}

    for YEAR in $(seq ${syear} ${eyear})
    do
        echo $YEAR

        name_mon=${outdir}/${variable_out}/mon/native/${variable_out}_mon_${data}_${YEAR}.nc
        #name_day=${outdir}/${variable_out}/day/native/${variable_out}_day_${data}_${YEAR}.nc

        for MONTH in $(seq -w 01 12)
        do
            echo $MONTH
            name_day_work=${workdir}/${VARI}_day_${data}_${YEAR}${MONTH}

            name_in1=${archive}/original/${VARI}/1hr/${YEAR}/${VARI}_1hr_${data}_${YEAR}${MONTH}.nc
            tmp=${workdir}/tmpfile_${YEAR}${MONTH}.nc


            if [[ ${product_type} = "forecast" ]]; then
                # -> last timestep is next day 00:00:00 and contains data from day before
                if [ ${MONTH} -eq 12 ]; then
                    let YEAR2=YEAR+1
                    MONTH2=01
                else
                    YEAR2=$YEAR
                    MONTH1=$(echo $MONTH | bc)
                    let NEWMONTH=MONTH1+1
                    MONTH2=$(printf "%02d" $NEWMONTH)
                fi

                name_in2=${archive}/original/${VARI}/1hr/${YEAR2}/${VARI}_1hr_${data}_${YEAR2}${MONTH2}.nc
                # extract first timestep from next day and concatenate with day before
                cdo seltimestep,1,1 ${name_in2} ${workdir}/${VARI}_1hr_${data}_${YEAR2}${MONTH2}_1.nc
                cdo mergetime ${name_in1} ${workdir}/${VARI}_1hr_${data}_${YEAR2}${MONTH2}_1.nc ${workdir}/${VARI}_1hr_${data}_${YEAR}${MONTH}.nc
                rm ${workdir}/${VARI}_1hr_${data}_${YEAR2}${MONTH2}_1.nc

                cdo shifttime,-1sec ${workdir}/${VARI}_1hr_${data}_${YEAR}${MONTH}.nc ${workdir}/${VARI}_1hr_${data}_${YEAR}${MONTH}_shift.nc
                if [ ${YEAR} -eq 1950 ] && [ ${MONTH} -eq 01 ] && [ ${product_type} = "forecast" ] && [ ${agg_method} = "sum" ]; then
                    # no need to cut first timestep, not downloaded
                    cp ${workdir}/${VARI}_1hr_${data}_${YEAR}${MONTH}_shift.nc ${tmp}
                else
                    ncks -d time,1, ${workdir}/${VARI}_1hr_${data}_${YEAR}${MONTH}_shift.nc ${tmp}
                fi

                rm ${workdir}/${VARI}_1hr_${data}_${YEAR}${MONTH}.nc
                rm ${workdir}/${VARI}_1hr_${data}_${YEAR}${MONTH}_shift.nc
            else
                cp ${name_in1} ${tmp}
            fi

            if [ ${agg_method} = "mean" ]; then
                cdo daymean ${tmp} ${name_day_work}.nc
            elif [ ${agg_method} = "sum" ]; then
                # variables which are sums over days should be forecast
                if [[ ${product_type} != "forecast" ]]; then
                    echo "Method is ${agg_method} but product is ${product_type}."
                    echo "Variables which are sums over days should be forecast."
                    exit
                fi
                cdo daysum ${tmp} ${name_day_work}.nc
            elif [ ${agg_method} = "max" ]; then
                cdo daymax ${tmp} ${name_day_work}.nc
            elif [ ${agg_method} = "min" ]; then
                cdo daymin ${tmp} ${name_day_work}.nc
            elif [ ${agg_method} = "inst" ]; then
                if [[ ${product_type} != "forecast" ]]; then
                    echo "Method is ${agg_method} but product is ${product_type}."
                    echo "Variables which are inst should be forecast."
                    exit
                fi
                cdo daymean -seltime,23:59:59 ${tmp} ${name_day_work}.nc
            fi

            ncks -O -4 -D 4 --cnk_plc=g3d --cnk_dmn=time,1 --cnk_dmn=lat,${lat_ck} --cnk_dmn=lon,${lon_ck} ${name_day_work}.nc ${name_day_work}_chunked.nc
            ncatted -a standard_name,${VARI},o,c,"${long_name}" ${name_day_work}_chunked.nc ${name_day_work}_ncatted.nc
            ncatted -O -a units,${VARI},o,c,"${unit}" ${name_day_work}_ncatted.nc ${name_day_work}_ncatted2.nc

            # rename variable
            name_day_out=${outdir}/${variable_out}/day/native/${variable_out}_day_${data}_${YEAR}${MONTH}.nc
            if [[ ${VARI} != ${variable_out} ]]; then
                ncrename -O -v ${VARI},${variable_out} ${name_day_work}_ncatted2.nc ${name_day_out}
            else
                mv ${name_day_work}_ncatted2.nc ${name_day_out}
            fi

            tmp_mon=${workdir}/tmpfile_mon_${YEAR}${MONTH}.nc
            if [ ${agg_method} = "mean" ] || [ ${agg_method} = "inst" ]; then
                cdo monmean ${name_day_out} ${tmp_mon}
            elif [ ${agg_method} = "sum" ]; then
                cdo monsum ${name_day_out} ${tmp_mon}
            elif [ ${agg_method} = "max" ]; then
                cdo monmax ${name_day_out} ${tmp_mon}
            elif [ ${agg_method} = "min" ]; then
                cdo monmin ${name_day_out} ${tmp_mon}
            fi

        done

        cdo mergetime ${workdir}/tmpfile_mon_${YEAR}??.nc ${name_mon}

        # clean up workdir
        rm ${workdir}/*
    done

done


} 2>&1 | tee logfiles/${logfile}
