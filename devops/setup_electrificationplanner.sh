#!/bin/bash

source $HOME/.bash_profile
# so that conda doesn't exit after running
conda config --set always_yes yes

# NOTE:  the repo is named infrastructure-planning, but model is
# referred to as electrificationplanner in modelrunner
echo "Setup electrificationplanner env"
# electrificationplanner requires full source to run
rm -rf $HOME/infrastructure-planning
git clone https://github.com/piensa/infrastructure-planning

# install dependencies
rm -rf $HOME/miniconda/envs/electrificationplanner
conda env create -f infrastructure-planning/packages.txt
conda install -n electrificationplanner -c conda-forge -c sel infrastructure-planning
