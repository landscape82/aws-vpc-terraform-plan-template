# AWS Ops Terraform Template

[![Terraform CI](https://github.com/landscape82/aws-vpc-terraform-plan-template/actions/workflows/terraform-ci.yml/badge.svg)](https://github.com/landscape82/aws-vpc-terraform-plan-template/actions/workflows/terraform-ci.yml)

This is my personal template and learning project for AWS infrastructure operations with Terraform. It provisions a VPC with public/private subnets, an internet-facing Application Load Balancer in front of an Auto Scaling Group of EC2 instances in private subnets, an RDS PostgreSQL database, CloudWatch monitoring, and access via AWS Systems Manager instead of direct SSH.

It also includes a bonus Go application (`ip-reverser`) in two variants — a plain version and one that persists results to the provisioned RDS database — used to exercise the infrastructure end to end.

## Table of Contents

- [Architecture](#architecture)
- [Repository Structure](#repository-structure)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Continuous Integration](#continuous-integration)
- [Security Notes](#security-notes)
- [Roadmap](#roadmap)
- [License](#license)

## Architecture

Traffic enters through the ALB in the public subnets and is distributed to EC2 instances in the private subnets, which connect onward to RDS. See [`ARCHITECTURE.md`](./ARCHITECTURE.md) for the full diagram and component breakdown.

## Repository Structure

```
aws-vpc-terraform-plan-template/
├── .github/
│   ├── workflows/
│   │   └── terraform-ci.yml  # fmt/validate/tflint/checkov on every PR
│   └── dependabot.yml        # keeps Action versions patched
├── app/                 # Go app (ip-reverser) with RDS integration
├── app-no-db/           # Go app variant without database connectivity
├── archive_logs/        # Example terraform debug output, kept for reference
├── assets/               # Screenshots used in docs
├── docs/
│   ├── CI.md              # CI workflow explained + external tooling guide
│   └── DEPLOYMENT.md      # Full deployment walkthrough
├── modules/
│   ├── cloudwatch/       # Log groups + CloudWatch agent config
│   ├── compute/          # EC2 instances, Auto Scaling Group, ALB integration
│   ├── database/         # RDS PostgreSQL
│   ├── networking/       # VPC, subnets, ALB, NAT Gateway
│   └── security/         # Security groups
│                          # (each module follows main.tf / variables.tf / outputs.tf / versions.tf)
├── .tflint.hcl
├── ARCHITECTURE.md
├── LICENSE
├── README.md
├── docker-compose.yml
├── main.tf
├── outputs.tf
├── terraform.tfvars
├── validate-debug.log    # Example `terraform validate` output, kept for reference
├── variables.tf
└── versions.tf
```

## Prerequisites

- AWS CLI configured
- Terraform installed
- Docker installed (Docker Desktop recommended)
- Go installed (only needed if you're building the bonus app yourself)

## Quick Start

```bash
terraform init
terraform plan
terraform apply
```

For the full walkthrough — including accessing instances via SSM, running the bonus Go app, common operations, and troubleshooting — see [`docs/DEPLOYMENT.md`](./docs/DEPLOYMENT.md).

## Configuration

`terraform.tfvars` holds the main configuration: VPC CIDR blocks, instance sizing, RDS settings, and Auto Scaling Group parameters. It ships with a placeholder database password for template purposes — see [Security Notes](#security-notes).

## Continuous Integration

Every pull request against `main` runs `terraform fmt`, `terraform validate`, TFLint, and a Checkov security scan, with results posted to a combined report in the workflow run summary. See [`docs/CI.md`](./docs/CI.md) for what each check does, how to run them locally before pushing, and a list of external tools worth knowing for Terraform development beyond what's wired in here.

## Security Notes

- `terraform.tfvars` in this repo carries a placeholder password for template purposes only. Never commit real credentials; for actual deployments use a git-ignored `.tfvars` file or AWS Secrets Manager.
- Instance access is designed around AWS SSM Session Manager rather than direct SSH, so no SSH key distribution or bastion host is required for normal operation.

## Roadmap

- Dedicated Secrets Manager module instead of passing RDS credentials via `terraform.tfvars`

## License

Apache License 2.0 — see [LICENSE](./LICENSE).
