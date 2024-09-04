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
TENANT="${2}"
DISTRIBUTED_TFF_EXAMPLE_PACKAGE_PATH="${3}"
IS_TFF_COORDINATOR="${4}"
TFF_WORKER_EMNIST_PARTITION_FILE_NAME="${5:-"not-needed"}"
TFF_WORKER_1_HOSTNAME="${6:-"not-needed"}"
TFF_WORKER_2_HOSTNAME="${7:-"not-needed"}"
TFF_COORDINATOR_POD_SERVICE_ACCOUNT_NAME="${8}"
TFF_COORDINATOR_NAMESPACE="${9:-"istio-ingress"}"
CONFIGURE_WORKER_INGRESS_GATEWAY="${10:-"false"}"
ARE_WORKERS_OUTSIDE_MESH="${11:-"false"}"
DISTRIBUTED_TFF_EXAMPLE_CONTAINER_IMAGE_LOCALIZED_ID="${12}"

DISTRIBUTED_TFF_EXAMPLE_OUTPUT_DIRECTORY_PATH="${TENANTS_CONFIGURATION_DIRECTORY_PATH}/${TENANT}/example-tff-image-classification"

echo "Configuring ${DISTRIBUTED_TFF_EXAMPLE_PACKAGE_PATH} package for ${TENANT} namespace. Output directory: ${DISTRIBUTED_TFF_EXAMPLE_OUTPUT_DIRECTORY_PATH}"

kpt fn eval "${DISTRIBUTED_TFF_EXAMPLE_PACKAGE_PATH}" --image gcr.io/kpt-fn/apply-setters:v0.2.0 --output="${DISTRIBUTED_TFF_EXAMPLE_OUTPUT_DIRECTORY_PATH}" --truncate-output=false -- \
  coordinator-namespace="${TFF_COORDINATOR_NAMESPACE}" \
  namespace="${TENANT}" \
  tff-pod-service-account-name="${TFF_COORDINATOR_POD_SERVICE_ACCOUNT_NAME}" \
  tff-workload-emnist-partition-file-name="${TFF_WORKER_EMNIST_PARTITION_FILE_NAME}" \
  tff-worker-1-hostname="${TFF_WORKER_1_HOSTNAME}" \
  tff-worker-2-hostname="${TFF_WORKER_2_HOSTNAME}" \
  tff-runtime-container-image-id="${DISTRIBUTED_TFF_EXAMPLE_CONTAINER_IMAGE_LOCALIZED_ID}"

if [ "${IS_TFF_COORDINATOR}" = "false" ]; then
  echo "This configuration is for a worker. Deleting coordinator-specific configuration."
  rm -fv \
    "${DISTRIBUTED_TFF_EXAMPLE_OUTPUT_DIRECTORY_PATH}/coordinator.yaml" \
    "${DISTRIBUTED_TFF_EXAMPLE_OUTPUT_DIRECTORY_PATH}/service-mesh-coordinator-workers-outside-mesh.yaml"

  if [ "${CONFIGURE_WORKER_INGRESS_GATEWAY}" = "false" ]; then
    echo "This configuration is for a worker but it doesn't need to be exposed using an ingress gateway. Deleting ingress gateway-specific configuration."
    rm -fv \
      "${DISTRIBUTED_TFF_EXAMPLE_OUTPUT_DIRECTORY_PATH}/service-mesh-worker-ingress-gateway.yaml"
  fi
else
  echo "This configuration is for a coordinator. Deleting worker-specific configuration."
  rm -fv \
    "${DISTRIBUTED_TFF_EXAMPLE_OUTPUT_DIRECTORY_PATH}/worker.yaml" \
    "${DISTRIBUTED_TFF_EXAMPLE_OUTPUT_DIRECTORY_PATH}/service-mesh-worker.yaml" \
    "${DISTRIBUTED_TFF_EXAMPLE_OUTPUT_DIRECTORY_PATH}/service-mesh-worker-ingress-gateway.yaml"

  echo "ARE_WORKERS_OUTSIDE_MESH: ${ARE_WORKERS_OUTSIDE_MESH}"
  if [ "${ARE_WORKERS_OUTSIDE_MESH}" = "false" ]; then
    rm -v "${DISTRIBUTED_TFF_EXAMPLE_OUTPUT_DIRECTORY_PATH}/service-mesh-coordinator-workers-outside-mesh.yaml"
  fi
fi

# These are leftovers from previous development iterations that we don't need anymore
rm -fv \
  "${DISTRIBUTED_TFF_EXAMPLE_OUTPUT_DIRECTORY_PATH}/service-mesh-coordinator.yaml"
