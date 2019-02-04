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
pushd infrastructure-planning
# get to commit with pinned versions
git checkout 92b2a4a0c06ee9f6ab2b972ed7b202031ecac775
popd

# install dependencies
rm -rf $HOME/miniconda/envs/electrificationplanner
conda create -n electrificationplanner -f infrastructure-planning/packages.txt
conda install -n electrificationplanner -c conda-forge -c sel infrastructure-planning
