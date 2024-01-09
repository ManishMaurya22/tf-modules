# Example: Dev/Staging with Spot VMs
#
# This is the configuration that saved $8M/year at Cleartrip
# by migrating all pre-prod workloads to Spot node pools.
# Scale-to-zero (min=0) further reduces cost when not in use.

provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" { type = string }
variable "region"     { type = string; default = "europe-west1" }
variable "cluster_name" { type = string }

# All pre-prod services share this Spot node pool
module "dev_nodepool" {
  source = "git::https://github.com/manishmaurya/tf-modules//modules/gke-nodepool?ref=v1.0.0"

  project_id       = var.project_id
  cluster_name     = var.cluster_name
  cluster_location = var.region

  name        = "dev-spot-pool"
  environment = "dev"
  team        = "platform"

  machine_type   = "e2-standard-4"
  min_node_count = 0      # scale to zero overnight — no idle spend
  max_node_count = 20
  use_spot       = true   # ~70% cheaper than on-demand
  disk_size_gb   = 50     # smaller disks for dev
}

module "staging_nodepool" {
  source = "git::https://github.com/manishmaurya/tf-modules//modules/gke-nodepool?ref=v1.0.0"

  project_id       = var.project_id
  cluster_name     = var.cluster_name
  cluster_location = var.region

  name        = "staging-spot-pool"
  environment = "staging"
  team        = "platform"

  machine_type   = "e2-standard-4"
  min_node_count = 1
  max_node_count = 10
  use_spot       = true
}

output "dev_nodepool" {
  value = module.dev_nodepool.node_pool_name
}
