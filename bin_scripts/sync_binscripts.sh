#!/bin/bash

# find /ifs/data/molecpathlab/bin -maxdepth 1 ! -name "Miniconda2-latest-Linux-x86_64.*" -name "*.sh" -o -name "*.yml" -exec rsync --dry-run -vhPl {} ./ \;

find /ifs/data/molecpathlab/bin -maxdepth 1 ! -name "Miniconda2-latest-Linux-x86_64.*" -name "*.sh" -o -name "*.yml" -exec rsync -vhPl {} ./ \;
