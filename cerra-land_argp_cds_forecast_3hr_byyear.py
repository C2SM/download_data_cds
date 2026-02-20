import os
import cdsapi
import argparse

from convert_grib_netcdf import grib_to_netcdf
from functions.file_util import read_cerra_info


def main():
    # -------------------------------------------------
    # Parse command line input
    # -------------------------------------------------
    parser = argparse.ArgumentParser(
        description="Download CERRA data from the CDS API and convert from GRIB to NetCDF format."
    )
    parser.add_argument(
        "-v",
        "--variable",
        help="Name of the variable to download and process",
        required=True,
    )

    parser.add_argument(
        "-start",
        "--start_year",
        help="Start year for data download (inclusive)",
        required=True,
    )

    parser.add_argument(
        "-end",
        "--end_year",
        help="End year for data download (inclusive)",
        required=True,
    )
    parser.add_argument(
        "-o",
        "--overwrite",
        help="Whether to overwrite existing files (default: False)",
        action="store_true",
    )

    args = parser.parse_args()


    var=args.variable
    cerra_info = read_cerra_info(var)
    long_name = cerra_info['long_name']
    startyr=int(args.start_year)
    endyr=int(args.end_year)
    archive=f'/net/atmos/data/cerra-land/original/{var}'

    if (os.access(archive, os.F_OK) == False):
        os.makedirs(archive)

    dataset = "reanalysis-cerra-land"

    for year in range(startyr, endyr+1):
        filename = f'{archive}/{var}_3hr_cerra-land_{year}'
        target = os.path.isfile(f'{filename}.grib')
        if not target or args.overwrite:
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


        grib_to_netcdf(f'{filename}.grib', f'{filename}.nc', variable_name=var)
        #os.system(f'rm {filename}.grib')

if __name__ == "__main__":
    main()