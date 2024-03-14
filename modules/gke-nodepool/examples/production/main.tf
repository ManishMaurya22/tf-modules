# Example: Production GKE Node Pools
#
# This mirrors the setup used at Cleartrip (Flipkart Group) for
# production microservices on GCP.
#
# Usage:
#   terraform init
#   terraform plan -var-file="terraform.tfvars.example"
#   terraform apply

terraform {
  required_version = ">= 1.5.0"

  # In real usage, store state in GCS:
  # backend "gcs" {
  #   bucket = "my-terraform-state"
  #   prefix = "gke-nodepools/production"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ── Variables ─────────────────────────────────────────────────────────────────

variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "europe-west1"
}

variable "cluster_name" {
  type = string
}

# ── API service node pool (general workloads) ─────────────────────────────────

module "api_nodepool" {
  source = "git::https://github.com/manishmaurya/tf-modules//modules/gke-nodepool?ref=v1.0.0"

  project_id       = var.project_id
  cluster_name     = var.cluster_name
  cluster_location = var.region

  name        = "api-pool"
  environment = "production"
  team        = "platform"

  machine_type   = "e2-standard-8"
  min_node_count = 3
  max_node_count = 30
  use_spot       = false
  disk_size_gb   = 100

  node_labels = {
    "pool-type" = "general"
  }
}

# ── Payments node pool (isolated, PCI-scoped) ─────────────────────────────────

module "payments_nodepool" {
  source = "git::https://github.com/manishmaurya/tf-modules//modules/gke-nodepool?ref=v1.0.0"

  project_id       = var.project_id
  cluster_name     = var.cluster_name
  cluster_location = var.region

  name        = "payments-pool"
  environment = "production"
  team        = "payments"

  machine_type   = "e2-standard-8"
  min_node_count = 3    # never scale to zero — financial SLA
  max_node_count = 15
  use_spot       = false

  # Dedicated taint — only payments pods schedule here
  taints = [
    {
      key    = "dedicated"
      value  = "payments"
      effect = "NO_SCHEDULE"
    }
  ]

  node_labels = {
    "dedicated" = "payments"
    "pci-scope" = "true"
  }
}

# ── ML inference node pool (GPU) ──────────────────────────────────────────────

module "ml_inference_nodepool" {
  source = "git::https://github.com/manishmaurya/tf-modules//modules/gke-nodepool?ref=v1.0.0"

  project_id       = var.project_id
  cluster_name     = var.cluster_name
  cluster_location = var.region

  name        = "ml-inference-pool"
  environment = "production"
  team        = "ml-platform"

  machine_type   = "a2-highgpu-1g"
  min_node_count = 0    # scale to zero when no inference requests
  max_node_count = 8
  gpu_count      = 1
  gpu_type       = "nvidia-tesla-a100"
  use_spot       = false

  node_labels = {
    "pool-type"  = "gpu"
    "workload"   = "inference"
  }
}

# ── Outputs ───────────────────────────────────────────────────────────────────

output "api_nodepool_name" {
  value = module.api_nodepool.node_pool_name
}

output "payments_nodepool_name" {
  value = module.payments_nodepool.node_pool_name
}

output "ml_inference_nodepool_name" {
  value = module.ml_inference_nodepool.node_pool_name
}

output "applied_labels_api" {
  description = "Labels applied to API node pool — used in FinOps cost queries"
  value       = module.api_nodepool.applied_labels
}
