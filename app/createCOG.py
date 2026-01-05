#!/usr/bin/env python

import argparse
import xarray as xr
import numpy as np
import logging
import rasterio
from rasterio.transform import Affine
from rio_cogeo.cogeo import cog_translate
from rio_cogeo.profiles import cog_profiles
from datetime import datetime, timezone

# Configure basic logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("NETCDF2COG")

class CogImage:
    FMT_TIME = "%Y-%m-%d %H:%M:%SZ"

    def __init__(self,ncfile):
        self.key      = None
        self.it       = None
        self.time_fmt = None
        self.data     = None
        self.profile  = None
        ###
        ### Open netcdf
        ###
        self.ds = xr.open_dataset(ncfile)
        self.nt = self.ds.sizes['time']

    def load(self,key,time):
        self.key = key
        #
        if key in self.ds: 
            da = self.ds[key]
        else:
            logger.info(f"Variable {key} not found. Nothing to do")
            return
        ###
        ### Check time
        ###
        if 'time' in da.dims: hasTime = True
        ###
        ### Indexing dataarray
        ###
        dims = ['time', 'lev', 'bin', 'fl', 'layer']
        d = {dim: 0 for dim in dims if dim in da.dims}
        if hasTime:
            it = time%self.nt
            d['time'] = it
            self.it  = it
            self.time_fmt = self.ds.isel(time=it)['time'].dt.strftime(self.FMT_TIME).item()
        self.data = da[d].astype(rasterio.float32)

        # Grid properties
        ysize     = self.ds.lat.cell_measures
        xsize     = self.ds.lon.cell_measures
        height    = self.data.shape[0]
        width     = self.data.shape[1]
        west_lon  = self.ds.lon.minimum
        south_lat = self.ds.lat.minimum
        transform = Affine(xsize,0.0,west_lon,0.0,ysize,south_lat)

        self.profile = {
            "driver":    "GTiff",
            "height":    height,
            "width":     width,
            "count":     1,
            "dtype":     self.data.dtype,
            "crs":       "EPSG:4326",
            "transform": transform,
            "nodata":    0,
            "tiled":     True,     # Enable tiling for COG
            "compress": 'DEFLATE'  # Initial compression
        }

    def save(self):
        """
        Save an array as a Cloud-Optimized GeoTIFF (COG)
        """
        if self.it is None:
            fname = f"{self.key}.tif"
        else:
            fname = f"{self.key}-t{self.it:03}.tif"

        logger.info(f"Saving {fname}")

        # Write the GeoTIFF (initial non-COG file)
        with rasterio.open(fname,'w',**self.profile) as dst: 
            dst.write(self.data,1)
            dst.update_tags(
#                step       = self.it,
                time       = self.time_fmt,
                key        = self.key,
                label      = self._getLabel(),
                unit       = self._getUnits(),
#                start_time = self.ds.isel(time=0)['time'].dt.strftime(self.FMT_TIME).item(),
                )

        # Convert to Cloud Optimized GeoTIFF
        cog_profile = cog_profiles.get("deflate")
        cog_translate(
            fname,
            fname,  # Overwrite the input file
            cog_profile,
            overview_level=6,  # Add overviews
            quiet=True
        )

    def _getLabel(self):
        labels = {
            'tephra_col_mass':  "Ash column mass",
            'SO2_col_mass':     "SO2 column mass",
            'tephra_cloud_top': "Ash cloud top height",
            'SO2_cloud_top':    "SO2 cloud top height",
        }
        return labels[self.key]

    def _getUnits(self):
        return self.ds[self.key].units

def main(args):
    c = CogImage(args.fname)
    for time in range(0,c.nt,args.times):
        c.load(args.key, time)
        c.save()

if __name__ == "__main__":
    # Argument parser
    parser = argparse.ArgumentParser(description="Convert NetCDF to Cloud-Optimized GeoTIFF (COG).")
    parser.add_argument("--fname", type=str, required=True, help="Path to NetCDF file")
    parser.add_argument("--key",   type=str, required=True, help="Variable name in NetCDF")
    parser.add_argument("--times",  type=int, required=True, help="Frequency time")
    parser.add_argument("--selected_fl", type=int, default=0, help="Selected flight level")
    parser.add_argument("--selected_intensity_measure_con", type=float, default=0, help="Selected intensity concentration measure")
    parser.add_argument("--selected_intensity_measure_col_mass", type=float, default=0, help="Selected intensity measure column mass")
    args = parser.parse_args()

    logger.info("Creating COG GeoTIFF file...")
    main(args)
    logger.info("Done!")
