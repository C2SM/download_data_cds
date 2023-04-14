import cdsapi

c = cdsapi.Client()

c.retrieve(
    'reanalysis-cerra-single-levels',
    {
        'format': 'grib',
        'variable': 'land_sea_mask',
        'level_type': 'surface_or_atmosphere',
        'data_type': 'reanalysis',
        'product_type': 'analysis',
        'year': '1985',
        'month': '01',
        'day': '01',
        'time': '00:00',
    },
    'download_land_sea_mask.grib')
