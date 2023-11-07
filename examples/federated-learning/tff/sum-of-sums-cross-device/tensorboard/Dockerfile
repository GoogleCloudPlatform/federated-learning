FROM python:3.11.4-slim-bookworm as runner

ENV TB_NAME=changeme
ENV LOGDIR=changeme
ENV EXPERIMENT_NAME=changeme

WORKDIR /usr/src/app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

CMD [ "tb-gcp-uploader" ]
ENTRYPOINT [ "--tensorboard_resource_name", "$TB_NAME", "--logdir=$LOGDIR", "--experiment_name=$EXPERIMENT_NAME", "--one_shot=True" ]
