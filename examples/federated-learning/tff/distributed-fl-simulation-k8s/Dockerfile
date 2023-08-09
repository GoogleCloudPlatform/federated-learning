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

FROM gcr.io/google.com/cloudsdktool/google-cloud-cli:441.0.0 as gcloud

ENV DATASET_DESTINATION_DIRECTORY_PATH="/tmp/dataset/emnist-partitions/2-partition"

RUN gsutil -m cp gs://tff-datasets-public/emnist-partitions/2-partition/emnist_part_1.sqlite "${DATASET_DESTINATION_DIRECTORY_PATH}/emnist_part_1.sqlite" \
    && gsutil -m cp gs://tff-datasets-public/emnist-partitions/2-partition/emnist_part_2.sqlite "${DATASET_DESTINATION_DIRECTORY_PATH}/emnist_part_2.sqlite"

FROM python:3.11-buster

WORKDIR "/"
COPY requirements.txt requirements.txt

RUN pip install --no-cache-dir --upgrade pip

RUN pip install \
    --no-cache-dir \
    --requirement requirements.txt \
    && rm requirements.txt

ENV RUN_DIR="/root/worker"
WORKDIR "${RUN_DIR}"

ENV EMNIST_PARTITION_DIRECTORY_PATH="${RUN_DIR}/data/"

# For simplicity, we copy all the partitions and executables.
# This makes the container image bigger, but it's fine for demo purposes.
COPY --from=gcloud "/tmp/dataset/emnist-partitions/2-partition" "${EMNIST_PARTITION_DIRECTORY_PATH}"
COPY ./worker_service.py "${RUN_DIR}/"
COPY ./training_procedure.py "${RUN_DIR}/"

ENTRYPOINT [ "python3" ]

# Run the worker workload by default
CMD [ "./worker_service.py" ]

EXPOSE 8000
