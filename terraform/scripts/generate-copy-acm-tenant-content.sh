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

TENANTS_CONFIGURATION_DIRECTORY_PATH="${1}"
TENANT_CONFIGURATION_PACKAGE_PATH="${2}"
TENANT="${3}"
TENANT_APPS_SERVICE_ACCOUNT_EMAIL="${4}"
TENANT_DEVELOPER_EMAIL="${5}"
DISTRIBUTED_TFF_EXAMPLE_DEPLOY="${6}"

TENANT_CONFIGURATION_DIRECTORY_PATH="${TENANTS_CONFIGURATION_DIRECTORY_PATH}/${TENANT}"

mkdir -vp "${TENANTS_CONFIGURATION_DIRECTORY_PATH}"

echo "Configuring ${TENANT_CONFIGURATION_PACKAGE_PATH} package for ${TENANT} tenant. Output directory: ${TENANT_CONFIGURATION_DIRECTORY_PATH}"

kpt fn eval --image gcr.io/kpt-fn/apply-setters:v0.2 "${TENANT_CONFIGURATION_PACKAGE_PATH}" --output="${TENANT_CONFIGURATION_DIRECTORY_PATH}" -- \
  tenant-name="${TENANT}" \
  gcp-service-account="${TENANT_APPS_SERVICE_ACCOUNT_EMAIL}" \
  tenant-developer="${TENANT_DEVELOPER_EMAIL}"

if [ "${DISTRIBUTED_TFF_EXAMPLE_DEPLOY}" = "true" ]; then
  DISTRIBUTED_TFF_EXAMPLE_PACKAGE_PATH="${7}"
  IS_TFF_COORDINATOR="${8}"

  TFF_WORKER_EMNIST_PARTITION_FILE_NAME="${9:-"not-needed"}"

  TFF_WORKER_1_ADDRESS="${10:-"not-needed"}"
  TFF_WORKER_2_ADDRESS="${11:-"not-needed"}"

  TFF_COORDINATOR_POD_SERVICE_ACCOUNT_NAME="${12}"

  _CONTAINER_IMAGE_REPOSITORY_LOCATION="${13}"
  _CONTAINER_IMAGE_REPOSITORY_PROJECT_ID="${14}"
  _CONTAINER_IMAGE_REPOSITORY_NAME="${15}"
  _CONTAINER_IMAGE_REPOSITORY_HOSTNAME="${_CONTAINER_IMAGE_REPOSITORY_LOCATION}-docker.pkg.dev"
  _CONTAINER_IMAGE_REPOSITORY_ID="${_CONTAINER_IMAGE_REPOSITORY_HOSTNAME}/${_CONTAINER_IMAGE_REPOSITORY_PROJECT_ID}/${_CONTAINER_IMAGE_REPOSITORY_NAME}"
  _CONTAINER_IMAGE_LOCALIZED_ID="${_CONTAINER_IMAGE_REPOSITORY_ID}/tff-runtime:latest"

  DISTRIBUTED_TFF_EXAMPLE_OUTPUT_DIRECTORY_PATH="${TENANT_CONFIGURATION_DIRECTORY_PATH}/example-tff-image-classification"

  DISTRIBUTED_TFF_EXAMPLE_CONTAINER_IMAGE_BUILD_CONTEXT_PATH="${DISTRIBUTED_TFF_EXAMPLE_PACKAGE_PATH}/.."

  echo "Configuring ${DISTRIBUTED_TFF_EXAMPLE_PACKAGE_PATH} package for ${TENANT} namespace. Output directory: ${DISTRIBUTED_TFF_EXAMPLE_OUTPUT_DIRECTORY_PATH}"

  kpt fn eval "${DISTRIBUTED_TFF_EXAMPLE_PACKAGE_PATH}" --image gcr.io/kpt-fn/apply-setters:v0.2.0 --output="${DISTRIBUTED_TFF_EXAMPLE_OUTPUT_DIRECTORY_PATH}" -- \
    namespace="${TENANT}" \
    tff-pod-service-account-name="${TFF_COORDINATOR_POD_SERVICE_ACCOUNT_NAME}" \
    tff-workload-emnist-partition-file-name="${TFF_WORKER_EMNIST_PARTITION_FILE_NAME}" \
    tff-worker-1-address="${TFF_WORKER_1_ADDRESS}" \
    tff-worker-2-address="${TFF_WORKER_2_ADDRESS}" \
    tff-runtime-container-image-id="${_CONTAINER_IMAGE_LOCALIZED_ID}"

  if [ "${IS_TFF_COORDINATOR}" = "false" ]; then
    echo "This configuration is for a worker. Deleting worker-specific configuration."
    rm -v "${DISTRIBUTED_TFF_EXAMPLE_OUTPUT_DIRECTORY_PATH}/deployment-coordinator.yaml"
    rm -v "${DISTRIBUTED_TFF_EXAMPLE_OUTPUT_DIRECTORY_PATH}/service-mesh-coordinator.yaml"
  else
    echo "This configuration is for a coordinator. Deleting coordinator-specific configuration."
    rm -v "${DISTRIBUTED_TFF_EXAMPLE_OUTPUT_DIRECTORY_PATH}/deployment.yaml" "${DISTRIBUTED_TFF_EXAMPLE_OUTPUT_DIRECTORY_PATH}/service.yaml"
  fi

  echo "Build the ${_CONTAINER_IMAGE_LOCALIZED_ID} container image. Context: ${DISTRIBUTED_TFF_EXAMPLE_CONTAINER_IMAGE_BUILD_CONTEXT_PATH}"
  docker build \
    --file examples/federated-learning/tff/distributed-fl-simulation-k8s/Dockerfile \
    --tag "${_CONTAINER_IMAGE_LOCALIZED_ID}" \
    "${DISTRIBUTED_TFF_EXAMPLE_CONTAINER_IMAGE_BUILD_CONTEXT_PATH}"

  echo "Authenticating Docker against ${_CONTAINER_IMAGE_REPOSITORY_HOSTNAME}"
  gcloud auth configure-docker \
    "${_CONTAINER_IMAGE_REPOSITORY_HOSTNAME}"

  echo "Pushing the ${_CONTAINER_IMAGE_LOCALIZED_ID} container image"
  docker image push "${_CONTAINER_IMAGE_LOCALIZED_ID}"
fi
