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

OUTPUT_DIRECTORY_PATH="${1}"
KPT_PACKAGE_PATH="${2}"
NAMESPACE="${3}"
TFF_COORDINATOR_POD_SERVICE_ACCOUNT_NAME="${4}"
TFF_WORKER_EMNIST_PARTITION_FILE_NAME="${5}"
TFF_WORKER_POD_SERVICE_ACCOUNT_NAME="${6}"
TFF_WORKER_1_ADDRESS="${7}"
TFF_WORKER_2_ADDRESS="${8}"

IS_TFF_COORDINATOR="${9:-"false"}"

echo "Configuring ${KPT_PACKAGE_PATH} package for ${NAMESPACE} namespace. Output directory: ${OUTPUT_DIRECTORY_PATH}"

kpt fn render "${KPT_PACKAGE_PATH}" --output="unwrap" |
  kpt fn eval --image gcr.io/kpt-fn/apply-setters:v0.2.0 --output="${OUTPUT_DIRECTORY_PATH}" - -- \
    namespace="${NAMESPACE}" \
    tff-coordinator-service-account-name="${TFF_COORDINATOR_POD_SERVICE_ACCOUNT_NAME}" \
    tff-workload-emnist-partition-file-name="${TFF_WORKER_EMNIST_PARTITION_FILE_NAME}" \
    tff-worker-service-account-name="${TFF_WORKER_POD_SERVICE_ACCOUNT_NAME}" \
    tff-worker-1-address="${TFF_WORKER_1_ADDRESS}" \
    tff-worker-2-address="${TFF_WORKER_2_ADDRESS}"

if [ "${IS_TFF_COORDINATOR}" = "false" ]; then
  echo "This configuration is for a worker. Deleting worker-specific configuration."
  rm -v "${OUTPUT_DIRECTORY_PATH}/deployment-coordinator.yaml"
else
  echo "This configuration is for a worker. Deleting coordinator-specific configuration."
  rm -v "${OUTPUT_DIRECTORY_PATH}/deployment.yaml" "${OUTPUT_DIRECTORY_PATH}/service.yaml"
fi
