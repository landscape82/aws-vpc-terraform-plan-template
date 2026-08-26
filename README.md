# AWS Ops Terraform Template

[![Terraform CI](https://github.com/landscape82/aws-vpc-terraform-plan-template/actions/workflows/terraform-ci.yml/badge.svg)](https://github.com/landscape82/aws-vpc-terraform-plan-template/actions/workflows/terraform-ci.yml)

This is my personal template and learning project for AWS infrastructure operations with Terraform. It provisions a VPC with public/private subnets, an internet-facing Application Load Balancer in front of an Auto Scaling Group of EC2 instances in private subnets, an RDS PostgreSQL database, baseline CloudWatch resources, and access via AWS Systems Manager instead of direct SSH.

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
│   │       ├── terraform-ci.yml       # fmt/validate/tflint/checkov
│   │       ├── go-ci.yml              # gofmt/vet/test for both apps
│   │       ├── docker-ci.yml          # build validation for both images
│   │       ├── docs-ci.yml            # Markdown lint
│   │       └── docker-release.yml     # Docker Hub publishing on version tags
│   └── dependabot.yml        # keeps Action versions patched
├── app/                 # Go app (ip-reverser) with RDS integration
├── app-no-db/           # Go app variant without database connectivity
├── archive_logs/        # Example terraform debug output, kept for reference
├── assets/               # Screenshots used in docs
├── docs/
│   ├── CI.md              # CI workflow explained + external tooling guide
│   └── DEPLOYMENT.md      # Full deployment walkthrough
├── modules/
│   ├── cloudwatch/       # Log groups, metric filter, and alarm scaffolding
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
├── .env.example
├── main.tf
├── outputs.tf
├── terraform.tfvars.example
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

`terraform.tfvars.example` holds the non-secret example configuration: VPC CIDR blocks, instance sizing, RDS settings, Auto Scaling Group parameters, and the SSM parameter path used by the instances at boot. See [Security Notes](#security-notes) for the secret inputs that must stay local.

## Continuous Integration

Pull requests and relevant pushes to `main` run Terraform, Go, Docker, and Markdown checks. Docker images are built but not pushed during validation. See [`docs/CI.md`](./docs/CI.md) for the checks, local helper scripts, and Docker Hub release process.

## Release Automation

Push a semantic version tag such as `v1.0.0` to build and publish both application images to Docker Hub. Configure the repository secrets `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` first; release tags and commit-SHA tags are documented in [`docs/CI.md`](./docs/CI.md#docker-hub-releases).

## Security Notes

- Do not commit `terraform.tfvars`, `.env`, or any other file containing real secrets. This repo now tracks examples only.
- `database_password` is intended to be provided at apply time as a sensitive Terraform input, while EC2 instances read the runtime password from SSM Parameter Store via `database_password_ssm_parameter_name`.
- Instance access is designed around AWS SSM Session Manager rather than direct SSH, so no SSH key distribution or bastion host is required for normal operation.

## Known Limitations

- The CloudWatch module currently provisions log groups, a metric filter, and an alarm, but the EC2 bootstrap does not yet configure the CloudWatch agent to ship application logs into that group.
- The Terraform stack still launches a simple demo container by default; the `ip-reverser` app is exercised separately through the local workflow described in [app/README.md](./app/README.md).

## App Deployment Notes

- The `ip-reverser` app now defaults to port `8080`, includes a container health check, and runs as a non-root user in Docker.
- Local container validation uses `docker compose` with `.env.example` as the template for local configuration.

## Roadmap

- Dedicated Secrets Manager module instead of relying on a manually created SSM parameter plus Terraform-provided RDS password input

## License

Apache License 2.0 — see [LICENSE](./LICENSE).
