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
if [ "$DATA_JSON" == "null" ]; then
    echo "Error: ShortName '$SHORT_NAME' not found in CERRA_variables.json"
    exit 1
fi

# 3. Map the TSV (Tab Separated Values) into an array
read -ra PARAMS <<< "$DATA_JSON"

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
if [[ $data == "cerra-land" ]] && [[ $variable != "tp" ]]; then
    product_type="forecast"
elif [[ $AN == "True" ]] && [[ $FC == "False" ]]; then
    product_type="analysis"
elif [[ $AN == "True" ]] && [[ $FC == "True" ]]; then
    product_type="analysis"
elif [[ $AN == "False" ]] && [[ $FC == "True" ]]; then
    product_type="forecast"
else
    echo "Error: Invalid combination of Analysis and Forecast flags."
    exit 1
fi

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
