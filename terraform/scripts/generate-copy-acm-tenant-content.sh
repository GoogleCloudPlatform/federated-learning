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
