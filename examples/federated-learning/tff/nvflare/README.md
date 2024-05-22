# Nvflare with TensorFlow

This example uses Nvflare to train an image classifier using federated averaging and TensorFlow as the deep learning framework.

[NVIDIA FLARE](https://nvflare.readthedocs.io/en/main/index.html) (**NV**IDIA **F**ederated **L**earning **A**pplication **R**untime **E**nvironment)
is a domain-agnostic, open-source, extensible SDK that allows researchers and data scientists to adapt existing ML/DL workflows to a federated paradigm.
It enables platform developers to build a secure, privacy-preserving offering for a distributed multi-party collaboration.

[Here](https://nvflare.readthedocs.io/en/main/flare_overview.html#high-level-system-architecture) is a high level system architecture of Nvflare.

> **_NOTE:_** This example uses the [MNIST](http://yann.lecun.com/exdb/mnist/) handwritten digits dataset and will load its data within the trainer code.

This example builds on top of the infrastructure that the
[blueprint provides](../../../../README.md), and follows the best practices the
blueprint establishes.

## High-level diagram
The following diagram shows one server and two clients that are connected to the server through a secure gRPC link:

![alt_text](../../../../assets/nvflare.svg "Infrastructure overview")

As shown in the preceding diagram, the blueprint helps you to create and configure the following infrastructure components:
- A persistent volume to store the Nvflare workspace
- Two pods that are the clients that will be connected to the server in the nvidia-client1 and nvidia-client2 namespaces respectively
- One pod that is the the server that will aggregate all the results from the computation in the nvflare-infra namespace

## 1. Create custom image
For this demo to work, you have to create a custom image with TensorFlow and Nvflare installed. To create the image and push it on Artifact Registry, go to the `docker-image` and build the image:

```bash
cd docker-image
export REGION=$(gcloud config get compute/region)
export PROJET_ID=$(gcloud config get core/project)
export REPOSITORY=my-repository
gcloud builds submit --tag ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/nvflare-tensorflow:1.0.0
```

Once the image is built, modify the `kustomization.yaml` file to add the new name and new tag of the image.

## 2. Create persistent volume for Nvflare workspace
All the models generated will be stored in a Cloud storage bucket mounted by each pod. First, create a bucket:

```bash
gcloud storage buckets create gs://nvflare-storage
```

Add the following permissions to the Kubernetes Service Account:

```bash
gcloud storage buckets add-iam-policy-binding gs://nvflare-storage \
    --member "principal://iam.googleapis.com/projects/391818703174/locations/global/workloadIdentityPools/lgu-demos.svc.id.goog/subject/ns/default/sa/default" \
    --role "roles/storage.objectUser"
```

## 3. Create Nvflare folder structure
Now that the persistent volume is created, you can start creating the folder structure and upload it to GCS. First install nvflare on your workstation:

```bash
python3 -m pip install -r requirements.txt
```

Then, run the provisionning tool:

```bash
cd ${HOME}
nvflare provision
```

You have to choose the non-ha (non high-availability) choice, as ha (high-availability) is not yet supported on Kubernetes. It will create a `project.yml` file that you can customize for your needs. Then, re-run the provisionning tool:

```bash
cd ${HOME}
nvflare provision
cd ${HOME}/workspace/example_project/prod_00/
```

The different folders generated represent the infrastructure you will deploy on the reference architecture:
- `server1` is the server that will aggregate all the results from the computation
- `site-1` and `site-2` are the clients that will be connected to the server
- `admin@nvidia.com` is the administration client to start and list jobs

## 4. Clone the repository
You will need to clone the Nvflare repository that contains the job you will run on the reference architecture:

```bash
cd ${HOME}
git clone https://github.com/NVIDIA/NVFlare
```

In the newly create folder, there is an `examples` folder that contains lots of demo you can use to test Nvflare. The TensorFlow demo is in the `examples/hello-world/hello-tf2`. The job will need to be in a special folder inside the `admin@nvidia.com` called the `transfer` folder to be deployed on each client participating in the computation.
Copy this folder in the `transfer` folder of the `admin@nvidia.com` folder:

```bash
cd ${HOME}/workspace/example_project/prod_00/admin@nvidia.com/transfer
cp -R ${HOME}/NVFlare/examples/hello-world/hello-tf2 .
```

Now, copy the whole workspace folder in GCS. The pods will have access to the infrastructure to run jobs:

```bash
gsutil -m cp -r ${HOME}/workspace gs://nvflare-storage
```

## 5. Deploy the infrastructure
Everything is now setup to be able to submit the job. Deploy the infrastructure:

```bash
kubectl apply -k .
```

Both clients and servers rely on kustomize to be deployed. If you want to add more client, just copy/paste the `client1` folder, modify values accordingly and add the new folder in the `kustomization.yaml` file. Do the same with the `server1` folder. Then, redeploy the whole infrastructure:

```bash
kubectl apply -k .
```

You should end up with the following running pods:

```bash
NAME                               READY   STATUS    RESTARTS   AGE
nvflare-client1-57d5b45d84-bmv58   1/1     Running   0          16h
nvflare-client2-895b65d8f-p4fs9    1/1     Running   0          16h
nvflare-server1-66c44ddb47-dhtqz   1/1     Running   0          16h
```

## 6. Submit the job
Everything is now ready to submit and run the job. Go to the `admin@nvidia.com` folder and connect to the infrastructure. When prompted, the username is `admin@nvidia.com`:

```bash
cd ${HOME}/workspace/nvfl/workspace/example_project/prod_00/admin@nvidia.com/startup
./fl_admin.sh
```

You should be connected to the federated learning system:

```bash
User Name: admin@nvidia.com
Trying to obtain server address
Obtained server address: server1:8003
Trying to login, please wait ...
Logged into server at server1:8003 with SSID: ebc6125d-0a56-4688-9b08-355fe9e4d61a
Type ? to list commands; type "? cmdName" to show usage of a command.
>
```

When connected, you can list the jobs submitted to the cluster by using the `list_jobs` command. To start the TensorFlow job, just type the command `submit_job` with the name of the job you want to run, here `hello-tf2`:

```bash
> submit_job hello-tf2
Submitted job: c8973f05-8787-41c5-8568-ecc15c7683b2
Done [262650 usecs] 2024-05-23 09:47:04.543903
```

The job should be running now:

```bash
> list_jobs
-----------------------------------------------------------------------------------------------------------------------------
| JOB ID                               | NAME      | STATUS             | SUBMIT TIME                      | RUN DURATION   |
-----------------------------------------------------------------------------------------------------------------------------
| c8973f05-8787-41c5-8568-ecc15c7683b2 | hello-tf2 | RUNNING            | 2024-05-23T09:47:04.488652+00:00 | 0:00:11.978134 |
-----------------------------------------------------------------------------------------------------------------------------
Done [136046 usecs] 2024-05-23 09:47:17.630953
```

You can verify the job ran successfully with the `list_jobs` command:

```bash
> list_jobs
-----------------------------------------------------------------------------------------------------------------------------
| JOB ID                               | NAME      | STATUS             | SUBMIT TIME                      | RUN DURATION   |
-----------------------------------------------------------------------------------------------------------------------------
| c8973f05-8787-41c5-8568-ecc15c7683b2 | hello-tf2 | FINISHED:COMPLETED | 2024-05-23T09:47:04.488652+00:00 | 0:01:44.335456 |
-----------------------------------------------------------------------------------------------------------------------------
Done [56885 usecs] 2024-05-23 09:49:15.420097
```

Alternatively, you can also inspect the logs of both the server and the clients:

```bash
kubectl logs deploy/nvflare-client1

2024-05-23 09:47:05,450 - ClientEngine - INFO - Starting client app. rank: 0
2024-05-23 09:47:05,583 - ProcessExecutor - INFO - Worker child process ID: 128
2024-05-23 09:47:05,589 - ProcessExecutor - INFO - run (c8973f05-8787-41c5-8568-ecc15c7683b2): waiting for child worker process to finish.
...
2024-05-23 09:47:30,727 - Communicator - INFO - Received from example_project server. getTask: train size: 408.5KB (408512 Bytes) time: 0.100075 seconds
2024-05-23 09:47:30,728 - FederatedClient - INFO - pull_task completed. Task name:train Status:True
2024-05-23 09:47:30,728 - ClientRunner - INFO - [identity=site-1, run=c8973f05-8787-41c5-8568-ecc15c7683b2, peer=example_project, peer_run=c8973f05-8787-41c5-8568-ecc15c7683b2]: got task assignment: name=train, id=eec461ea-c475-4c39-a52a-db666c51680e
2024-05-23 09:47:30,729 - ClientRunner - INFO - [identity=site-1, run=c8973f05-8787-41c5-8568-ecc15c7683b2, peer=example_project, peer_run=c8973f05-8787-41c5-8568-ecc15c7683b2, task_name=train, task_id=eec461ea-c475-4c39-a52a-db666c51680e]: invoking task executor SimpleTrainer
Epoch 1/2
938/938 [==============================] - 12s 12ms/step - loss: 0.3942 - accuracy: 0.8868 - val_loss: 0.2465 - val_accuracy: 0.9282
Epoch 2/2
938/938 [==============================] - 8s 8ms/step - loss: 0.1873 - accuracy: 0.9459 - val_loss: 0.1844 - val_accuracy: 0.9418
...
2024-05-23 09:48:42,128 - ClientRunner - INFO - [identity=site-1, run=c8973f05-8787-41c5-8568-ecc15c7683b2, peer=example_project, peer_run=c8973f05-8787-41c5-8568-ecc15c7683b2, task_name=train, task_id=ee34fd97-84a0-4d03-b15e-941e9e44eba6]: task result sent to server
...
2024-05-23 09:48:44,144 - FederatedClient - INFO - Shutting down client run: site-1
2024-05-23 09:48:44,321 - ClientRunner - INFO - [identity=site-1, run=c8973f05-8787-41c5-8568-ecc15c7683b2]: Client is stopping ...
2024-05-23 09:48:44,331 - ReliableMessage - INFO - shutdown reliable message monitor
2024-05-23 09:48:45,832 - MPM - INFO - MPM: Good Bye!
2024-05-23 09:48:48,477 - ProcessExecutor - INFO - run (c8973f05-8787-41c5-8568-ecc15c7683b2): child worker process finished with RC 0
```
