#!/bin/sh
# Copyright 2021 Google LLC
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


# fetch the current ConfigSync configuration for the supplied Hub membership
if [ -z "$1" ]; then
    echo "Please specify the Hub membership name."
    exit 1
fi
echo "Hub membership name: $1"
CONFIGSYNC_SPEC=$(gcloud alpha container hub config-management fetch-for-apply --membership "$1")
# write a local temp file, setting the value of mutations flag
tmpfile=$(mktemp)
echo "${CONFIGSYNC_SPEC}" | sed 's/mutationEnabled: false/mutationEnabled: true/g' > "$tmpfile"

# apply the updated config
gcloud alpha container hub config-management apply --membership "$1" --config "$tmpfile"
echo "Enabled Policy Controller mutations"
# cleanup
rm "$tmpfile"
