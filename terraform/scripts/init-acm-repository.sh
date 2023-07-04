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

ACM_REPOSITORY_PATH="${1}"
ACM_REPOSITORY_URL="${2}"
ACM_BRANCH="${3}"

mkdir -vp "${ACM_REPOSITORY_PATH}"
git clone "${ACM_REPOSITORY_URL}" "${ACM_REPOSITORY_PATH}"
git -C "${ACM_REPOSITORY_PATH}" config pull.ff only
git -C "${ACM_REPOSITORY_PATH}" config user.email "committer@example.com"
git -C "${ACM_REPOSITORY_PATH}" config user.name "Config Sync committer"
git -C "${ACM_REPOSITORY_PATH}" switch "${ACM_BRANCH}"
