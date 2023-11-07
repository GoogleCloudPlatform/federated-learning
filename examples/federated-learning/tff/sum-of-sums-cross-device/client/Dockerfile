FROM ubuntu:22.04 as builder

ENV CC=/usr/bin/x86_64-linux-gnu-gcc
ENV CXX=/usr/bin/x86_64-linux-gnu-g++
ENV VIRTUAL_ENV=venv
ENV REMOTE_BUILD_CACHE=fcp-build-cache

RUN apt update && apt full-upgrade -y && apt autoremove -y && apt install -y git gcc-10 python3 python3-dev python3-venv wget g++-10 clang lld libc++-dev libc++abi-dev
RUN ln -s /usr/bin/x86_64-linux-gnu-gcc-10 /usr/bin/x86_64-linux-gnu-gcc
RUN ln -s /usr/bin/x86_64-linux-gnu-g++-10 /usr/bin/x86_64-linux-gnu-g++
ADD https://github.com/bazelbuild/bazelisk/releases/download/v1.16.0/bazelisk-linux-amd64 /usr/local/bin/bazelisk
RUN chmod +x /usr/local/bin/bazelisk

WORKDIR /
RUN git clone https://github.com/google/federated-compute

WORKDIR /federated-compute
RUN python3 -m venv $VIRTUAL_ENV
RUN . $VIRTUAL_ENV/bin/activate && pip install --upgrade pip
RUN . $VIRTUAL_ENV/bin/activate && pip install -r requirements.txt
RUN . $VIRTUAL_ENV/bin/activate && bazelisk build //fcp/client:client_runner_main --config=clang --remote_cache=https://storage.googleapis.com/$REMOTE_BUILD_CACHE --google_default_credentials

FROM python:3.12.0-slim-bookworm as runner
RUN apt update && apt full-upgrade -y && apt autoremove -y && apt install -y libc++-dev

WORKDIR /

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY --from=builder /federated-compute/bazel-bin/fcp/client/client_runner_main .
ADD main.py .

CMD [ "python", "main.py" ]
