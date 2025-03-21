#!/usr/bin/env bash

set -o errexit

# shellcheck disable=SC1091,SC1094
. ./scripts/common.sh

echo "Lint commits"

if [ -z "${FROM_INTERVAL_COMMITLINT:-}" ]; then
  FROM_INTERVAL_COMMITLINT="HEAD~1"
fi

if [ -z "${TO_INTERVAL_COMMITLINT:-}" ]; then
  TO_INTERVAL_COMMITLINT="HEAD"
fi

build_cd_container

# shellcheck disable=SC2086
docker run \
  ${_DOCKER_INTERACTIVE_TTY_OPTION} \
  -v "$(pwd):/source-repository" \
  "${CD_CONTAINER_URL}" \
  commitlint \
  --config config/lint/commitlint.config.js \
  --cwd /source-repository \
  --from ${FROM_INTERVAL_COMMITLINT} \
  --to ${TO_INTERVAL_COMMITLINT} \
  --verbose
