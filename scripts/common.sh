#!/usr/bin/env sh

set -o errexit
set -o nounset

# shellcheck disable=SC2034
ERR_ARGUMENT_EVAL=2
ERR_MISSING_GITHUB_TOKEN_FILE=3

CD_CONTAINER_URL="googlecloudplatform/federated-learning-devcontainer:latest"

GITHUB_TOKEN_PATH="$(pwd)/.github-personal-access-token"

_DOCKER_INTERACTIVE_TTY_OPTION=
if [ -t 0 ]; then
  _DOCKER_INTERACTIVE_TTY_OPTION="-it"
fi

build_cd_container() {
  echo "Build CD container: ${CD_CONTAINER_URL}"
  docker build \
    --tag "${CD_CONTAINER_URL}" \
    container-images/ci-tooling
}

check_github_token_file() {
  if [ ! -f "${GITHUB_TOKEN_PATH}" ]; then
    echo "Error: ${GITHUB_TOKEN_PATH} doesn't exist, or is not a file."
    exit "${ERR_MISSING_GITHUB_TOKEN_FILE}"
  fi
}
