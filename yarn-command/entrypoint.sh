#!/bin/sh

set -e

sanitize() {
  if [ -z "${1}" ]
  then
    >&2 echo "Unable to find ${2}. Did you configure your workflow correctly?"
    exit 1
  fi
}

sanitize "${INPUT_COMMAND}" "command"

# Change to dir if provided
if [ -n "$INPUT_DIRECTORY" ]; then
  cd ${GITHUB_WORKSPACE}/${INPUT_DIRECTORY}
fi

yarn
yarn ${INPUT_COMMAND}
