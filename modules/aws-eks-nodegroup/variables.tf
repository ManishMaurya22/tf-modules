# variables.tf

variable "cluster_name" {
  description = "Name of the existing EKS cluster."
  type        = string
}

variable "name" {
  description = "Name of the node group."
  type        = string
}

variable "environment" {
  description = "Deployment environment: production | staging | dev"
  type        = string
  validation {
    condition     = contains(["production", "staging", "dev"], var.environment)
    error_message = "environment must be production, staging, or dev."
  }
}

variable "team" {
  description = "Owning team. Applied as mandatory tag for AWS Cost Explorer attribution."
  type        = string
}

variable "node_role_arn" {
  description = "IAM role ARN for EKS nodes. Must have AmazonEKSWorkerNodePolicy, AmazonEKS_CNI_Policy, AmazonEC2ContainerRegistryReadOnly."
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs for nodes. Nodes should never be in public subnets."
  type        = list(string)
}

variable "instance_types" {
  description = "EC2 instance types. For Spot, provide multiple types to increase availability."
  type        = list(string)
  default     = ["m5.xlarge", "m5a.xlarge", "m5d.xlarge"]
}

variable "desired_size" {
  type    = number
  default = 2
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 10
}

variable "disk_size_gb" {
  type    = number
  default = 100
}

variable "use_spot" {
  description = "Use Spot instances (capacity_type=SPOT). ~70% cheaper. Recommended for dev/staging."
  type        = bool
  default     = false
}

variable "node_labels" {
  type    = map(string)
  default = {}
}

variable "taints" {
  type = list(object({
    key    = string
    value  = string
    effect = string  # NO_SCHEDULE | PREFER_NO_SCHEDULE | NO_EXECUTE
  }))
  default = []
}

variable "additional_tags" {
  description = "Additional AWS tags. Mandatory tags (Environment, Team, ManagedBy, etc.) cannot be overridden."
  type        = map(string)
  default     = {}
}
