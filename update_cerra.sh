#!/bin/bash
# File Name: update_cerra.sh
# Author:  Ruth Lorenz
# Created: 02/03/2026
# Modified:
# Purpose : update cerra data for certain years

###-------------------------------------------------------
printf -v date '%(%Y-%m-%d_%H%M%S)T' -1
logfile="update_cerra_$date.log"
mkdir -p logfiles
{
export PYTHONPATH=""
module load conda
source activate iacpy3_2025

syear=2024
eyear=2025

# forecast variables to be updated
variable_list=("mx2t" "mn2t" "slhf" "sshf" "ssr" "ssrd" "str" "strd")
#variable_list=("eva")

for VARI in "${variable_list[@]}"
do
    echo "Updating variable $VARI for years $syear to $eyear."
    python cerra_cds_forecast_3hr_byyear.py --start_year $syear --end_year $eyear --variable $VARI &&
    ./process_cerra/calc_day_mon_argp.sh $VARI $syear $eyear cerra
done


# forecast variable total precipitation (download 1 hourly data and then calculate daily and monthly sums)
variable_list=("tp")
for VARI in "${variable_list[@]}"
do
    echo "Updating variable $VARI for years $syear to $eyear."
    python cerra_cds_forecast_1hr_byyear.py --start_year $syear --end_year $eyear --variable $VARI &&
    ./process_cerra/calc_day_mon_from_1hr_argp.sh $VARI $syear $eyear cerra
done

# forecast variable on soil
variable_list=("vsw" "liqvsm")
for VARI in "${variable_list[@]}"
do
    echo "Updating variable $VARI for years $syear to $eyear."
    python cerra_cds_analysis_soil_3hr_byyear.py --start_year $syear --end_year $eyear --variable $VARI &&
    ./process_cerra/calc_day_mon_argp.sh $VARI $syear $eyear cerra
done


# analysis variables to be updated
variable_list=("10si" "10wdir" "2r" "2t" "msl" "sd" "sde" "skt" "sp" "tcc")

for VARI in "${variable_list[@]}"
do
    echo "Updating variable $VARI for years $syear to $eyear."
    python cerra_cds_analysis_3hr_byyear.py --start_year $syear --end_year $eyear --variable $VARI &&
    ./process_cerra/calc_day_mon_argp.sh $VARI $syear $eyear cerra
done


# 1pressure level variables to be updated
variable_list=("gph300" "gph500")
for VARI in "${variable_list[@]}"
do
    echo "Updating variable $VARI for years $syear to $eyear."
    python cerra_cds_1pressure_level_3hr_byyear.py --start_year $syear --end_year $eyear --variable $VARI &&
    ./process_cerra/calc_day_mon_3D_argp.sh $VARI $syear $eyear cerra
done


# pressure levels variables to be updated
variable_list=("r" "t" "u" "v")
for VARI in "${variable_list[@]}"
do
    echo "Updating variable $VARI for years $syear to $eyear."
    python cerra_cds_pressure_levels_3hr_byyear.py --start_year $syear --end_year $eyear --variable $VARI &&
    ./process_cerra/calc_day_mon_3D_argp.sh $VARI $syear $eyear cerra
done

} 2>&1 | tee logfiles/${logfile}