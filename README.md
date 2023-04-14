# download_data_cds
Scripts to download data from cds.climate.copernicus.eu via cdsapi
cdsapi is included in python environment iacpy3_2022

Scripts are for CERRA (DATA=cerra), CERRA-Land (DATA=cerra-land), ERA5 (DATA=era5-cds) and ERA5-Land(DATA=era5-land_cds) data.
Variable names are specified in scripts. Different scripts for different product types (forecast or analysis),
 level types (surface or atmosphere, soil, or pressure levels).

Data are downloaded as grib files (smaller than netcdfs, issues with time axis in CERRA when downloading netcdf directly)
 and then convertet to netcdf once data is on IAC servers. grib files are deleted.
For ERA5 and ERA5-Land variable names are changed to something more meaningful than varXYZ after converting to netcdf.

Data are downloaded to /net/atmos/data/$DATA/original/$VAR/
Processed data to daily and monthly (sums, averages, etc.) are in /net/atmos/data/$DATA/processed/v1/$VAR/day/native/
 resp. /net/atmos/data/$DATA/processed/v1/$VAR/mon/native/

Data download and processing progress:
CERRA: https://docs.google.com/spreadsheets/d/1xfM4TZCGXZm4M4VLQW3XPyAk6IX9vjlwj_p6ymX4aDU/edit?usp=sharing
CERRA-Land: https://docs.google.com/spreadsheets/d/1e58ps_yBmxUG0jvL8ZmNNr7Zz_UXuqIZsz4MdRAzvbM/edit?usp=sharing
ERA5: https://docs.google.com/spreadsheets/d/1HbKCZ4lV_ZkIcy1t7AtO3HGj7QzlpCKPmH8NpyA9IuM/edit?usp=sharing
ERA5-Land: https://docs.google.com/spreadsheets/d/1ViB3aCHzP2zmjjd7_U3j7RULcITuUrXto073TJi-Kfg/edit?usp=sharing

