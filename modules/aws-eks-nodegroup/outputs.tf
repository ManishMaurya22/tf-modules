# outputs.tf

output "node_group_name" {
  value = aws_eks_node_group.this.node_group_name
}

output "node_group_arn" {
  value = aws_eks_node_group.this.arn
}

output "node_group_status" {
  value = aws_eks_node_group.this.status
}

output "launch_template_id" {
  value = aws_launch_template.this.id
}

output "applied_tags" {
  description = "Final AWS tags applied to all resources (mandatory + caller-supplied)."
  value       = local.final_tags
}

output "node_selector" {
  description = "Kubernetes nodeSelector to target this node group."
  value = {
    "environment" = var.environment
    "team"        = var.team
  }
}
