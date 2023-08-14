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

CONTAINER_IMAGE_LOCALIZED_ID="${1}"
DISTRIBUTED_TFF_EXAMPLE_CONTAINER_IMAGE_BUILD_CONTEXT_PATH="${5}"

echo "Build the ${CONTAINER_IMAGE_LOCALIZED_ID} container image. Context: ${DISTRIBUTED_TFF_EXAMPLE_CONTAINER_IMAGE_BUILD_CONTEXT_PATH}"
docker build \
  --file "${DISTRIBUTED_TFF_EXAMPLE_CONTAINER_IMAGE_BUILD_CONTEXT_PATH}/Dockerfile" \
  --tag "${CONTAINER_IMAGE_LOCALIZED_ID}" \
  "${DISTRIBUTED_TFF_EXAMPLE_CONTAINER_IMAGE_BUILD_CONTEXT_PATH}"

echo "Authenticating Docker against ${_CONTAINER_IMAGE_REPOSITORY_HOSTNAME}"
gcloud auth configure-docker \
  "${_CONTAINER_IMAGE_REPOSITORY_HOSTNAME}"

echo "Pushing the ${CONTAINER_IMAGE_LOCALIZED_ID} container image"
docker image push "${CONTAINER_IMAGE_LOCALIZED_ID}"
