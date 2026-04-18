# tf-modules

> Production-grade Terraform modules built from real-world SRE experience across
> Cleartrip (Flipkart Group), Intel Corporation, Morgan Stanley, and Cisco Systems.
>
> **Author:** Manish Maurya — SRE/DevOps Manager | AI Platform Engineer  
> **LinkedIn:** linkedin.com/in/manishmaurya

---

## Philosophy

These modules enforce infrastructure standards at the code level — not documentation, not
wikis, not hope. Every module has mandatory labels for cost attribution, security controls
baked in (not optional), and sensible defaults that teams can override where legitimate.

Built to support:
- **FinOps** — every resource is tagged for cost attribution out of the box
- **Compliance** — SOC-2, ISO 27001, PCI-DSS controls enforced at module level
- **Scale** — used to manage 60+ microservices across GCP and AWS

---

## Available Modules

| Module | Provider | Description |
|--------|----------|-------------|
| [gke-nodepool](./modules/gke-nodepool) | GCP | GKE node pool with autoscaling, Spot support, Workload Identity |
| [aws-eks-nodegroup](./modules/aws-eks-nodegroup) | AWS | EKS managed node group with launch templates and cost tagging |

---

## Usage

Pin to a specific version tag to avoid breaking changes:

```hcl
module "my_nodepool" {
  source = "git::https://github.com/ManishMaurya22/tf-modules//modules/gke-nodepool?ref=v1.0.0"
  # ...
}
```

---

## Versioning

This repo follows [Semantic Versioning](https://semver.org/).
All releases are tagged — see [CHANGELOG.md](./CHANGELOG.md).

---

## Requirements

| Tool | Version |
|------|---------|
| Terraform | >= 1.5.0 |
| GCP provider | >= 5.0 |
| AWS provider | >= 5.0 |

---

## License

MIT — free to use, attribution appreciated.
