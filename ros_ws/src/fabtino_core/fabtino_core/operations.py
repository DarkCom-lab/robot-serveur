"""Validated viewer operations shared by the ROS adapters."""
import math
import numpy as np
from .navigation.planner import OccupancyGrid

MAX_MAP_CELLS = 1_000_000


def map_dimensions(payload):
    resolution = float(payload['resolution'])
    radius = float(payload['radius'])
    if not (math.isfinite(resolution) and math.isfinite(radius) and resolution > 0 and radius > 0):
        raise ValueError('Map resolution and radius must be finite and positive')
    size = math.ceil(2 * radius / resolution)
    if size * size > MAX_MAP_CELLS:
        raise ValueError('Map exceeds 1,000,000 cells; increase its resolution')
    return resolution,radius,size


def imported_grid(payload):
    resolution=float(payload['resolution']);radius=float(payload['radius'])
    if not all(math.isfinite(v) and v>0 for v in (resolution,radius)):
        raise ValueError('Map resolution and scale must be finite and positive')
    default_size=math.ceil(2*radius/resolution)
    width=int(payload.get('width',default_size));height=int(payload.get('height',default_size))
    if width<1 or height<1 or width*height>MAX_MAP_CELLS:
        raise ValueError('Map width and height must be positive and contain at most 1,000,000 cells')
    values = np.asarray(payload['grid'])
    if values.ndim != 1 or values.size != width*height or not np.isin(values, (-1, 0, 100)).all():
        raise ValueError('Map must contain exactly width * height -1/0/100 cells')
    origin_x=float(payload.get('origin_x',-radius));origin_y=float(payload.get('origin_y',-radius));origin_yaw=float(payload.get('origin_yaw',0.))
    grid = OccupancyGrid(resolution, radius,width=width,height=height,origin_x=origin_x,origin_y=origin_y,origin_yaw=origin_yaw)
    grid.load(resolution, radius, values,width=width,height=height,origin_x=origin_x,origin_y=origin_y,origin_yaw=origin_yaw)
    return grid
