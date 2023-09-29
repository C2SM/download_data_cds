#!/bin/bash
# File Name: regrid_to_g025.sh
# Author: Ruth Lorenz 
# Created: 30/08/2023
# Modified:
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
variable="2t"
freq="mon"
grid="g025"
method="remapcon2"
year=2022

archive=/net/atmos/data/${DATA}
version=v1

indir=${archive}/processed/${version}/${variable}/${freq}/native
path_to_grid=/home/rlorenz/scripts/cmip6-ng/grids/

outdir=${archive}/processed/${version}/${variable}/${freq}/${grid}

## create directory if does not exist yet
mkdir -p ${outdir}

if [[ year=="all" ]] then
    file_pattern=${indir}/*.nc
else
    file_pattern=${indir}/*_${year}.nc
fi

for f in ${file_pattern}
do
    echo "Processing $f file..."
    namestart_path=$(echo $f| cut -d'.' -f 1)
    namestart=$(echo $namestart_path| cut -d'/' -f 11)
    outfile=${outdir}/${namestart}_${grid}.nc
    echo "Writing $outfile ..."
    cdo -O -b F64 -${method},${path_to_grid}/g025.txt $f ${outfile}
done




} 2>&1 | tee logfiles/${logfile}