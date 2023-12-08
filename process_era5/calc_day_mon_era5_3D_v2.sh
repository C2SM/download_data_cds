#!/bin/bash
# File Name: calc_day_mon.sh
# Author: ruth.lorenz@c2sm.ethz.ch 
# Created: 13/01/22
# Modified: Wed Sep 13 14:38:03 2023
# Purpose : calculate daily and monthly means, sums, etc.
#           from original 1hr data

###-------------------------------------------------------
printf -v date '%(%Y-%m-%d_%H%M%S)T' -1
logfile="calc_day_mon_era5_3D_v2_$date.log"
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
DATA="era5_cds"
data="era5"
variable_in="cc"
variable_out="clt"
# aggregation method, depends on variable (mean, sum, max, min)
agg_method="mean"
# forecast or analysis? in case of forecast time needs to be shifted
# because time "date 00:00:00" contains forecast data of "day before 23:00:00 to 24:00:00"
product_type="analysis"

## years which need to be processed
syear=1980
eyear=1980

archive=/net/atmos/data/${DATA}
version=v2

outdir=${archive}/processed/${version}

# set chunksizes for lat and lon
lat_ck="45"
lon_ck="22"

for VARI in $variable_in
do
    echo "Processing variable $VARI, $product_type, with aggregation method $agg_method."
    workdir=${outdir}/work/${VARI}
    ## create directories if do not exist yet
    mkdir -p ${workdir}

    for YEAR in $(seq ${syear} ${eyear})
    do
        echo $YEAR
        mkdir -p ${outdir}/${variable_out}/day/native/${YEAR}
        mkdir -p ${outdir}/${variable_out}/mon/native/${YEAR}

        for MONTH in $(seq -w 01 12)
        do
            echo $MONTH
            name_mon=${outdir}/${variable_out}/mon/native/${YEAR}/${variable_out}_mon_${data}_${YEAR}${MONTH}.nc
            name_day=${outdir}/${variable_out}/day/native/${YEAR}/${variable_out}_day_${data}_${YEAR}${MONTH}.nc

            name_day_work=${workdir}/${VARI}_day_${data}_${YEAR}${MONTH}

            name_in1=${workdir}/${VARI}_1hr_${data}_${YEAR}${MONTH}.nc
            tmp=${workdir}/tmpfile_${YEAR}${MONTH}.nc

            if [ ! -f name_in1 ]; then
                # first need to concatenate all days in month
                ncrcat ${archive}/original/${VARI}/1hr/${YEAR}/${MONTH}/${VARI}_1hr_${data}_${YEAR}${MONTH}*.nc ${name_in1}
            fi

            if [ -z ${plev+x} ]; then
                # determine if variable is on plev, if yes set chunking dimension for plev
                plev_info=$(ncdump -h "$name_in1" | grep "plev")
                # Check if the dimension exists in the output
                if [[ -n "$plev_info" ]]; then
                    plev=$(echo "$plev_info" | awk 'NR==1 {print NR,$3}' | cut -d' ' -f2)
                    echo "The dimension 'plev' exists in the NetCDF file and is plev=$plev."
                else
                    echo "The dimension 'plev' does not exist in the NetCDF file."
                    plev=0
                fi
            fi

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
                name_in2=${archive}/original/${VARI}/1hr/${YEAR2}/${VARI}_1hr_${data}_${YEAR2}${MONTH2}01.nc

                # extract first timestep from next day and concatenate with day before
                cdo seltimestep,1,1 ${name_in2} ${workdir}/${VARI}_1hr_${data}_${YEAR2}${MONTH2}_1.nc
                cdo mergetime ${name_in1} ${workdir}/${VARI}_1hr_${data}_${YEAR2}${MONTH2}_1.nc ${workdir}/${VARI}_1hr_${data}_${YEAR}${MONTH}_all.nc
                #rm ${workdir}/${VARI}_1hr_${data}_${YEAR2}${MONTH2}_1.nc

                cdo shifttime,-1sec ${workdir}/${VARI}_1hr_${data}_${YEAR}${MONTH}_all.nc ${workdir}/${VARI}_1hr_${data}_${YEAR}${MONTH}_shift.nc
                if [ ${YEAR} -eq 1940 ] && [ ${MONTH} -eq 01 ]; then
                    # for the first year January data starts at 6:00:00, so no need to cut the first hour
                    cp ${workdir}/${VARI}_1hr_${data}_${YEAR}${MONTH}_shift.nc ${tmp}
                else
                    # cut first hour and chunk data into small lat, lon blocks
                    ncks -d time,1, ${workdir}/${VARI}_1hr_${data}_${YEAR}${MONTH}_shift.nc ${tmp}
                fi

                #rm ${workdir}/${VARI}_1hr_${data}_${YEAR}${MONTH}*.nc
            else
                cp ${name_in1} ${tmp}
            fi

            if [ ${agg_method} = "mean" ]; then
                cdo daymean ${tmp} ${name_day_work}.nc
                ncatted -O -h -a comment,global,m,c,"Daily data aggregated as mean over calendar day 00:00:00 to 23:00:00." ${name_day_work}.nc ${name_day_work}_ncatted.nc               
            elif [ ${agg_method} = "sum" ]; then
                # variables which are sums over days should be forecast
                if [[ ${product_type} != "forecast" ]]; then
                    echo "Method is ${agg_method} but product is ${product_type}."
                    echo "Variables which are sums over days should be forecast."
                    exit
                fi
                cdo daysum ${tmp} ${name_day_work}.nc
                ncatted -O -h -a comment,global,m,c,"Daily data aggregated as sum over 01:00:00 to 00:00:00 next day." ${name_day_work}.nc ${name_day_work}_ncatted.nc                
            elif [ ${agg_method} = "max" ]; then
                cdo daymax ${tmp} ${name_day_work}.nc
                ncatted -O -h -a comment,global,m,c,"Daily data aggregated as max over calendar day 00:00:00 to 23:00:00." ${name_day_work}.nc ${name_day_work}_ncatted.nc                
            elif [ ${agg_method} = "min" ]; then
                cdo daymin ${tmp} ${name_day_work}.nc
                ncatted -O -h -a comment,global,m,c,"Daily data aggregated as min over calendar day 00:00:00 to 23:00:00." ${name_day_work}.nc ${name_day_work}_ncatted.nc  
            fi
            if [[ ${plev} -gt 0 ]]; then
                ncks -O -4 -D 4 --cnk_plc=g3d --cnk_dmn=time,1 --cnk_dmn=plev,${plev} --cnk_dmn=lat,${lat_ck} --cnk_dmn=lon,${lon_ck} ${name_day_work}_ncatted.nc ${name_day_work}_chunked.nc
            else
                ncks -O -4 -D 4 --cnk_plc=g3d --cnk_dmn=time,1 --cnk_dmn=lat,${lat_ck} --cnk_dmn=lon,${lon_ck} ${name_day_work}_ncatted.nc ${name_day_work}_chunked.nc
            fi
            cdo chname,${VARI},${variable_out} ${name_day_work}_chunked.nc ${name_day}
            

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
        rm ${workdir}/*
    done

done


} 2>&1 | tee logfiles/${logfile}
