variable "distributed_tff_example_worker_1_address" {
  description = "Address of the first worker of the distributed TensorFlow Federated example. Set this when the worker is outside the coordinator mesh."
  type        = string
}

variable "distributed_tff_example_worker_2_address" {
  description = "Address of the second worker of the distributed TensorFlow Federated example. Set this when the worker is outside the coordinator mesh."
  type        = string
}

variable "project_id" {
  description = "The Google Cloud project ID"
  type        = string
}

variable "list_nodepool_sa_emails" {
  description = "List of the nodepool service accounts"
  type        = list(string)
}

variable "vpc_network_id" {
  description = "VPC network ID"
  type        = string
}

variable "vpc_network_name" {
  description = "VPC network name"
  type        = string
}
