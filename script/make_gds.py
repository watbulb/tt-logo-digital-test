#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2024 Uri Shaked

import gdspy
import sys
from PIL import Image

PNG_NAME  = "high_voltage.png"
CELL_NAME = "high_voltage_logo"
GDS_NAME  = "high_voltage.gds"

BOUNDARY_LAYER = 235  # prBndry
BOUNDARY_DATATYPE = 4  # boundary
LAYER = 69  # met2
DATATYPE = 20  # drawing
PIXEL_SIZE = 0.28  # um

# Process arguments
args = sys.argv[1:]
while args:
    arg = args.pop(0)
    if arg == "-u" and args:
        PIXEL_SIZE = float(args.pop(0))
    elif arg == "-i" and args:
        PNG_NAME = args.pop(0)
    elif arg == "-c" and args:
        CELL_NAME = args.pop(0)
    elif arg == "-o" and args:
        GDS_NAME = args.pop(0)
    else:
        print("Unknown argument: %s" % arg)
        exit(1)

# Open the image
img = Image.open(PNG_NAME)

# Convert the image to grayscale
img = img.convert("L")

layout = gdspy.Cell(CELL_NAME)
layout.add(
    gdspy.Rectangle(
        (0, 0),
        (img.width * PIXEL_SIZE, img.height * PIXEL_SIZE),
        layer=BOUNDARY_LAYER,
        datatype=BOUNDARY_DATATYPE,
    )
)
for y in range(img.height):
    for x in range(img.width):
        color = img.getpixel((x, y))
        if color < 128:
            # Adjust y-coordinate to flip the image vertically
            flipped_y = img.height - y - 1
            layout.add(
                gdspy.Rectangle(
                    (x * PIXEL_SIZE, flipped_y * PIXEL_SIZE),
                    ((x + 1) * PIXEL_SIZE, (flipped_y + 1) * PIXEL_SIZE),
                    layer=LAYER,
                    datatype=DATATYPE,
                )
            )

# Save the layout to a file
gdspy.write_gds(GDS_NAME)
