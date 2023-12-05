FROM jupyter/tensorflow-notebook

WORKDIR "/home/jovyan"

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

EXPOSE 8888
