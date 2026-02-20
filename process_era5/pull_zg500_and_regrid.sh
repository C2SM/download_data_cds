#!/bin/bash
# File Name: pull_zg500_and_regrid_to_g025.sh
# Author: Ruth Lorenz
# Created: 06/05/2024
# Modified: Fri Mar  7 19:16:37 2025
# Purpose : pull 500 level from zg and regrid ERA5 data from CDS to same grid as
#           cmip6-ng archive

###-------------------------------------------------------
printf -v date '%(%Y-%m-%d_%H%M%S)T' -1
logfile="pull_zg500_and_regrid_$date.log"
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
variable="zg"
level="500"
freq="day"
grid="0.11deg_rot"
method="remapcon2"
year=2022

archive=/net/atmos/data/${DATA}
version=v2

indir=${archive}/processed/${version}/${variable}/${freq}/native
path_to_grid=/net/ch4/data/cordex.ch2025/gridinfo/
gridfile=grid_EUR-11_rot_new

outdir=${archive}/processed/${version}/${variable}${level}/${freq}/${grid}/${year}

## create directory if does not exist yet
mkdir -p ${outdir}

if [[ ${year} == "all" ]]; then
    file_pattern=${indir}/*/*.nc
else
    file_pattern=${indir}/${year}/*_${year}*.nc
fi

for f in ${file_pattern}
do
    echo "Processing $f file..."
    namestart_path=$(echo $f| cut -d'.' -f 1)
    namestart=$(echo $namestart_path| cut -d'/' -f 12)
    namestart_new=$(echo "$namestart" | sed "s/$variable/$variable$level/g")
    outfile=${outdir}/${namestart_new}_${grid}.nc
    echo "Writing $outfile ..."
    cdo -O -b F64 -chname,${variable},${variable}${level} -${method},${path_to_grid}/${gridfile} -sellevel,${level} $f ${outfile}
done




} 2>&1 | tee logfiles/${logfile}
