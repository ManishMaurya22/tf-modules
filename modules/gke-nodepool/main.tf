/**
 * # gke-nodepool
 *
 * Creates a GKE node pool attached to an existing cluster.
 *
 * ## Features
 * - Autoscaling (min/max node count)
 * - Spot VM support for cost savings (up to 80% cheaper for pre-prod)
 * - Workload Identity enforced — pods get GCP IAM roles, no key files needed
 * - Shielded Nodes enforced — Secure Boot + Integrity Monitoring (SOC-2/ISO 27001)
 * - Mandatory cost attribution labels applied to every resource
 * - Rolling upgrades with zero max_unavailable — no surprise downtime
 * - Optional GPU support for ML/AI workloads (NVIDIA drivers auto-installed)
 *
 * ## Usage
 *
 * ```hcl
 * module "api_nodepool" {
 *   source = "git::https://github.com/manishmaurya/tf-modules//modules/gke-nodepool?ref=v1.0.0"
 *
 *   project_id       = "my-project"
 *   cluster_name     = "prod-gke-cluster"
 *   cluster_location = "europe-west1"
 *   name             = "api-pool"
 *   environment      = "production"
 *   team             = "platform"
 *   machine_type     = "e2-standard-8"
 *   min_node_count   = 2
 *   max_node_count   = 20
 * }
 * ```
 */

# ── Local values ──────────────────────────────────────────────────────────────
locals {
  # Mandatory labels applied to every node pool and GCE instance.
  # These feed into GCP Billing Export → BigQuery → FinOps dashboards.
  # Labels cannot be overridden by callers — enforced by merge order.
  mandatory_labels = {
    environment  = var.environment
    team         = var.team
    managed_by   = "terraform"
    module       = "gke-nodepool"
    cost_center  = var.team
  }

  # Caller labels merged first so mandatory labels always win
  final_labels = merge(var.node_labels, local.mandatory_labels)

  # GPU node pools need a specific taint so only GPU workloads schedule here
  gpu_taint = var.gpu_count > 0 ? [{
    key    = "nvidia.com/gpu"
    value  = "present"
    effect = "NO_SCHEDULE"
  }] : []

  all_taints = concat(local.gpu_taint, var.taints)
}

# ── Node pool ─────────────────────────────────────────────────────────────────
resource "google_container_node_pool" "this" {
  name     = var.name
  project  = var.project_id
  cluster  = var.cluster_name
  location = var.cluster_location

  # Node count — initial_node_count only used at creation time
  initial_node_count = var.min_node_count

  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }

  # Rolling upgrade — max_unavailable=0 prevents simultaneous node drain.
  # This was critical during Cleartrip Big Billion Day — zero node churn
  # during peak traffic events.
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
    strategy        = "SURGE"
  }

  management {
    auto_repair  = true
    auto_upgrade = var.environment == "production" ? false : true
    # Production upgrades are done manually during change windows.
    # Non-prod can auto-upgrade to stay current.
  }

  node_config {
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    disk_type    = var.disk_type

    # Spot VMs — typically 60-80% cheaper than on-demand.
    # Recommended for dev/staging. We saved $8M/year at Cleartrip
    # by migrating all pre-prod to Spot.
    spot = var.use_spot

    # GPU accelerators — for ML/AI workloads on DGX-style node pools
    dynamic "guest_accelerator" {
      for_each = var.gpu_count > 0 ? [1] : []
      content {
        type  = var.gpu_type
        count = var.gpu_count
        gpu_driver_installation_config {
          gpu_driver_version = "DEFAULT"
        }
      }
    }

    # Workload Identity — pods authenticate to GCP services via IAM,
    # no service account JSON keys on disk. Mandatory for SOC-2 compliance.
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Shielded Nodes — Secure Boot prevents rootkit/bootkit attacks.
    # Integrity Monitoring detects runtime tampering.
    # Both required for ISO 27001 and our Morgan Stanley-era security baseline.
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Network policy enforcement needs these permissions
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    # Service account — use a dedicated SA per node pool, not the default.
    # Caller must create the SA separately and pass it in.
    service_account = var.node_service_account

    # Kubernetes node labels
    labels = local.final_labels

    # GCP resource labels (for billing export and cost attribution)
    resource_labels = local.final_labels

    # Kubernetes taints — used for dedicated node pools (GPU, ML, etc.)
    dynamic "taint" {
      for_each = local.all_taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }

    # Linux node config — set for performance-sensitive workloads
    dynamic "linux_node_config" {
      for_each = var.sysctls != {} ? [1] : []
      content {
        sysctls = var.sysctls
      }
    }

    metadata = {
      # Disable legacy metadata API (security hardening)
      "disable-legacy-endpoints" = "true"
    }
  }

  # Allow terraform to destroy and recreate node pools when config changes
  # that require replacement (e.g. machine type). Without this, you'd have
  # to manually taint the resource.
  lifecycle {
    create_before_destroy = true

    # Ignore autoscaler-driven node count changes — the autoscaler manages
    # this at runtime and we don't want Terraform to fight it.
    ignore_changes = [
      initial_node_count,
    ]
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}
