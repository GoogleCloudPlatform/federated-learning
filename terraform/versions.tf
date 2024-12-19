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

terraform {

  provider_meta "google" {
    module_name = "cloud-solutions/federated-learning-v2.0.1" # x-release-please-version
  }

  required_version = ">=1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.69.1, < 6.14.2"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 4.69.1, < 6.14.2"
    }
    external = {
      source  = "hashicorp/external"
      version = ">=2.2.2, < 3.0.0"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.3.0, < 4.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.1.1, < 4.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0, ~> 2.10"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.1, <4.0.0"
    }
  }
}
