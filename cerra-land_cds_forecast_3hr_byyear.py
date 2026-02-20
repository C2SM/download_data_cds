import os
import cdsapi

from convert_grib_netcdf import grib_to_netcdf

c = cdsapi.Client()

var='sro'
long_name='surface_runoff'
startyr=2021
endyr=2021
archive=f'/net/atmos/data/cerra-land/original/{var}'

if (os.access(archive, os.F_OK) == False):
    os.makedirs(archive)

dataset = "reanalysis-cerra-land"

for year in range(startyr, endyr+1):
    filename = f'{archive}/{var}_3hr_cerra-land_{year}'

    request = {
        'format': 'grib',
        'variable': [f'{long_name}'],
        'level_type': 'surface',
        'product_type': 'forecast',
        'year': [f'{year}'],
        'month': [
            '01', '02', '03',
            '04', '05', '06',
            '07', '08', '09',
            '10', '11', '12',
        ],
        'day': [
            '01', '02', '03',
            '04', '05', '06',
            '07', '08', '09',
            '10', '11', '12',
            '13', '14', '15',
            '16', '17', '18',
            '19', '20', '21',
            '22', '23', '24',
            '25', '26', '27',
            '28', '29', '30',
            '31',
        ],
        'time': [
            '00:00', '03:00', '06:00',
            '09:00', '12:00', '15:00',
            '18:00', '21:00',
        ],
        'leadtime_hour': ['3'],
        "data_format": "grib"
        }

    client = cdsapi.Client()
    client.retrieve(dataset, request, f'{filename}.grib')

    #os.system(f'cdo -f nc copy {filename}.grib {filename}.nc')
    grib_to_netcdf(f'{filename}.grib', f'{filename}.nc', variable_name=var)
    #os.system(f'rm {filename}.grib')