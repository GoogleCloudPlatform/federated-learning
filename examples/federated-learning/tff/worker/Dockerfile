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

FROM python:3.10-bookworm

WORKDIR "/"
COPY requirements.txt requirements.txt

RUN pip install --no-cache-dir --upgrade pip

RUN pip install \
    --no-cache-dir \
    --requirement requirements.txt \
    && rm requirements.txt

ENV RUN_DIR="/root/worker"

# File path to the sqlite database storing a partition of the EMNIST dataset.
ENV EMNIST_PARTITION_PATH="$RUN_DIR/data/emnist_partition.sqlite"

WORKDIR "${RUN_DIR}"

ARG WORKER_SRC_PATH="./worker_service.py"
COPY $WORKER_SRC_PATH $RUN_DIR

EXPOSE 8000

ENTRYPOINT [ "python3", "${WORKER_SRC_PATH}" ]
