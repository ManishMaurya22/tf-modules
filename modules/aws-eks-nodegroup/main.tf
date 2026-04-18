/**
 * # aws-eks-nodegroup
 *
 * Creates an EKS managed node group with production-grade defaults.
 *
 * ## Features
 * - Launch template for full node config control
 * - IMDSv2 enforced (prevents SSRF-based credential theft — CVSS 9.8 fix)
 * - Spot instance support via capacity_type
 * - Mandatory cost tags on all resources
 * - EBS volume encryption enforced
 * - Node-level security hardening (no public IPs, IMDSv2 only)
 *
 * Built from Morgan Stanley and Cisco SRE experience managing
 * EKS clusters across AWS US-East, EU-West, and AP-South regions.
 */


locals {
  # Mandatory tags applied to every AWS resource.
  # These feed into AWS Cost Explorer and our FinOps dashboards.
  mandatory_tags = {
    Environment = var.environment
    Team        = var.team
    ManagedBy   = "terraform"
    Module      = "aws-eks-nodegroup"
    CostCenter  = var.team
    Cluster     = var.cluster_name
  }

  final_tags = merge(var.additional_tags, local.mandatory_tags)
}

# ── Launch template ───────────────────────────────────────────────────────────
# Using a launch template gives us full control over instance config:
# IMDSv2, EBS encryption, security hardening — things EKS doesn't
# enforce by default.

resource "aws_launch_template" "this" {
  name_prefix = "${var.cluster_name}-${var.name}-"
  description = "Launch template for EKS node group ${var.name}"

  # IMDSv2 enforcement — prevents SSRF attacks from stealing
  # EC2 instance credentials (CVE-2019-11254 class vulnerabilities).
  # Required for CIS Benchmark compliance and our Morgan Stanley security baseline.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"   # IMDSv2 only — no IMDSv1
    http_put_response_hop_limit = 2            # 2 needed for containers on the node
    instance_metadata_tags      = "enabled"
  }

  # Block device — encrypt root volume
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.disk_size_gb
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  # No public IPs on nodes — traffic goes through NAT gateway
  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true
  }

  # User data is managed by EKS — don't override it here
  # (the managed node group injects bootstrap script automatically)

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.final_tags, { Name = "${var.cluster_name}-${var.name}" })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = local.final_tags
  }

  tag_specifications {
    resource_type = "network-interface"
    tags          = local.final_tags
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = local.final_tags
}

# ── EKS managed node group ────────────────────────────────────────────────────

resource "aws_eks_node_group" "this" {
  cluster_name    = var.cluster_name
  node_group_name = var.name
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids

  # Spot or On-Demand
  capacity_type = var.use_spot ? "SPOT" : "ON_DEMAND"

  # Multiple instance types for Spot — increases availability pool
  instance_types = var.instance_types

  scaling_config {
    desired_size = var.desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }

  update_config {
    # Max 1 node unavailable during rolling update
    max_unavailable = 1
  }

  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }

  # Kubernetes labels applied to nodes
  labels = merge(var.node_labels, {
    "environment" = var.environment
    "team"        = var.team
  })

  # Kubernetes taints for dedicated node pools
  dynamic "taint" {
    for_each = var.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  tags = local.final_tags

  lifecycle {
    # Ignore autoscaler changes to desired_size at runtime
    ignore_changes = [scaling_config[0].desired_size]
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}
