SHELL:=/bin/bash
MINICONDA_sh:=Miniconda3-4.4.10-Linux-x86_64.sh
MINICONDA_sh_url:=https://repo.continuum.io/miniconda/$(MINICONDA_sh)
CONDA_INSTALL_DIR:=$(shell pwd)/conda3
CONDA_ACTIVATE:=$(CONDA_INSTALL_DIR)/bin/activate

none:

$(MINICONDA_sh):
	wget "$(MINICONDA_sh_url)"

dl: $(MINICONDA_sh)

$(CONDA_INSTALL_DIR): dl
	[ ! -d "$(CONDA_INSTALL_DIR)" ] && \
	module unload python && \
	unset PYTHONPATH && \
	unset PYTHONHOME && \
	bash "$(MINICONDA_sh)" -b -p "$(CONDA_INSTALL_DIR)" || :

# install conda in the current directory and install the conda-build package to it
install: $(CONDA_INSTALL_DIR)
	module unload python && \
	unset PYTHONPATH && \
	unset PYTHONHOME && \
	source "$(CONDA_ACTIVATE)" && \
	conda install -y conda-build

# # build the custom conda package and create a new env using it
# custom: install
# 	source $(CONDA_ACTIVATE) && \
# 	conda-build custom-package-0.1 && \
# 	conda create -y -c local -n custom-package-0.1 custom-package==0.1

# # build the custom package and install from YAML env file
# custom-yaml: install
# 	source $(CONDA_ACTIVATE) && \
# 	conda-build custom-package-0.1 && \
# 	conda env create -f custom.yml

# test:
# 	source $(CONDA_ACTIVATE) custom-package-0.1 && \
# 	my_script.sh


multiqc:
	module unload python && \
	unset PYTHONPATH && \
	unset PYTHONHOME && \
	source $(CONDA_ACTIVATE) && \
	pip install multiqc

multiqc-test:
	module unload python && \
	unset PYTHONPATH && \
	unset PYTHONHOME && \
	source $(CONDA_ACTIVATE) && \
	export LANG=en_US.utf8 && \
	export LC_ALL=en_US.utf8 && \
	multiqc --version



# conda create -y -c bioconda -n multiqc multiqc
# conda create -y -c bioconda -n multiqc-1.5 multiqc=1.5
# conda search -c bioconda 'multiqc'
# && \
# conda env create -f multiqc-1.5.yml


#  remove all conda files
clean:
	[ -d "$(CONDA_INSTALL_DIR)" ] && mv "$(CONDA_INSTALL_DIR)" old_conda && rm -rf old_conda &
	rm -f "$(MINICONDA_sh)"

# ~~~~~ CONDA SETUP ~~~~~ #
# https://repo.continuum.io/miniconda/Miniconda3-4.4.10-Linux-x86_64.sh