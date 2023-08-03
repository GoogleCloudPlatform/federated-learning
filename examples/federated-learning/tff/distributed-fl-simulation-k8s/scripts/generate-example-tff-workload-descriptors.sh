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

KPT_PACKAGE_PATH="${1}"
NAMESPACE="${2}"
TERRAFORM_ENVIRONMENT_DIRECTORY_PATH="${3}"
IS_TFF_COORDINATOR="${4:-"false"}"
TFF_WORKER_EMNIST_PARTITION_FILE_NAME="${5:-"not-needed"}"

TFF_WORKER_1_ADDRESS="${6:-"not-needed"}"
TFF_WORKER_2_ADDRESS="${7:-"not-needed"}"

echo "Loading data from Terraform"
OUTPUT_DIRECTORY_PATH="$(terraform -chdir="${TERRAFORM_ENVIRONMENT_DIRECTORY_PATH}" output -raw config_sync_repository_tenants_configuration_directory_path)/${NAMESPACE}/example-tff-image-classification"
TFF_COORDINATOR_POD_SERVICE_ACCOUNT_NAME="$(terraform -chdir="${TERRAFORM_ENVIRONMENT_DIRECTORY_PATH}" output -raw kubernetes_apps_service_account_name)"

_CONTAINER_IMAGE_REPOSITORY_LOCATION="$(terraform -chdir="${TERRAFORM_ENVIRONMENT_DIRECTORY_PATH}" output -raw artifact_registry_container_image_repository_location)"
_CONTAINER_IMAGE_REPOSITORY_PROJECT_ID="$(terraform -chdir="${TERRAFORM_ENVIRONMENT_DIRECTORY_PATH}" output -raw artifact_registry_container_image_repository_project_id)"
_CONTAINER_IMAGE_REPOSITORY_NAME="$(terraform -chdir="${TERRAFORM_ENVIRONMENT_DIRECTORY_PATH}" output -raw artifact_registry_container_image_repository_name)"
_CONTAINER_IMAGE_REPOSITORY_HOSTNAME="${_CONTAINER_IMAGE_REPOSITORY_LOCATION}-docker.pkg.dev"
_CONTAINER_IMAGE_REPOSITORY_ID="${_CONTAINER_IMAGE_REPOSITORY_HOSTNAME}/${_CONTAINER_IMAGE_REPOSITORY_PROJECT_ID}/${_CONTAINER_IMAGE_REPOSITORY_NAME}"
_CONTAINER_IMAGE_LOCALIZED_ID="${_CONTAINER_IMAGE_REPOSITORY_ID}/tff-runtime:latest"

TFF_WORKER_1_ADDRESS="not-needed"
TFF_WORKER_2_ADDRESS="not-needed"

echo "Configuring ${KPT_PACKAGE_PATH} package for ${NAMESPACE} namespace. Output directory: ${OUTPUT_DIRECTORY_PATH}"

kpt fn eval "${KPT_PACKAGE_PATH}" --image gcr.io/kpt-fn/apply-setters:v0.2.0 --output="${OUTPUT_DIRECTORY_PATH}" -- \
  namespace="${NAMESPACE}" \
  tff-pod-service-account-name="${TFF_COORDINATOR_POD_SERVICE_ACCOUNT_NAME}" \
  tff-workload-emnist-partition-file-name="${TFF_WORKER_EMNIST_PARTITION_FILE_NAME}" \
  tff-worker-1-address="${TFF_WORKER_1_ADDRESS}" \
  tff-worker-2-address="${TFF_WORKER_2_ADDRESS}" \
  tff-runtime-container-image-id="${_CONTAINER_IMAGE_LOCALIZED_ID}"

if [ "${IS_TFF_COORDINATOR}" = "false" ]; then
  echo "This configuration is for a worker. Deleting worker-specific configuration."
  rm -v "${OUTPUT_DIRECTORY_PATH}/deployment-coordinator.yaml"
else
  echo "This configuration is for a worker. Deleting coordinator-specific configuration."
  rm -v "${OUTPUT_DIRECTORY_PATH}/deployment.yaml" "${OUTPUT_DIRECTORY_PATH}/service.yaml"
fi

echo "Build the ${_CONTAINER_IMAGE_LOCALIZED_ID} container image"
docker build \
  --file examples/federated-learning/tff/distributed-fl-simulation-k8s/Dockerfile \
  --tag "${_CONTAINER_IMAGE_LOCALIZED_ID}" \
  examples/federated-learning/tff/distributed-fl-simulation-k8s

echo "Pushing the ${_CONTAINER_IMAGE_LOCALIZED_ID} container image"
docker image push "${_CONTAINER_IMAGE_LOCALIZED_ID}"
