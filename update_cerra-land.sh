#!/bin/bash
# File Name: update_cerra-land.sh
# Author:  Ruth Lorenz
# Created: 20/02/2026
# Modified:
# Purpose : update cerra-land data for certain years

###-------------------------------------------------------
printf -v date '%(%Y-%m-%d_%H%M%S)T' -1
logfile="update_cerra-land_$date.log"
mkdir -p logfiles
{
export PYTHONPATH=""
module load conda
source activate iacpy3_2025

syear=2021
eyear=2025

# forecast variables to be updated
variable_list=("eva" "perc" "sd" "skt" "slhf" "snom" "sro" "sshf" "ssr" "ssrd" "str" "strd")

for VARI in "${variable_list[@]}"
do
    echo "Updating variable $VARI for years $syear to $eyear."
    python cerra-land_argp_cds_forecast_3hr_byyear.py --start_year $syear --end_year $eyear --variable $VARI &&
    ./process_cerra/calc_day_mon_argp.sh $VARI $syear $eyear cerra-land
done

# forecast variable on soil
variable_list=("vsw")
for VARI in "${variable_list[@]}"
do
    echo "Updating variable $VARI for years $syear to $eyear."
    python cerra-land_argp_cds_forecast_soil_3hr_byyear.py --start_year $syear --end_year $eyear --variable $VARI &&
    ./process_cerra/calc_day_mon_argp.sh $VARI $syear $eyear cerra-land
done

# special analysis tp (only available as day)
variable_list=("tp")

for VARI in "${variable_list[@]}"
do
    echo "Updating variable $VARI for years $syear to $eyear."
    python cerra-land_argp_cds_analysis_day_byyear.py --start_year $syear --end_year $eyear --variable $VARI &&
    ./process_cerra/calc_mon_from_day_argp.sh $VARI $syear $eyear cerra-land
done


} 2>&1 | tee logfiles/${logfile}