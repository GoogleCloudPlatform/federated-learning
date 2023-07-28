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

import collections
from typing import Any, List, Optional

import grpc
import nest_asyncio
import tensorflow as tf
import tensorflow_federated as tff

nest_asyncio.apply()


class FederatedData(
    tff.program.FederatedDataSource, tff.program.FederatedDataSourceIterator
):
    """Interface for interacting with the federated training data."""

    def __init__(self, type_spec: tff.FederatedType):
        self._type_spec = type_spec
        self._capabilities = [tff.program.Capability.RANDOM_UNIFORM]

    @property
    def federated_type(self) -> tff.FederatedType:
        return self._type_spec

    @property
    def capabilities(self) -> List[tff.program.Capability]:
        return self._capabilities

    def iterator(self) -> tff.program.FederatedDataSourceIterator:
        return self

    def select(self, num_clients: Optional[int] = None) -> Any:
        data_uris = [f"uri://{i}" for i in range(num_clients)]
        return tff.framework.CreateDataDescriptor(
            arg_uris=data_uris, arg_type=self._type_spec
        )


input_spec = collections.OrderedDict(
    [
        ("x", tf.TensorSpec(shape=(1, 784), dtype=tf.float32, name=None)),
        ("y", tf.TensorSpec(shape=(1, 1), dtype=tf.int32, name=None)),
    ]
)
element_type = tff.types.StructWithPythonType(
    input_spec, container_type=collections.OrderedDict
)
dataset_type = tff.types.SequenceType(element_type)

train_data_source = FederatedData(type_spec=dataset_type)
train_data_iterator = train_data_source.iterator()


def model_fn():
    model = tf.keras.models.Sequential(
        [
            tf.keras.layers.InputLayer(input_shape=(784,)),
            tf.keras.layers.Dense(units=10, kernel_initializer="zeros"),
            tf.keras.layers.Softmax(),
        ]
    )
    return tff.learning.from_keras_model(
        model,
        input_spec=input_spec,
        loss=tf.keras.losses.SparseCategoricalCrossentropy(),
        metrics=[tf.keras.metrics.SparseCategoricalAccuracy()],
    )


trainer = tff.learning.algorithms.build_weighted_fed_avg(
    model_fn,
    client_optimizer_fn=lambda: tf.keras.optimizers.SGD(learning_rate=0.02),
    server_optimizer_fn=lambda: tf.keras.optimizers.SGD(learning_rate=1.0),
)


def train_loop(num_rounds=10, num_clients=10):
    state = trainer.initialize()
    for round in range(1, num_rounds + 1):
        train_data = train_data_iterator.select(num_clients)
        result = trainer.next(state, train_data)
        state = result.state
        train_metrics = result.metrics["client_work"]["train"]
        print("round {:2d}, metrics={}".format(round, train_metrics))


# TODO: get these IPs from environment variables or arguments
ip_address_1 = "0.0.0.0"
ip_address_2 = "0.0.0.0"
port = 8000

print("\n".join(sys.argv[1:]))

channels = [
    grpc.insecure_channel(f"{ip_address_1}:{port}"),
    grpc.insecure_channel(f"{ip_address_2}:{port}"),
]

tff.backends.native.set_remote_python_execution_context(channels)

train_loop()
