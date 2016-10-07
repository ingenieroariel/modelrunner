#!/bin/bash
# Run networker with given input, output and config

input_dir=$1
output_dir=$2

echo "Running networker"
echo "Reading input from $input_dir"
pushd $HOME/infrastructure-planning
source activate infrastructure-planning
python estimate_electricity_cost_by_technology_from_population.py $input_dir/config.json -w $input_dir -o $output_dir
popd
