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

# This is needed because Terraform doesn't handle all cases when destroying a resource.
# Ref: https://github.com/hashicorp/terraform/issues/13549#issuecomment-293627472
rm -rfv "${TENANT_CONFIGURATION_DIRECTORY_PATH}"

echo "Configuring ${TENANT_CONFIGURATION_PACKAGE_PATH} package for ${TENANT} tenant. Output directory: ${TENANT_CONFIGURATION_DIRECTORY_PATH}"
mkdir -vp "${TENANTS_CONFIGURATION_DIRECTORY_PATH}"

kpt fn eval --image gcr.io/kpt-fn/apply-setters:v0.2 "${TENANT_CONFIGURATION_PACKAGE_PATH}" --output="${TENANT_CONFIGURATION_DIRECTORY_PATH}" --truncate-output=false -- \
  tenant-name="${TENANT}" \
  gcp-service-account="${TENANT_APPS_SERVICE_ACCOUNT_EMAIL}" \
  tenant-developer="${TENANT_DEVELOPER_EMAIL}"

echo "DISTRIBUTED_TFF_EXAMPLE_DEPLOY: ${DISTRIBUTED_TFF_EXAMPLE_DEPLOY}"

if [ "${DISTRIBUTED_TFF_EXAMPLE_DEPLOY}" = "true" ]; then
  DISTRIBUTED_TFF_EXAMPLE_PACKAGE_PATH="${7}"
  IS_TFF_COORDINATOR="${8}"
  TFF_WORKER_EMNIST_PARTITION_FILE_NAME="${9:-"not-needed"}"
  TFF_WORKER_1_ADDRESS="${10:-"not-needed"}"
  TFF_WORKER_1_HOSTNAME="${11:-"not-needed"}"
  TFF_WORKER_2_ADDRESS="${12:-"not-needed"}"
  TFF_WORKER_2_HOSTNAME="${13:-"not-needed"}"
  TFF_COORDINATOR_POD_SERVICE_ACCOUNT_NAME="${14}"
  TFF_COORDINATOR_NAMESPACE="${15:-"istio-ingress"}"
  CONFIGURE_WORKER_INGRESS_GATEWAY="${16:-"false"}"
  ARE_WORKERS_OUTSIDE_MESH="${17:-"false"}"
  DISTRIBUTED_TFF_EXAMPLE_CONTAINER_IMAGE_LOCALIZED_ID="${18}"

  echo "ARE_WORKERS_OUTSIDE_MESH: ${ARE_WORKERS_OUTSIDE_MESH}"

  DISTRIBUTED_TFF_EXAMPLE_OUTPUT_DIRECTORY_PATH="${TENANT_CONFIGURATION_DIRECTORY_PATH}/example-tff-image-classification"

  echo "Configuring ${DISTRIBUTED_TFF_EXAMPLE_PACKAGE_PATH} package for ${TENANT} namespace. Output directory: ${DISTRIBUTED_TFF_EXAMPLE_OUTPUT_DIRECTORY_PATH}"

  kpt fn eval "${DISTRIBUTED_TFF_EXAMPLE_PACKAGE_PATH}" --image gcr.io/kpt-fn/apply-setters:v0.2.0 --output="${DISTRIBUTED_TFF_EXAMPLE_OUTPUT_DIRECTORY_PATH}" --truncate-output=false -- \
    coordinator-namespace="${TFF_COORDINATOR_NAMESPACE}" \
    namespace="${TENANT}" \
    tff-pod-service-account-name="${TFF_COORDINATOR_POD_SERVICE_ACCOUNT_NAME}" \
    tff-workload-emnist-partition-file-name="${TFF_WORKER_EMNIST_PARTITION_FILE_NAME}" \
    tff-worker-1-address="${TFF_WORKER_1_ADDRESS}" \
    tff-worker-1-hostname="${TFF_WORKER_1_HOSTNAME}" \
    tff-worker-2-address="${TFF_WORKER_2_ADDRESS}" \
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

    if [ "${ARE_WORKERS_OUTSIDE_MESH}" = "false" ]; then
      rm -v "${DISTRIBUTED_TFF_EXAMPLE_OUTPUT_DIRECTORY_PATH}/service-mesh-workers-outside-mesh.yaml"
    fi
  fi

  # These are leftovers from previous development iterations that we don't need anymore
  rm -fv \
    "${DISTRIBUTED_TFF_EXAMPLE_OUTPUT_DIRECTORY_PATH}/service-mesh-coordinator.yaml"
fi
