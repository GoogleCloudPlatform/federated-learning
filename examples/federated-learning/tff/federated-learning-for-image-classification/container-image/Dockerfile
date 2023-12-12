FROM quay.io/jupyter/tensorflow-notebook:tensorflow-2.15.0

WORKDIR "/home/jovyan"

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && rm requirements.txt

COPY . .

EXPOSE 8888
