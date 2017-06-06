#!/bin/bash

# https://github.com/pezmaster31/bamtools/wiki/Building-and-installing

git clone git://github.com/pezmaster31/bamtools.git && cd bamtools && mkdir build && cd build && cmake .. && make
