output "node_pool_name" {
  description = "Name of the created node pool."
  value       = google_container_node_pool.this.name
}

output "node_pool_id" {
  description = "Full resource ID of the node pool."
  value       = google_container_node_pool.this.id
}

output "instance_group_urls" {
  description = "URLs of the managed instance groups backing this node pool."
  value       = google_container_node_pool.this.managed_instance_group_urls
}

output "applied_labels" {
  description = "Final set of labels applied to all nodes (mandatory + caller-supplied)."
  value       = local.final_labels
}

output "node_selector" {
  description = "Kubernetes nodeSelector map to target this node pool nodes."
  value = {
    "environment" = var.environment
    "team"        = var.team
  }
}
