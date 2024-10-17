module "distributed-tff-example-dns" {
  source  = "terraform-google-modules/cloud-dns/google"
  version = "5.3.0"

  description = "Private DNS zone for the distributed TensorFlow Federated example"
  domain      = "tensorflow-federated.example.com."
  name        = "distributed-tff-example"
  project_id  = var.project_id
  type        = "private"

  private_visibility_config_networks = [
    var.vpc_network_id
  ]

  recordsets = [
    {
      name    = "tff-worker-1"
      type    = "A"
      ttl     = 300
      records = [var.distributed_tff_example_worker_1_address]
    },
    {
      name    = "tff-worker-2"
      type    = "A"
      ttl     = 300
      records = [var.distributed_tff_example_worker_2_address]
    },
  ]
}

module "distributed_tff_example_firewall_rules" {
  source  = "terraform-google-modules/network/google//modules/firewall-rules"
  version = "9.3.0"

  project_id   = var.project_id
  network_name = var.vpc_network_name

  egress_rules = [
    {
      name                    = "allow-egress-to-workers-outside-mesh"
      description             = "Allow egress traffic to workers outside the mesh"
      destination_ranges      = ["${var.distributed_tff_example_worker_1_address}/32", "${var.distributed_tff_example_worker_2_address}/32"]
      priority                = 1000
      target_service_accounts = var.list_nodepool_sa_emails

      allow = [{
        protocol = "tcp"
        ports    = ["8000"]
      }]

      log_config = {
        metadata = "INCLUDE_ALL_METADATA"
      }
    }
  ]
}
