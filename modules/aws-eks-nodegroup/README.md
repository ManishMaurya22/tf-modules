# Module: aws-eks-nodegroup

Creates an AWS EKS managed node group with a launch template that enforces
security hardening and mandatory cost tagging.

Built from SRE experience at Morgan Stanley and Cisco managing EKS clusters
across US-East, EU-West, and AP-South regions.

---

## What this module enforces

| Control | Why |
|---------|-----|
| IMDSv2 only (http_tokens=required) | Prevents SSRF credential theft — CIS Benchmark |
| EBS volume encryption | Data at rest encryption — SOC-2 / ISO 27001 |
| No public IPs on nodes | Nodes in private subnets only |
| Mandatory cost tags (`Environment`, `Team`, `ManagedBy`) | AWS Cost Explorer attribution |
| Rolling updates (max_unavailable=1) | Zero surprise downtime |

---

## Usage

```hcl
module "api_nodegroup" {
  source = "git::https://github.com/ManishMaurya22/tf-modules//modules/aws-eks-nodegroup?ref=v1.0.0"

  cluster_name  = "prod-eks-eu-west-1"
  name          = "api-nodegroup"
  environment   = "production"
  team          = "platform"
  node_role_arn = aws_iam_role.eks_node.arn
  subnet_ids    = ["subnet-abc123", "subnet-def456"]

  instance_types = ["m5.xlarge"]
  min_size       = 2
  desired_size   = 4
  max_size       = 20
  use_spot       = false
}

# Dev with Spot instances
module "api_nodegroup_dev" {
  source = "git::https://github.com/ManishMaurya22/tf-modules//modules/aws-eks-nodegroup?ref=v1.0.0"

  cluster_name  = "dev-eks-eu-west-1"
  name          = "api-nodegroup-dev"
  environment   = "dev"
  team          = "platform"
  node_role_arn = aws_iam_role.eks_node.arn
  subnet_ids    = ["subnet-abc123", "subnet-def456"]

  # Multiple instance types increases Spot availability pool
  instance_types = ["m5.xlarge", "m5a.xlarge", "m5d.xlarge", "m4.xlarge"]
  min_size       = 1
  desired_size   = 2
  max_size       = 10
  use_spot       = true    # ~70% cheaper
}
```

---

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.5.0 |
| aws provider | >= 5.0, < 6.0 |
