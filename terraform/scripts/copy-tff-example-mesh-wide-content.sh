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

ARE_WORKERS_OUTSIDE_MESH="${4:-"false"}"
echo "ARE_WORKERS_OUTSIDE_MESH: ${ARE_WORKERS_OUTSIDE_MESH}"

IS_THERE_A_COORDINATOR="${5:-"false"}"
echo "IS_THERE_A_COORDINATOR: ${IS_THERE_A_COORDINATOR}"

if [ "${IS_THERE_A_COORDINATOR}" = "false" ] || [ "${ARE_WORKERS_OUTSIDE_MESH}" = "false" ]; then
  rm -v "${DESTINATION_DIRECTORY_PATH}/service-mesh-workers-outside-mesh.yaml"
fi

# These are leftovers from previous development iterations that we don't need anymore
rm -fv "${DESTINATION_DIRECTORY_PATH}/service-mesh-workers-inside-mesh.yaml"
