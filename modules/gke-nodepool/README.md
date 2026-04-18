# Module: gke-nodepool

Creates a GKE node pool with production-grade defaults enforced at the module level.

Built from operational experience managing 60+ microservices on GCP at Cleartrip
(Flipkart Group) and Intel Tiber AI Cloud infrastructure.

---

## What this module enforces (non-negotiable)

| Control | Why |
|---------|-----|
| Workload Identity | No service account key files on nodes — SOC-2 / ISO 27001 |
| Shielded Nodes (Secure Boot + Integrity Monitoring) | Prevents boot-level attacks — ISO 27001 |
| Mandatory cost labels (`environment`, `team`, `managed_by`) | FinOps cost attribution — feeds GCP Billing → BigQuery |
| Rolling upgrades (max_unavailable=0) | Zero unexpected downtime during node upgrades |
| Legacy metadata API disabled | Security hardening |

---

## Usage

### Standard production node pool

```hcl
module "api_nodepool" {
  source = "git::https://github.com/ManishMaurya22/tf-modules//modules/gke-nodepool?ref=v1.0.0"

  project_id       = "my-gcp-project"
  cluster_name     = "prod-gke-europe"
  cluster_location = "europe-west1"

  name        = "api-pool"
  environment = "production"
  team        = "platform"

  machine_type   = "e2-standard-8"
  min_node_count = 2
  max_node_count = 20
  use_spot       = false
}
```

### Dev pool with Spot VMs (60–80% cost saving)

```hcl
module "api_nodepool_dev" {
  source = "git::https://github.com/ManishMaurya22/tf-modules//modules/gke-nodepool?ref=v1.0.0"

  project_id       = "my-gcp-project-dev"
  cluster_name     = "dev-gke-europe"
  cluster_location = "europe-west1"

  name        = "api-pool-dev"
  environment = "dev"
  team        = "platform"

  machine_type   = "e2-standard-4"
  min_node_count = 0      # scale to zero when idle
  max_node_count = 5
  use_spot       = true   # Spot VMs for dev — major cost saving
}
```

### GPU node pool for ML/AI workloads

```hcl
module "gpu_nodepool" {
  source = "git::https://github.com/ManishMaurya22/tf-modules//modules/gke-nodepool?ref=v1.0.0"

  project_id       = "my-gcp-project"
  cluster_name     = "prod-gke-europe"
  cluster_location = "europe-west1"

  name        = "gpu-pool"
  environment = "production"
  team        = "ml-platform"

  machine_type   = "a2-highgpu-1g"
  min_node_count = 0
  max_node_count = 8
  gpu_count      = 1
  gpu_type       = "nvidia-tesla-a100"

  # GPU taint added automatically — only GPU-requesting pods schedule here
}
```

### Dedicated node pool with custom taint

```hcl
module "fintech_nodepool" {
  source = "git::https://github.com/ManishMaurya22/tf-modules//modules/gke-nodepool?ref=v1.0.0"

  project_id       = "my-gcp-project"
  cluster_name     = "prod-gke-europe"
  cluster_location = "europe-west1"

  name        = "fintech-pool"
  environment = "production"
  team        = "payments"

  machine_type   = "e2-standard-8"
  min_node_count = 3
  max_node_count = 15

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
```

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `project_id` | GCP project ID | `string` | — | yes |
| `cluster_name` | GKE cluster name | `string` | — | yes |
| `cluster_location` | Cluster region or zone | `string` | — | yes |
| `name` | Node pool name | `string` | — | yes |
| `environment` | `production`, `staging`, or `dev` | `string` | — | yes |
| `team` | Owning team (for cost labels) | `string` | — | yes |
| `machine_type` | GCE machine type | `string` | `e2-standard-4` | no |
| `min_node_count` | Autoscaling minimum | `number` | `1` | no |
| `max_node_count` | Autoscaling maximum | `number` | `10` | no |
| `disk_size_gb` | Boot disk size (GB) | `number` | `100` | no |
| `disk_type` | `pd-ssd`, `pd-balanced`, `pd-standard` | `string` | `pd-ssd` | no |
| `use_spot` | Use Spot VMs | `bool` | `false` | no |
| `gpu_count` | GPUs per node (0 = CPU only) | `number` | `0` | no |
| `gpu_type` | GPU accelerator type | `string` | `nvidia-tesla-t4` | no |
| `node_labels` | Extra Kubernetes node labels | `map(string)` | `{}` | no |
| `taints` | Kubernetes taints | `list(object)` | `[]` | no |
| `node_service_account` | Dedicated node SA email | `string` | `null` | no |
| `sysctls` | Linux kernel parameters | `map(string)` | `{}` | no |

---

## Outputs

| Name | Description |
|------|-------------|
| `node_pool_name` | Node pool name |
| `node_pool_id` | Full resource ID |
| `node_pool_self_link` | Self-link URI |
| `instance_group_urls` | Managed instance group URLs (for Prometheus SD) |
| `applied_labels` | Final label set (mandatory + caller-supplied) |
| `node_selector` | Kubernetes nodeSelector map |

---

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.5.0 |
| google provider | >= 5.0, < 6.0 |

---

## Real-world impact

- Migrating all pre-prod pools to `use_spot = true` at Cleartrip saved **$8M/year** on GCP
- Mandatory `team` and `environment` labels enabled accurate FinOps dashboards in Looker Studio,
  feeding the cost attribution that drove a total of **$14M in annual savings**
- Module-enforced Workload Identity and Shielded Nodes allowed us to pass SOC-2 and
  ISO 27001 audits without per-team remediation work
