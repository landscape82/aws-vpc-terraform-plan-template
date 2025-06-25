# CloudOps Home Task

This project provides an infrastructure as code (IaC) solution for deploying containerized applications on AWS using Terraform. Objective was to deploy EC2 instance with private and public subnets (module: `compute`). Install Docker, run it with `Simple-Web` container (webserver). All resources should should be allocated in Security Groups (module: `security`), enabled Application Load-Balancer with Auto-Scaling Group (module: `networking`). Access to EC2 instance(s) is possible via SSM. Also ssh-key as an example is pre-generated, terraform plan distributes it (of course its a very bad practice to include key pair or whole key chain, this is only an example).

Bonus added Application (called `ip-reverser`) written in GO, in 2 version - 1st version plain and 2nd version with option to connect with RDS database (for extended 2nd version included `docker-compose` manifest). Added plan for provisioning small PostgreSQL database, with enabled deletion protection by default (module: `database`), also NAT Gateway. RDS credentials are passed via `terraform.tfvars` (in future it could be good to extend whole setup with module dedicated for `Secret Manager`). Optional I've create CloudWatch setup installed, using agent, for providing log groups etc. (modules: `compute` and `cloudwatch`).

I've started working on enabling provisioning of Bastion host (module: `compute`), that would be jump-host to other provisioned EC2 servers in VPC. Tried put comment in some of the terraform blocks of code (in modules).

## Project Structure

```
    ├── ARCHITECTURE.md
    ├── QUICK-START.md
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
    ├── terraform-debug.log
    ├── terraform.tfvars
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
terraform workspace new Development (optional step in case when operating on many environment)
terraform workspace show
Development
```

```bash
terraform validate (optional step for debugging)
```

For more detail look into `QUICK-START.md`. Optional plan as it's modular can be executed for particular modules:

```bash
terraform plan
terraform apply
```

## Tfvars as main variables for configuring applied plan (module)

File contain configuration parameters for VPC, RDS, ASG etc. (description in file)

```bash
terrafrom.tfvars
```

## Example output from apply

```bash
$ terraform apply
module.networking.data.aws_availability_zones.available: Reading...
module.compute.data.aws_ami.amazon_linux_2: Reading...
module.networking.data.aws_availability_zones.available: Read complete after 1s [id=us-east-1]
module.compute.data.aws_ami.amazon_linux_2: Read complete after 2s [id=ami-09e4ba81d75ebeb6a]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

...

Outputs:

alb_dns_name = "development-alb-1206327056.us-east-1.elb.amazonaws.com"
database_endpoint = "development-database.cjnjfezzg8qi.us-east-1.rds.amazonaws.com:5432"
private_subnet_ids = [
  "subnet-005f8865b323c7658",
  "subnet-0c11df2e3a548bfc4",
]
public_subnet_ids = [
  "subnet-06b5d92651143089e",
  "subnet-06d51b3ba162809f1",
]
vpc_id = "vpc-0203d1d9413871251
```

## Access provisioned EC2 instance via SSM

Establish running instances with installed SSM agent:

```bash
$ aws ec2 describe-instances --filters "Name=tag:Environment,Values=development" --query 'Reservations[*].Instances[*].[InstanceId,PrivateIpAddress]' --output table
------------------------------------------
|            DescribeInstances           |
+----------------------+-----------------+
|  i-0ca537f741b584182 |  10.100.30.35   |
|  i-031e463535c022889 |  10.100.40.153  |
+----------------------+-----------------+
```

Describes one of server status:

```bash
$ aws ssm describe-instance-information --filters "Key=InstanceIds,Values=i-031e463535c022889"
{
    "InstanceInformationList": [
        {
            "InstanceId": "i-031e463535c022889",
            "PingStatus": "Online",
            "LastPingDateTime": "2024-11-29T12:30:32.978000+01:00",
            "AgentVersion": "3.3.987.0",
            "IsLatestVersion": false,
            "PlatformType": "Linux",
            "PlatformName": "Amazon Linux",
            "PlatformVersion": "2",
            "ResourceType": "EC2Instance",
            "IPAddress": "10.100.40.153",
            "ComputerName": "ip-10-100-40-153.ec2.internal",
            "SourceId": "i-031e463535c022889",
            "SourceType": "AWS::EC2::Instance"
        }
    ]
}
```

Login to server:

```bash
$ aws ssm start-session --target i-031e463535c022889

Starting session with SessionId: Jacek-b3quvups4hu45cazl5ftyzgc2e
sh-4.2$ 
```

Check Docker service, containers running and exit:

```bash
sh-4.2$ sudo docker ps
CONTAINER ID   IMAGE              COMMAND                  CREATED              STATUS              PORTS                               NAMES
ab85d8c52f59   yeasy/simple-web   "/bin/sh -c 'python …"   About a minute ago   Up About a minute   0.0.0.0:80->80/tcp, :::80->80/tcp   gracious_goldstine
```

Check ALB for accessing exposed application:

```bash
$ aws elbv2 describe-load-balancers --names development-alb --query 'LoadBalancers[0].DNSName' --output text
development-alb-1141512460.us-east-1.elb.amazonaws.com
```

## Debugging while applying plan

Run validate and export to log file for investigation

```bash
TF_LOG=DEBUG terraform validate > validate-debug.log
```

## Example log from applied plan

```bash
terraform-debug.log
validate-debug.log
```