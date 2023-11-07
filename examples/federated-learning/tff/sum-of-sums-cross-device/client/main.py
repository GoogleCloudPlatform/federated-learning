import os
import time
import requests
import random


# gets the value of environment variables
url = os.environ["URL"]
population = os.environ["POPULATION"]
server = os.environ["SERVER"]
# testcert = os.environ["TESTCERT"]
exampledatapath = os.environ["EXAMPLEDATAPATH"]
numrounds = os.environ["NUMROUNDS"]
sleepsec = os.environ["SLEEPSEC"]
# dailyscheduler = int(os.environ["DAILYSCHEDULER"])

# gets a random data file from data service
response = requests.get(url)
open(exampledatapath, "wb").write(response.content)
print("data received")

# generates a random session id to annotate client logs
sessionid = random.randint(1, 300000)

cmd = "/client_runner_main"
os.popen(
    cmd
    + f" --population={population} --server={server} --test_cert=/etc/ssl/certs/client.pem --example_data_path={exampledatapath} --num_rounds={numrounds} --sleep_after_round_secs={sleepsec} --use_http_federated_compute_protocol --use_tflite_training"
).read()
# while True:
#     so = os.popen(
#         cmd
#         + f" --population={population} --server={server} --test_cert={testcert} --example_data_path={exampledatapath} --num_rounds={numrounds} --sleep_after_round_secs={sleepsec} --session={sessionid} --use_http_federated_compute_protocol --use_tflite_training"
#     ).read()
#     print(so)
#     time.sleep(dailyscheduler)
