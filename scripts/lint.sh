#!/usr/bin/env bash

set -o errexit

# shellcheck disable=SC1091,SC1094
. ./scripts/common.sh

echo "Running lint checks"

LINT_CI_JOB_PATH=".github/workflows/pipeline.yaml"
DEFAULT_LINTER_CONTAINER_IMAGE_VERSION="$(grep <"${LINT_CI_JOB_PATH}" "super-linter/super-linter" | awk -F '@' '{print $2}' | head --lines=1)"

LINTER_CONTAINER_IMAGE="ghcr.io/super-linter/super-linter:${LINTER_CONTAINER_IMAGE_VERSION:-${DEFAULT_LINTER_CONTAINER_IMAGE_VERSION}}"

echo "Running linter container image: ${LINTER_CONTAINER_IMAGE}"

SUPER_LINTER_COMMAND=(
  docker run
)

if [ -t 0 ]; then
  SUPER_LINTER_COMMAND+=(
    --interactive
    --tty
  )
fi

if [ "${LINTER_CONTAINER_OPEN_SHELL:-}" == "true" ]; then
  SUPER_LINTER_COMMAND+=(
    --entrypoint "/bin/bash"
  )
fi

if [ "${LINTER_CONTAINER_FIX_MODE:-}" == "true" ]; then
  SUPER_LINTER_COMMAND+=(
    --env-file "config/lint/super-linter-fix-mode.env"
  )
fi

SUPER_LINTER_COMMAND+=(
  --env ACTIONS_RUNNER_DEBUG="${ACTIONS_RUNNER_DEBUG:-"false"}"
  --env DEFAULT_BRANCH="main"
  --env MULTI_STATUS="false"
  --env RUN_LOCAL="true"
  --env-file "config/lint/super-linter.env"
  --name "super-linter"
  --rm
  --volume "$(pwd)":/tmp/lint
  --volume /etc/localtime:/etc/localtime:ro
  --workdir /tmp/lint
  "${LINTER_CONTAINER_IMAGE}"
  "$@"
)

echo "Super-linter command: ${SUPER_LINTER_COMMAND[*]}"
"${SUPER_LINTER_COMMAND[@]}"
