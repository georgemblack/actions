#!/bin/bash

set -e

params=(
  --config=_config.yml,_config_prod.yml
)
if [[ -n "$INPUT_OUTPUTDIRECTORY" ]]; then
    params+=(-d ${GITHUB_WORKSPACE}/${INPUT_OUTPUTDIRECTORY})
fi

if [ -n "$INPUT_DIRECTORY" ]; then
  cd ${GITHUB_WORKSPACE}/${INPUT_DIRECTORY}
fi

bundle exec jekyll build "${params[@]}"
