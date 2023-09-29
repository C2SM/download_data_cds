#!/bin/bash
# File Name: download_using_era5cli.sh
# Author: Ruth Lorenz 
# Created: 13/09/2023
# Modified: Wed Sep 13 16:45:11 2023
# Purpose : shell script to downolad era5 data from cds
#	using package era5cli (installed in environment
#	download_cds)

###-------------------------------------------------------
printf -v date '%(%Y-%m-%d_%H%M%S)T' -1
logfile="download_using_era5cli_$date.log"
mkdir -p logfiles
{

module load conda
source activate download_cds

varname=10m_u_component_of_wind
time_res=hourly
syear=1942
eyear=1943
splitmon=True

download_path=/net/atmos/data/era5_cds/original/$varname/$time_res
mkdir -p $download_path
cd $download_path

for YEAR in $(seq ${syear} ${eyear})
do
    echo $YEAR
    mkdir $YEAR
    cd $YEAR
    era5cli $time_res --variables $varname --startyear $YEAR --endyear $YEAR --splitmonths True
done

} 2>&1 | tee logfiles/${logfile}



