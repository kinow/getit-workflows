#!/usr/bin/env python

import argparse
import logging
from string import Template
from datetime import datetime 
from shapely.wkt import loads
from shapely.geometry import Polygon

# Configure basic logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger("FILL_TEMPLATE")

def main(args):
    #datetime 2018-12-25T00:00:00Z
    dt_start = datetime.fromisoformat(args.start_date_time.replace("Z", "+00:00"))
    dt_end = datetime.fromisoformat(args.end_date_time.replace("Z", "+00:00"))
    day_start = datetime(dt_start.year, dt_start.month, dt_start.day, tzinfo=dt_start.tzinfo)

    start_time = (dt_start - day_start).total_seconds()/3600
    end_time = (dt_end - day_start).total_seconds()/3600

    #Parse WKT
    wkt_polygon = loads(args.WKT)
    if not isinstance(wkt_polygon, Polygon):
        raise ValueError("WKT must be a POLYGON")

    west_lon, south_lat, east_lon, north_lat = wkt_polygon.bounds

    data = vars(args)
    data['YEAR']  = dt_start.year
    data['MONTH'] = dt_start.month
    data['DAY']   = dt_start.day
    data['START_TIME'] = start_time
    data['END_TIME'] = end_time
    data['LONMIN'] = west_lon
    data['LONMAX'] = east_lon
    data['LATMIN'] = south_lat
    data['LATMAX'] = north_lat

    #
    #check volcano in box
    #
    if west_lon <= args.VENT_LON <= east_lon and south_lat <= args.VENT_LAT <= north_lat:
        print(f"Volcano coordinates are inside the domain box.")
    else:
        raise ValueError("Volcano coordinates are OUTSIDE the domain box!")


    fname = args.template
    fname_out = "final.inp"

    with open(fname, 'r') as f1, open(fname_out,'w') as f2:
        src = Template(f1.read())
        result = src.safe_substitute(data)
        f2.write(result)

if __name__ == "__main__":
    #
    # Argument parser
    #
    parser=argparse.ArgumentParser(description="Fill out an input template for miniapp or fullapp")
    parser.add_argument("--template", required=True, metavar='file', help='Template file to be modified')
    parser.add_argument("--MINIAPP_SOURCE", choices=['point', 'linear'], default='point', help='Type of source definition for miniapp')
    parser.add_argument("--MINIAPP_METEO", choices=['uniform', 'rotational'], default='uniform', help='Type of meteorological data for miniapp')
    parser.add_argument("--METEO_DATABASE", choices=['GFS','ERA5','ERA5ML','WRF'], default='WRF', help='Type of meteorological dataset')
    parser.add_argument("--METEO_FILE", required=True, metavar='file', help='Input meteorological file')
    parser.add_argument("--METEO_DICTIONARY", metavar='file', default='', help='Input dictionary for variable decoding')
    parser.add_argument("--RESTART_FILE", metavar='file', default='', help='Restart file in netCDF format')
    parser.add_argument("--LEVELS_FILE", metavar='file', default='', help='Two-columns file with coefficients for hybrid levels')
    parser.add_argument("--INITIAL", choices=['RESTART','NONE'], default='NONE', help='Initial condition')
#    parser.add_argument('--LONMIN', metavar='west_longitude', type=float, help='Domain west longitude')
#    parser.add_argument('--LONMAX', metavar='east_longitude', type=float, help='Domain east longitude')
#    parser.add_argument('--LATMIN', metavar='south_latitude', type=float, help='Domain south latitude')
#    parser.add_argument('--LATMAX', metavar='north_latitude', type=float, help='Domain north latitude')
    parser.add_argument('--WKT', required=True, help='Domain geometry in WKT format')
    parser.add_argument('--VENT_LON', default=15.0, metavar='vent_longitude', type=float, help='Volcano vent longitude')
    parser.add_argument('--VENT_LAT', default=37.75, metavar='vent_latitude', type=float, help='Volcano vent latitude')
    parser.add_argument('--VENT_HEIGHT', default=3300, metavar='vent_height', type=int, help='Volcano vent height') 
    parser.add_argument('--DX', metavar='longitude_resolution', type=float, help='Domain resolution for longiudes')
    parser.add_argument('--DY', metavar='latitude_resolution', type=float, help='Domain resolution for latitudes')
    parser.add_argument('--NZ', metavar='vertical_levels', type=int, help='Number of vertical levels')
    parser.add_argument('--start_date_time', required=True, metavar='YYYY-MM-DDTHH:MM:SSZ', help='Start time')
    parser.add_argument('--end_date_time', required=True, metavar='YYYY-MM-DDTHH:MM:SSZ', help='End time')
    #parser.add_argument("--date", metavar='YYYYMMDD', help='Reference date in format YYYYMMDD')
    args=parser.parse_args()
    #
    # Main program
    #
    logger.info("Filling in template...")
    main(args)
    logger.info("Done!")
