FROM quay.io/jupyter/tensorflow-notebook:tensorflow-2.15.0

# Default home where permissions and user are correctly positionned
WORKDIR "/home/jovyan"

COPY requirements.txt .
RUN pip install \
    --no-cache-dir \
    --requirement requirements.txt \
    && rm requirements.txt

COPY . .

EXPOSE 8888
