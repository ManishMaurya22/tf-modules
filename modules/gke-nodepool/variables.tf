# ── Required variables ────────────────────────────────────────────────────────

variable "project_id" {
  description = "GCP project ID where the node pool will be created."
  type        = string
}

variable "cluster_name" {
  description = "Name of the existing GKE cluster to attach this node pool to."
  type        = string
}

variable "cluster_location" {
  description = "Region or zone of the GKE cluster (e.g. europe-west1 or europe-west1-b)."
  type        = string
}

variable "name" {
  description = "Name of the node pool. Must be unique within the cluster."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,38}[a-z0-9]$", var.name))
    error_message = "Node pool name must be lowercase alphanumeric with hyphens, 3-40 characters."
  }
}

variable "environment" {
  description = "Deployment environment. Controls auto-upgrade behaviour and is applied as a mandatory label."
  type        = string

  validation {
    condition     = contains(["production", "staging", "dev"], var.environment)
    error_message = "environment must be one of: production, staging, dev."
  }
}

variable "team" {
  description = "Owning team name. Applied as a mandatory label for cost attribution in billing exports."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,29}$", var.team))
    error_message = "team must be lowercase alphanumeric with hyphens, max 30 characters."
  }
}

# ── Node pool sizing ──────────────────────────────────────────────────────────

variable "machine_type" {
  description = "GCE machine type for nodes. See https://cloud.google.com/compute/docs/machine-types"
  type        = string
  default     = "e2-standard-4"
}

variable "min_node_count" {
  description = "Minimum number of nodes in the pool (autoscaling lower bound)."
  type        = number
  default     = 1

  validation {
    condition     = var.min_node_count >= 0
    error_message = "min_node_count must be >= 0. Use 0 to allow scale-to-zero."
  }
}

variable "max_node_count" {
  description = "Maximum number of nodes in the pool (autoscaling upper bound)."
  type        = number
  default     = 10

  validation {
    condition     = var.max_node_count >= 1
    error_message = "max_node_count must be >= 1."
  }
}

variable "disk_size_gb" {
  description = "Boot disk size per node in GB."
  type        = number
  default     = 100

  validation {
    condition     = var.disk_size_gb >= 50
    error_message = "disk_size_gb must be at least 50GB to avoid container image pull failures."
  }
}

variable "disk_type" {
  description = "Boot disk type. pd-ssd recommended for production workloads."
  type        = string
  default     = "pd-ssd"

  validation {
    condition     = contains(["pd-ssd", "pd-standard", "pd-balanced"], var.disk_type)
    error_message = "disk_type must be pd-ssd, pd-standard, or pd-balanced."
  }
}

# ── Cost optimisation ─────────────────────────────────────────────────────────

variable "use_spot" {
  description = <<-EOT
    Use Spot VMs for this node pool.
    Spot VMs are 60-80% cheaper but can be preempted with 30s notice.
    Recommended: true for dev/staging, false for production.
    At Cleartrip this change across all pre-prod pools saved $8M/year on GCP.
  EOT
  type        = bool
  default     = false
}

# ── GPU support ───────────────────────────────────────────────────────────────

variable "gpu_count" {
  description = "Number of GPUs per node. Set to 0 for CPU-only nodes."
  type        = number
  default     = 0
}

variable "gpu_type" {
  description = "GPU accelerator type. Only used when gpu_count > 0."
  type        = string
  default     = "nvidia-tesla-t4"
  # Common values: nvidia-tesla-t4, nvidia-a100-80gb, nvidia-h100-80gb
}

# ── Labels and taints ─────────────────────────────────────────────────────────

variable "node_labels" {
  description = <<-EOT
    Additional Kubernetes labels to apply to nodes.
    Mandatory labels (environment, team, managed_by, module, cost_center)
    are always applied and cannot be overridden.
  EOT
  type        = map(string)
  default     = {}
}

variable "taints" {
  description = <<-EOT
    Kubernetes taints for dedicated workloads. Use to prevent general workloads
    from scheduling on specialised node pools (e.g. GPU, high-memory, ML).
    GPU taints are added automatically when gpu_count > 0.
  EOT
  type = list(object({
    key    = string
    value  = string
    effect = string  # NO_SCHEDULE | PREFER_NO_SCHEDULE | NO_EXECUTE
  }))
  default = []
}

# ── Identity and security ─────────────────────────────────────────────────────

variable "node_service_account" {
  description = <<-EOT
    GCP service account email for nodes. Should be a dedicated SA with
    minimal permissions (not the Compute default SA).
    Create with: google_service_account resource and pass the email here.
  EOT
  type        = string
  default     = null
  # If null, GKE uses the default Compute Engine service account.
  # For production, always create a dedicated SA.
}

# ── Linux tuning ──────────────────────────────────────────────────────────────

variable "sysctls" {
  description = <<-EOT
    Linux kernel parameters to set on nodes.
    Useful for high-connection-count services or ML workloads.
    Example: { "net.core.somaxconn" = "65535" }
  EOT
  type        = map(string)
  default     = {}
}
