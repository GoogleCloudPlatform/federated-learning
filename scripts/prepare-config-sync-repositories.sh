#!/usr/bin/env sh

# Copyright 2023 Google LLC
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

set -o nounset
set -o errexit

# Doesn't follow symlinks, but it's likely expected for most users
SCRIPT_BASENAME="$(basename "${0}")"
SCRIPT_DIRECTORY_PATH="$(dirname "${0}")"

echo "This script (${SCRIPT_BASENAME}) has been invoked with: $0 $*"
echo "This script directory path is: ${SCRIPT_DIRECTORY_PATH}"

# shellcheck source=/dev/null
. "${SCRIPT_DIRECTORY_PATH}/common.sh"

CONFIG_SYNC_REPOSITORY_URL="${1:-}"

check_argument "${CONFIG_SYNC_REPOSITORY_URL}" "Config Sync repository URL"

CONFIG_SYNC_REPOSITORY_DIRECTORY_PATH="$(mktemp -d)"
echo "Source repository path: ${CONFIG_SYNC_REPOSITORY_DIRECTORY_PATH}"

clone_git_repository_if_not_cloned_already "${CONFIG_SYNC_REPOSITORY_DIRECTORY_PATH}" "${CONFIG_SYNC_REPOSITORY_URL}"

git -C "${CONFIG_SYNC_REPOSITORY_DIRECTORY_PATH}" config pull.ff only

BLUEPRINT_REPOSITORY_DIRECTORY_PATH="${SCRIPT_DIRECTORY_PATH}/.."
echo "Blueprint repository path: ${BLUEPRINT_REPOSITORY_DIRECTORY_PATH}"

cp -rv "${BLUEPRINT_REPOSITORY_DIRECTORY_PATH}/configsync" "${CONFIG_SYNC_REPOSITORY_DIRECTORY_PATH}/"

git -C "${CONFIG_SYNC_REPOSITORY_DIRECTORY_PATH}" push -u origin main
