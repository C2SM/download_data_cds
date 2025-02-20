#!/bin/bash
# File Name: regrid_to_g025.sh
# Author: Ruth Lorenz
# Created: 30/08/2023
# Modified: Fri Jan 31 14:09:53 2025
# Purpose : regrid ERA5 data from CDS to same grid as
#           cmip6-ng archive

###-------------------------------------------------------
printf -v date '%(%Y-%m-%d_%H%M%S)T' -1
logfile="regrid_to_g025_$date.log"
{
##-----------------------##
## load required modules ##
##-----------------------##
module load netcdf
module load nco
module load cdo

##---------------------##
## user specifications ##
##-------------------- ##
DATA="era5_cds"
variable="tos"
freq="mon"
grid="g025"
method="remapcon2"
syear=1950
eyear=2024

archive=/net/atmos/data/${DATA}
version=v2

indir=${archive}/processed/${version}/${variable}/${freq}/native
path_to_grid=/home/rlorenz/scripts/cmip6-ng/grids/

outdir=${archive}/processed/${version}/${variable}/${freq}/${grid}

for year in $(seq ${syear} ${eyear})
do
    echo $year
    ## create directory if does not exist yet
    mkdir -p ${outdir}/${year}

    file_pattern=${indir}/${year}/*_${year}*.nc

    for f in ${file_pattern}
    do
        echo "Processing $f file..."
        namestart_path=$(echo $f| cut -d'.' -f 1)
        namestart=$(echo $namestart_path| cut -d'/' -f 12)
        outfile=${outdir}/${year}/${namestart}_${grid}.nc
        echo "Writing $outfile ..."
        cdo -O -b F64 -${method},${path_to_grid}/g025.txt $f ${outfile}
    done
done


} 2>&1 | tee logfiles/${logfile}
