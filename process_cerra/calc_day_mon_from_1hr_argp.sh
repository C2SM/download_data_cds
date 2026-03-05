#!/bin/bash
# File Name: calc_day_mon.sh
# Author: ruth.lorenz@c2sm.ethz.ch
# Created: 13/01/22
# Modified: Fri Jul 14 17:42:01 2023
# Purpose : calculate daily and monthly means, sums, etc.
#           from original 3hr data

###-------------------------------------------------------
printf -v date '%(%Y-%m-%d_%H%M%S)T' -1
logfile="calc_day_mon_from_1hr_argp_$date.log"
{
##-----------------------##
## load required modules ##
##-----------------------##
module load netcdf/4.7.4
module load nco/5.1.8
module load cdo/2.3.0

##-----------------------##
## Capture cl arguments   ##
##-----------------------##
SHORT_NAME=$1
## years which need to be processed
syear=$2
eyear=$3
data=$4

# Check if argument is provided
if [ -z "$SHORT_NAME" ] || [ -z "$syear" ] || [ -z "$eyear" ] || [ -z "$data" ]; then
    echo "Usage: $0 <ShortName> <StartYear> <EndYear> <Data>"
    exit 1
fi

# 2. Extract the array from JSON using jq
# We fetch the entry for the specific key provided
DATA_JSON=$(jq -r --arg KEY "$SHORT_NAME" '.[$KEY] | @tsv' CERRA_variables.json)

# Check if the key exists in the JSON
if [ "$DATA_JSON" == "null" ] || [ -z "$DATA_JSON" ]; then
    echo "Error: ShortName '$SHORT_NAME' not found in CERRA_variables.json"
    exit 1
fi

# Map the TSV into an array using ONLY a tab as the delimiter
IFS=$'\t' read -ra PARAMS <<< "$DATA_JSON"

# 4. Assign to named variables for clarity
VAR_NAME=${PARAMS[0]}
UNITS=${PARAMS[1]}
AN=${PARAMS[4]}
FC=${PARAMS[5]}
AGG=${PARAMS[8]}


# Output results
echo "Processing $SHORT_NAME..."
echo "------------------------"
echo "CDS Variable: $VAR_NAME"
echo "Units:        $UNITS"
echo "Analysis:     $AN"
echo "Forecast:     $FC"
echo "Aggregation:  $AGG"
echo "------------------------"

##---------------------##
## user specifications ##
##-------------------- ##

variable=$SHORT_NAME
# aggregation method, depends on variable (mean, sum, max, min)
agg_method=$AGG

# forecast or analysis? in case of forecast time needs to be shifted
# because time "date 00:00:00" contains forecast data of "day before 21:00:00 to 24:00:00"
product_type="forecast"

archive=/net/atmos/data/${data}
version=v1

outdir=${archive}/processed/${version}


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
        name_day=${outdir}/${VARI}/day/native/${VARI}_day_${agg_method}_${data}_${YEAR}.nc
        name_mon=${outdir}/${VARI}/mon/native/${VARI}_mon_${agg_method}_${data}_${YEAR}.nc

        for MONTH in $(seq -w 01 12)
        do
            name_in=${archive}/original/${VARI}/${VARI}_1hr_${data}_${YEAR}${MONTH}.nc
            name_day_m=${workdir}/${VARI}_day_${agg_method}_${data}_${YEAR}${MONTH}.nc
            name_mon_m=${workdir}/${VARI}_mon_${agg_method}_${data}_${YEAR}${MONTH}.nc
            tmp=${workdir}/tmpfile.nc

            if [[ ${product_type} = "forecast" ]]; then
                echo "Processing forecast variable, file ${name_in}"
                echo $(cdo ntime "${name_in}")
                nt=$(cdo ntime "${name_in}")
                # hourly data are accumulated over 3 hour leadtimes, only need to sum up every 3rd time step -> seltimestep
                # Build list of timesteps: 3,6,9,... up to $nt
                steps=$(awk -v n="$nt" 'BEGIN {
                    for (i=3; i<=n; i+=3) {
                    printf i (i+3<=n ? "," : "")
                    }
                }')
                # -> last timestep is next day 00:00:00 and contains data from day before -shifttime
                # at end of the year the first timestep from the next year is already included in each file
                cdo -shifttime,-1sec -seltimestep,"${steps}" "${name_in}" "${tmp}"

            else
                cp ${name_in} ${tmp}
            fi

            if [[ ${agg_method} = "mean" ]]; then
                cdo daymean ${name_in} ${name_day_m}
                cdo monmean ${name_day_m} ${name_mon_m}
            elif [[ ${agg_method} = "sum" ]]; then
                # variables which are sums over days should be forecast
                if [[ ${product_type} != "forecast" ]]; then
                    echo "Method is ${agg_method} but product is ${product_type}."
                    echo "Variables which are sums over days should be forecast."
                    exit
                fi
                cdo daysum ${tmp} ${name_day_m}
                cdo monsum ${name_day_m} ${name_mon_m}
            elif [[ ${agg_method} = "max" ]]; then
                # variables which are max over days should be forecast
                if [[ ${product_type} != "forecast" ]]; then
                    echo "Method is ${agg_method} but product is ${product_type}."
                    echo "Variables which are max over days should be forecast."
                    exit
                fi
                cdo daymax ${tmp} ${name_day_m}
                cdo monmax ${name_day_m} ${name_mon_m}
            elif [[ ${agg_method} = "min" ]]; then
                # variables which are min over days should be forecast
                if [[ ${product_type} != "forecast" ]]; then
                    echo "Method is ${agg_method} but product is ${product_type}."
                    echo "Variables which are min over days should be forecast."
                    exit
                fi
                cdo daymin ${tmp} ${name_day_m}

            fi
        done
        # create yearly files
        cdo mergetime ${workdir}/${VARI}_day_${agg_method}_${data}_${YEAR}* ${name_day}
        cdo mergetime ${workdir}/${VARI}_mon_${agg_method}_${data}_${YEAR}* ${name_mon}
    done
    # clean up workdir
    rm ${workdir}/*
done


} 2>&1 | tee logfiles/${logfile}
