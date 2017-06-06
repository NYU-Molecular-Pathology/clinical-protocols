#!/bin/bash
set -x
source /ifs/data/molecpathlab/bin/activate_miniconda.sh

# cd /ifs/data/molecpathlab/bin
# git clone https://github.com/etal/cnvkit.git

# https://conda.io/docs/using/envs.html#create-an-environment
# conda install cnvkit -c bioconda -c r -c conda-forge
conda env create -f cnvkit.yml

# use the new env:
# source activate cnvkit
