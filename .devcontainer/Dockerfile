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

FROM hashicorp/terraform:1.9.0 as terraform

FROM mcr.microsoft.com/devcontainers/python:3.10

SHELL ["/bin/bash", "-o", "pipefail", "-o", "errexit", "-c"]

COPY --from=terraform /bin/terraform /usr/bin/

COPY ./requirements.txt /tmp/pip-tmp/devcontainer-requirements.txt

# Tell pip how to find legacy releases
RUN pip3 install --no-cache-dir --upgrade pip \
    && pip3 \
    --no-cache-dir install \
    --find-links https://storage.googleapis.com/jax-releases/jax_releases.html \
    --requirement /tmp/pip-tmp/devcontainer-requirements.txt \
    && rm -rf /tmp/pip-tmp
