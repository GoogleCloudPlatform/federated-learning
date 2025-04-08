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

module "task-builder" {
  source   = "./kubernetes"
  name     = "task-builder"
  replicas = 2
  hpa = {
    min_replicas = 2
    max_replicas = 5
  }
  ports = [{
    containerPort = 5000
    name          = "http"
    protocol      = "TCP"
  }]
  env = {
    FCP_OPTS = "--environment '${var.environment}'"
    # TASK_MANAGEMENT_SERVER_URL = kubernetes_service.odp_services["task-management"].spec[0].cluster_ip
    PYTHONUNBUFFERED = 1
  }
  java_opts            = "-XX:+UseG1GC -XX:MaxGCPauseMillis=100 -Xmx2g -Xms2g"
  service_account_name = var.task_builder_sa
  image                = var.task_builder_image
  environment          = var.environment
  namespace            = var.namespace
}
