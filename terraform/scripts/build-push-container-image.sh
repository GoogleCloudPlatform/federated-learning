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

_CONTAINER_IMAGE_REPOSITORY_LOCATION="${1}"
_CONTAINER_IMAGE_REPOSITORY_PROJECT_ID="${2}"
_CONTAINER_IMAGE_REPOSITORY_NAME="${3}"
_CONTAINER_IMAGE_IMAGE_TAG="${4}"

DISTRIBUTED_TFF_EXAMPLE_CONTAINER_IMAGE_BUILD_CONTEXT_PATH="${5}"

_CONTAINER_IMAGE_REPOSITORY_HOSTNAME="${_CONTAINER_IMAGE_REPOSITORY_LOCATION}-docker.pkg.dev"
_CONTAINER_IMAGE_REPOSITORY_ID="${_CONTAINER_IMAGE_REPOSITORY_HOSTNAME}/${_CONTAINER_IMAGE_REPOSITORY_PROJECT_ID}/${_CONTAINER_IMAGE_REPOSITORY_NAME}"
_CONTAINER_IMAGE_LOCALIZED_ID="${_CONTAINER_IMAGE_REPOSITORY_ID}/tff-runtime:${_CONTAINER_IMAGE_IMAGE_TAG}"

echo "Build the ${_CONTAINER_IMAGE_LOCALIZED_ID} container image. Context: ${DISTRIBUTED_TFF_EXAMPLE_CONTAINER_IMAGE_BUILD_CONTEXT_PATH}"
docker build \
  --file "${DISTRIBUTED_TFF_EXAMPLE_CONTAINER_IMAGE_BUILD_CONTEXT_PATH}/Dockerfile" \
  --tag "${_CONTAINER_IMAGE_LOCALIZED_ID}" \
  "${DISTRIBUTED_TFF_EXAMPLE_CONTAINER_IMAGE_BUILD_CONTEXT_PATH}"

echo "Authenticating Docker against ${_CONTAINER_IMAGE_REPOSITORY_HOSTNAME}"
gcloud auth configure-docker \
  "${_CONTAINER_IMAGE_REPOSITORY_HOSTNAME}"

echo "Pushing the ${_CONTAINER_IMAGE_LOCALIZED_ID} container image"
docker image push "${_CONTAINER_IMAGE_LOCALIZED_ID}"
