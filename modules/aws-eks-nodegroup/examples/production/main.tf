# Example: Production EKS Node Groups
# Based on Morgan Stanley and Cisco SRE setup

provider "aws" {
  region = var.region
}

variable "region"        { type = string; default = "eu-west-1" }
variable "cluster_name"  { type = string }
variable "node_role_arn" { type = string }
variable "subnet_ids"    { type = list(string) }

module "api_nodegroup" {
  source = "git::https://github.com/manishmaurya/tf-modules//modules/aws-eks-nodegroup?ref=v1.0.0"

  cluster_name   = var.cluster_name
  name           = "api-nodegroup"
  environment    = "production"
  team           = "platform"
  node_role_arn  = var.node_role_arn
  subnet_ids     = var.subnet_ids
  instance_types = ["m5.xlarge"]
  min_size       = 2
  desired_size   = 4
  max_size       = 20
  use_spot       = false
}

module "api_nodegroup_dev" {
  source = "git::https://github.com/manishmaurya/tf-modules//modules/aws-eks-nodegroup?ref=v1.0.0"

  cluster_name   = var.cluster_name
  name           = "api-nodegroup-dev"
  environment    = "dev"
  team           = "platform"
  node_role_arn  = var.node_role_arn
  subnet_ids     = var.subnet_ids
  instance_types = ["m5.xlarge", "m5a.xlarge", "m5d.xlarge", "m4.xlarge"]
  min_size       = 1
  desired_size   = 2
  max_size       = 10
  use_spot       = true
}
