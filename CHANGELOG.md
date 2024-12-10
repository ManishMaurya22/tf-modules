# Changelog

All notable changes to this project will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.0.0] - 2025-04-18

### Added
- `gke-nodepool` module — GKE node pool with autoscaling, Spot VM support,
  Workload Identity, Shielded Nodes, mandatory cost labels
- `aws-eks-nodegroup` module — EKS managed node group with launch template,
  IMDSv2 enforcement, mandatory cost tags, Spot support
- GitHub Actions CI pipeline — `terraform fmt`, `validate`, `tflint` on PRs

---

## [Unreleased]

### Planned
- `gke-cluster` module — full GKE cluster with VPC-native networking
- `aws-rds` module — RDS with automated backups and parameter groups
- `observability-stack` module — Prometheus + Grafana on Kubernetes
- `llm-serving` module — vLLM deployment on GPU node pools
