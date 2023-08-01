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
TFF_WORKER_EMNIST_PARTITION_NAME="${4}"
TFF_WORKER_1_ADDRESS="${5}"
TFF_WORKER_2_ADDRESS="${6}"

TENANT_CONFIGURATION_DIRECTORY_PATH="${TENANTS_CONFIGURATION_DIRECTORY_PATH}/${TENANT}"

mkdir -vp "${TENANTS_CONFIGURATION_DIRECTORY_PATH}"

echo "Configuring ${TENANT_CONFIGURATION_PACKAGE_PATH} package for ${TENANT} tenant. Output directory: ${TENANT_CONFIGURATION_DIRECTORY_PATH}"

kpt fn render "${TENANT_CONFIGURATION_PACKAGE_PATH}" --output="unwrap" \
  | kpt fn eval --image gcr.io/kpt-fn/apply-setters:v0.2.0 "${TENANT_CONFIGURATION_PACKAGE_PATH}" --output="${TENANT_CONFIGURATION_DIRECTORY_PATH}" -- \
  namespace="${TENANT}" \
  tff-coordinator-service-account-name="${TENANT}" \
  tff-workload-emnist-partition-file-name="${TFF_WORKER_EMNIST_PARTITION_NAME}" \
  tff-worker-service-account-name="${TENANT}" \
  tff-worker-1-address="${TFF_WORKER_1_ADDRESS}" \
  tff-worker-2-address="${TFF_WORKER_2_ADDRESS}"
