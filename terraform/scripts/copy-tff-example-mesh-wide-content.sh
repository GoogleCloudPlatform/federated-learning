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

SOURCE_DIRECTORY_PATH="${1}"
DESTINATION_DIRECTORY_PATH="${2}"

cp -rv "${SOURCE_DIRECTORY_PATH}" "${DESTINATION_DIRECTORY_PATH}"

DEPLOY_INGRESS_GATEWAY="${3:-"false"}"
echo "DEPLOY_INGRESS_GATEWAY: ${DEPLOY_INGRESS_GATEWAY}"

if [ "${DEPLOY_INGRESS_GATEWAY}" = "false" ]; then
  INGRESS_GATEWAY_DESCRIPTOR_PATH="${DESTINATION_DIRECTORY_PATH}/ingress-gateway.yaml"
  echo "Ingress Gateway is not enabled. Deleting ${INGRESS_GATEWAY_DESCRIPTOR_PATH}"
  rm -v "${INGRESS_GATEWAY_DESCRIPTOR_PATH}"
fi

DEPLOY_SERVICE_ENTRIES_WORKERS_OUTSIDE_MESH="${4:-"false"}"
echo "DEPLOY_SERVICE_ENTRIES_WORKERS_OUTSIDE_MESH: ${DEPLOY_SERVICE_ENTRIES_WORKERS_OUTSIDE_MESH}"

if [ "${DEPLOY_SERVICE_ENTRIES_WORKERS_OUTSIDE_MESH}" = "false" ]; then
  SERVICE_ENTRIES_WORKERS_OUTSIDE_MESH_DESCRIPTOR_PATH="${DESTINATION_DIRECTORY_PATH}/service-entries-workers-outside-mesh.yaml"
  echo "Service Entries for workers outside the mesh are not enabled. Deleting ${SERVICE_ENTRIES_WORKERS_OUTSIDE_MESH_DESCRIPTOR_PATH}"
  rm -v "${SERVICE_ENTRIES_WORKERS_OUTSIDE_MESH_DESCRIPTOR_PATH}"
fi
