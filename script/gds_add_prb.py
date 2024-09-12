#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2024 Dayton Pidhirney
import sys, os
import gdspy

BOUNDARY_LAYER = 235  # prBndry
BOUNDARY_DATATYPE = 4 # boundary

if __name__ == '__main__':

  # Check args
  if len(sys.argv) < 2:
    print(f"{sys.argv[0]} <file.gds>")
    print("warning: this script modifies the file in-place")
    exit(1)
  
  # Check filepath
  filepath: str = sys.argv.pop()
  if not os.path.isfile(filepath):
    raise FileNotFoundError("unable to locate GDS file specified")

  target_cellname: str = os.path.basename(filepath.split(".")[0])

  # Load GDS
  gdsii = gdspy.GdsLibrary(infile=filepath)
  if not target_cellname in gdsii.cells:
    raise RuntimeError("cannot locate a cell in the GDS file matching the filename")

  # Add missing PR Boundary Layer
  target_cell: gdspy.Cell = gdsii.cells[target_cellname]
  x, y = target_cell.get_bounding_box()[1]
  if BOUNDARY_LAYER not in target_cell.get_layers():
    print("Adding missing PR Boundary Layer")
    target_cell.add(
        gdspy.Rectangle(
          (0, 0),
          (x, y),
          layer=BOUNDARY_LAYER, datatype=BOUNDARY_DATATYPE
        )
    )
    x2, y2 = target_cell.get_bounding_box()[1]
    assert (x, y) == (x2, y2)
    gdsii.write_gds(filepath)
    print("Success")
  else:
    print("PR Boundary already exists ... skip")
