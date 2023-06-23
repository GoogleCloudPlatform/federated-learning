#!/usr/bin/env sh

# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset

check_argument() {
  ARGUMENT_VALUE="${1}"
  ARGUMENT_DESCRIPTION="${2}"

  if [ -z "${ARGUMENT_VALUE}" ]; then
    echo "[ERROR]: ${ARGUMENT_DESCRIPTION} is not defined. Run this command with the -h option to get help. Terminating..."
    # Ignoring because those are defined in common.sh, and don't need quotes
    # shellcheck disable=SC2086
    exit ${ERR_VARIABLE_NOT_DEFINED}
  else
    echo "[OK]: ${ARGUMENT_DESCRIPTION} value is defined: ${ARGUMENT_VALUE}"
  fi

  unset ARGUMENT_NAME
  unset ARGUMENT_VALUE
}

clone_git_repository_if_not_cloned_already() {
  destination_dir="$1"
  git_repository_url="$2"

  if [ -z "${destination_dir}" ]; then
    echo "ERROR while cloning the $git_repository_url git repository: The destination_dir variable is not set, or set to an empty string"
    exit 1
  fi

  if [ -d "${destination_dir}" ]; then
    echo "${destination_dir} already exists. Skipping..."
  else
    mkdir -p "$destination_dir"
    echo "Cloning $git_repository_url in $destination_dir"
    git clone "$git_repository_url" "$destination_dir"
  fi
  unset destination_dir
  unset git_repository_url
}

is_git_detached_head() {
  if [ "$(git rev-parse --abbrev-ref --symbolic-full-name HEAD)" = "HEAD" ]; then
    return 0
  else
    return 1
  fi
}

update_git_repository() {
  destination_dir="${1}"

  _git_dir="${destination_dir}/.git"
  if [ -d "${_git_dir}" ]; then
    echo "Updating repository in: ${destination_dir}"
    if ! is_git_detached_head; then
      git -C "${destination_dir}" pull
    else
      echo "${destination_dir} is in detached head state. Fetching only."
      git -C "${destination_dir}" fetch --all
    fi
  else
    echo "ERROR: ${_git_dir} doesn't exists"
    return 1
  fi
  unset _git_dir
  unset destination_dir
}
