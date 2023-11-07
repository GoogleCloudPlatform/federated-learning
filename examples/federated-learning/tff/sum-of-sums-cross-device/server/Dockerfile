FROM ubuntu:22.04 as builder

ENV CC=/usr/bin/x86_64-linux-gnu-gcc
ENV CXX=/usr/bin/x86_64-linux-gnu-g++
ENV VIRTUAL_ENV=venv
ENV REMOTE_BUILD_CACHE=fcp-build-cache

VOLUME [ "/logs" ]

RUN apt-get update && apt-get full-upgrade -y && apt-get autoremove -y && apt-get install -y git gcc-10 python3 python3-dev python3-venv wget g++-10 clang lld libc++-dev libc++abi-dev
RUN ln -s /usr/bin/x86_64-linux-gnu-gcc-10 /usr/bin/x86_64-linux-gnu-gcc
RUN ln -s /usr/bin/x86_64-linux-gnu-g++-10 /usr/bin/x86_64-linux-gnu-g++
ADD https://github.com/bazelbuild/bazelisk/releases/download/v1.16.0/bazelisk-linux-amd64 /usr/local/bin/bazelisk
RUN chmod +x /usr/local/bin/bazelisk

WORKDIR /
RUN git clone https://github.com/google/federated-compute

WORKDIR /federated-compute

COPY main_sumofsums.py /federated-compute/fcp/demo/main.py
COPY BUILD /federated-compute/fcp/demo

RUN python3 -m venv $VIRTUAL_ENV
RUN . $VIRTUAL_ENV/bin/activate && pip install --no-cache-dir --upgrade pip
RUN . $VIRTUAL_ENV/bin/activate && pip install --no-cache-dir -r requirements.txt
RUN . $VIRTUAL_ENV/bin/activate && bazelisk build //fcp/demo:main --config=clang --remote_cache=https://storage.googleapis.com/$REMOTE_BUILD_CACHE --google_default_credentials

CMD [ "/federated-compute/bazel-bin/fcp/demo/main" ]
