import os
import cdsapi

c = cdsapi.Client()

var='vsw'
long_name='volumetric_soil_moisture'
startyr=1985
endyr=2021
archive=f'/net/atmos/data/cerra-land/original/{var}'

if (os.access(archive, os.F_OK) == False):
    os.makedirs(archive)

for year in range(startyr, endyr+1):
    c.retrieve(
        'reanalysis-cerra-land',
        {
            'format': 'grib',
            'variable': f'{long_name}',
            'level_type': 'soil',
            'soil_layer': [
                '1', '2', '3',
                '4', '5', '6',
                '7', '8', '9',
                '10', '11', '12',
                '13', '14',
            ],
            'product_type': 'forecast',
            'year': f'{year}',
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
            'leadtime_hour': '3',
        },
        f'{archive}/{var}_3hr_cerra-land_{year}.grib')
    
    os.system(f'cdo -f nc copy {archive}/{var}_3hr_cerra-land_{year}.grib {archive}/{var}_3hr_cerra-land_{year}.nc')
    os.system(f'rm {archive}/{var}_3hr_cerra-land_{year}.grib')
