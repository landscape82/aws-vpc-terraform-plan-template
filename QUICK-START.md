# CloudOps HomeTask

This project provides an infrastructure as code (IaC) solution for deploying containerized applications on AWS using Terraform. Objective was to deploy EC2 instance with private and public subnets (module: `compute`). Install Docker, run it with `Simple-Web` container (webserver). All resources should should be allocated in Security Groups (module: `security`), enabled Application Load-Balancer with Auto-Scaling Group (module: `networking`). Access to EC2 instance(s) is possible via SSM. 

Bonus added Application (called `ip-reverser`) written in GO, in 2 version - 1st version plain and 2nd version with option to connect with RDS database (for extended 2nd version included `docker-compose` manifest). Added plan for provisioning small PostgreSQL database (module: `database`), also NAT Gateway. RDS credentials are passed via `terraform.tfvars` (in future it could be good to extend whole setup with module dedicated for `Secret Manager`). Optional I've create CloudWatch setup installed, using agent, for providing log groups etc. (modules: `compute` and `cloudwatch`).

I've started working on enabling provisioning of Bastion host (module: `compute`), that would be jump-host to other provisioned EC2 servers in VPC. Tried put comment in some of the terraform blocks of code (in modules)

## Project Structure

```
├── ARCHITECTURE.md
├── README.md
├── app
│   ├── Dockerfile
│   ├── README.md
│   ├── go.mod
│   ├── go.sum
│   └── main.go
├── app-no-db
│   ├── Dockerfile
│   ├── go.mod
│   └── main.go
├── assets
│   ├── rds_created.png
│   ├── result_app_running_localhost_docker_desktop.png
│   └── vpc_created.png
├── docker-compose.yml
├── main.tf
├── modules
│   ├── cloudwatch
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── compute
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── ssh
│   │   │   ├── deployer-key
│   │   │   └── deployer-key.pub
│   │   └── variables.tf
│   ├── database
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── networking
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── security
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
├── outputs.tf
├── plan.binary
├── plan.json
├── terraform-debug.log
├── terraform.tfstate.d
│   └── Development
│       ├── terraform.tfstate
│       └── terraform.tfstate.backup
├── terraform.tfvars
├── tfplan
├── validate-debug.log
├── variables.tf
└── versions.tf
```

## Prerequisites

- AWS CLI configured
- Terraform installed
- Docker installed (optimal - Docker Desktop)
- Go installed (for application development)

## Quick Start

1. Clone the repository
2. Configure AWS credentials
3. Navigate to the directory
4. Initialize and apply Terraform configurations
5. In case of issue validate plan with debug

```bash
terraform init
terraform plan
terraform apply
```

# Architecture Overview

## Components

- VPC with Public and Private subnets
- Application Load Balancer
- Auto Scaling Group
- RDS Database
- EC2 Instances
- CloudWatch Monitoring

## Network Flow

1. Traffic enters through ALB
2. Requests are distributed to EC2 instances
3. Application connects to RDS in private subnet

# Quick Deployment Guide

Prerequisites

AWS CLI v2: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
Terraform v1.5+: https://developer.hashicorp.com/terraform/downloads
Docker: https://docs.docker.com/get-docker/
Go v1.21+: https://golang.org/dl/

Setup Steps

Configure AWS

```bash
aws configure
```

# Enter your AWS credentials when prompted

Build Go Application

```bash
cd app
go mod init ip-reverser
go mod tidy
docker build -t your-registry/ip-reverser:latest .
docker push your-registry/ip-reverser:latest
```


Initialize Terraform

```bash
terraform init
```


Create terraform.tfvars

```bash
cat > terraform.tfvars << EOF
aws_region = "us-west-2"
project_name = "ip-reverser"
environment = "development"
db_username = "admin"
db_password = "your-secure-password"
docker_image = "your-registry/ip-reverser:latest"
EOF
```

Deploy Infrastructure

```bash
terraform plan
terraform apply -auto-approve
```

Verify Deployment

```bash
# Get ALB DNS
terraform output alb_dns_name
```

# Test application

```bash
curl http://<alb_dns_name>
```

Common Tasks
Update Application

Build new version

```bash
cd app
docker build -t your-registry/ip-reverser:v2 .
docker push your-registry/ip-reverser:v2
```

# Update terraform.tfvars with new image
# Apply changes

```bash
terraform apply -auto-approve -var-file="terraform.tfvars"
```

Access Database

# Get RDS endpoint

```bash
terraform output rds_endpoint
```

# Connect using psql

```bash
psql -h <rds_endpoint> -U admin -d appdb
```

Cleanup

```bash
terraform destroy -auto-approve
```

Important URLs

AWS Console: https://console.aws.amazon.com
ECR Registry: https://console.aws.amazon.com/ecr/repositories
RDS Console: https://console.aws.amazon.com/rds/home#databases:
CloudWatch Logs: https://console.aws.amazon.com/cloudwatch/home#logsV2:log-groups

Troubleshooting

Check instance logs: AWS Console → EC2 → Instances → Select Instance → Actions → Monitor and troubleshoot → Get system log
Check RDS logs: AWS Console → RDS → Databases → Select DB → Logs & events
Check ALB logs: AWS Console → EC2 → Load Balancers → Select ALB → Monitoring

Security Notes

Keep terraform.tfvars secure and never commit to git
Rotate database passwords regularly
Monitor CloudWatch for suspicious activities
Review security group rules periodically