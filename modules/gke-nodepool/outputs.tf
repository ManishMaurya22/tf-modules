# ── Node pool identity ────────────────────────────────────────────────────────

output "node_pool_name" {
  description = "Name of the created node pool."
  value       = google_container_node_pool.this.name
}

output "node_pool_id" {
  description = "Full resource ID of the node pool."
  value       = google_container_node_pool.this.id
}

output "node_pool_self_link" {
  description = "Self-link URI of the node pool resource."
  value       = google_container_node_pool.this.self_link
}

# ── Autoscaling ───────────────────────────────────────────────────────────────

output "instance_group_urls" {
  description = <<-EOT
    URLs of the managed instance groups backing this node pool.
    Used by Prometheus node exporter for GCE instance service discovery,
    and by external autoscalers.
  EOT
  value = google_container_node_pool.this.managed_instance_group_urls
}

# ── Cost attribution ──────────────────────────────────────────────────────────

output "applied_labels" {
  description = "Final set of labels applied to all nodes (mandatory + caller-supplied)."
  value       = local.final_labels
}

# ── Useful for Kubernetes resource definitions ────────────────────────────────

output "node_selector" {
  description = <<-EOT
    Kubernetes nodeSelector map to target this node pool's nodes.
    Use in Pod specs and Deployment templates:
      nodeSelector: ${jsonencode(local.final_labels)}
  EOT
  value = {
    "environment" = var.environment
    "team"        = var.team
  }
}
