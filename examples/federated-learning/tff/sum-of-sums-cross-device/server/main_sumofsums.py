import asyncio
import argparse
import logging

from absl import flags
from absl.testing import absltest

import tensorflow as tf
import tensorflow_federated as tff

from fcp import demo
from fcp.client import client_runner_example_data_pb2
from fcp.protos import plan_pb2

logdir = "./logs"


@tff.federated_computation()
def initialize() -> tff.Value:
    """Returns the initial state."""
    return tff.federated_value(0, tff.SERVER)


@tff.federated_computation(
    tff.type_at_server(tf.int32), tff.type_at_clients(tff.SequenceType(tf.string))
)
def sum_counts(state, client_data):
    """Sums the value of all 'count' features across all clients."""

    @tf.function
    def reduce_counts(s: tf.int32, example: tf.string) -> tf.int32:
        features = {"count": tf.io.FixedLenFeature((), tf.int64)}
        count = tf.io.parse_example(example, features=features)["count"]
        return s + tf.cast(count, tf.int32)

    @tff.tf_computation
    def client_work(client_data):
        return client_data.reduce(0, reduce_counts)

    client_counts = tff.federated_map(client_work, client_data)
    aggregated_count = tff.federated_sum(client_counts)

    num_clients = tff.federated_sum(tff.federated_value(1, tff.CLIENTS))
    metrics = tff.federated_zip((num_clients,))
    return state + aggregated_count, metrics


async def program_logic(
    init_comp: tff.Computation,
    main_comp: tff.Computation,
    data_source: tff.program.FederatedDataSource,
    total_rounds: int,
    number_of_clients: int,
    release_manager: tff.program.ReleaseManager,
) -> None:
    """Initializes and runs a computation, releasing metrics and final state."""
    tff.program.check_in_federated_context()
    data_iterator = data_source.iterator()
    state = init_comp()

    try:
        tf.io.gfile.rmtree(logdir)
    except tf.errors.NotFoundError as e:
        pass
    summary_writer = tf.summary.create_file_writer(logdir)

    # Wrapper function for tensorboard
    with summary_writer.as_default():
        for i in range(total_rounds):
            logging.info(f"Starting round {i}")
            cohort_config = data_iterator.select(number_of_clients)
            state, metrics = main_comp(state, cohort_config)
            await release_manager.release(
                metrics, main_comp.type_signature.result[1], key=f"metrics/{i}"
            )
            # adding current sumOfsums to state
            await release_manager.release(
                state, main_comp.type_signature.result[0], key=f"result/{i}"
            )
            # adding data to tensorboard
            tf.summary.scalar("Number of rounds", i, step=i)
            tf.summary.scalar("number_of_clients", number_of_clients, step=i)
            tf.summary.scalar(
                "Current sumOfsums", release_manager.values()[f"result/{i}"][0], step=i
            )
    await release_manager.release(
        state, main_comp.type_signature.result[0], key="result"
    )
    logging.info(f"Finished {total_rounds} rounds")
    logging.info(f"Final result: {release_manager.values()}")
    print("values:", release_manager.values())


async def run_multiple_rounds(
    population_name: str,
    collection_uri: str,
    num_rounds: int,
    num_clients: int,
    host: str,
    port: int,
) -> None:
    data_source = demo.FederatedDataSource(
        population_name, plan_pb2.ExampleSelector(collection_uri=collection_uri)
    )
    comp = demo.FederatedComputation(sum_counts, name="sum_counts")
    release_manager = tff.program.MemoryReleaseManager()
    with demo.FederatedContext(
        population_name,
        base_context=tff.framework.get_context_stack().current,
        host=host,
        port=port,
    ) as ctx:
        with tff.framework.get_context_stack().install(ctx):
            program = program_logic(
                init_comp=initialize,
                main_comp=comp,
                data_source=data_source,
                total_rounds=num_rounds,
                number_of_clients=num_clients,
                release_manager=release_manager,
            )
            return_codes = await asyncio.gather(program)
            logging.log(logging.INFO, f"Return codes: {return_codes}")


def init_argparse() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Spin up a server for federated learning. Using Federated Compute Platform (FCP) to run federated learning sum of sums.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("--port", type=int, default=8000, help="Port to listen on")
    parser.add_argument("--host", type=str, default="0.0.0.0", help="Host to listen on")
    parser.add_argument(
        "--population", type=str, default="test/population", help="Population to use"
    )
    parser.add_argument(
        "--collection", type=str, default="app:/example", help="Collection to use"
    )
    parser.add_argument("--rounds", type=int, default=5, help="Number of rounds to run")
    parser.add_argument(
        "--clients", type=int, default=2, help="Number of clients to use per round"
    )
    return parser


if __name__ == "__main__":
    parser = init_argparse()
    args = parser.parse_args()
    logging.info(f"Starting server with following arguments: {args}")
    asyncio.run(
        run_multiple_rounds(
            population_name=args.population,
            collection_uri=args.collection,
            num_rounds=args.rounds,
            num_clients=args.clients,
            host=args.host,
            port=args.port,
        )
    )
    tff.program.TensorBoardReleaseManager(logdir)
