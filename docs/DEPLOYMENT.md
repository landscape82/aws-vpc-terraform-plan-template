# Deployment Guide

Full walkthrough for deploying and operating this template. See the main [README](../README.md) for prerequisites and a quick overview, and [`CI.md`](./CI.md) for the checks that run on every pull request.

## 1. Initialize and configure

```bash
terraform init
terraform workspace new Development   # optional, for managing multiple environments
terraform workspace show
```

Copy the example config and keep the real file local-only:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Create the runtime database password parameter for the EC2 instances:

```bash
aws ssm put-parameter \
  --name /development/ip-reverser/database_password \
  --type SecureString \
  --value 'replace-me-with-a-real-password' \
  --overwrite
```

Provide the RDS password to Terraform as a sensitive input instead of storing it in the repository:

```bash
export TF_VAR_database_password='replace-me-with-a-real-password'
```

## 2. Validate before applying

```bash
terraform validate
```

If you need to troubleshoot, capture debug output to a file:

```bash
TF_LOG=DEBUG terraform validate > validate-debug.log
```

Example debug output from this repo's own runs is committed at `validate-debug.log` and `archive_logs/terraform-debug.log` for reference — this is a learning template, so real output is left in place intentionally.

## 3. Plan and apply

```bash
terraform plan
terraform apply
```

Example output:

```
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
vpc_id = "vpc-0203d1d9413871251"
```

## 4. Access the deployed EC2 instances via SSM

No SSH keys or bastion host required — access is via AWS Systems Manager Session Manager.

Find running instances:

```bash
$ aws ec2 describe-instances --filters "Name=tag:Environment,Values=development" --query 'Reservations[*].Instances[*].[InstanceId,PrivateIpAddress]' --output table
------------------------------------------
|            DescribeInstances           |
+----------------------+-----------------+
|  i-0ca537f741b584182 |  10.100.30.35   |
|  i-031e463535c022889 |  10.100.40.153  |
+----------------------+-----------------+
```

Check instance/agent status:

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

Start a session:

```bash
$ aws ssm start-session --target i-031e463535c022889

Starting session with SessionId: Jacek-b3quvups4hu45cazl5ftyzgc2e
sh-4.2$
```

Check the running container:

```bash
sh-4.2$ sudo docker ps
CONTAINER ID   IMAGE              COMMAND                  CREATED              STATUS              PORTS                               NAMES
ab85d8c52f59   yeasy/simple-web   "/bin/sh -c 'python …"   About a minute ago   Up About a minute   0.0.0.0:80->80/tcp, :::80->80/tcp   gracious_goldstine
```

## 5. Access the application through the load balancer

```bash
$ aws elbv2 describe-load-balancers --names development-alb --query 'LoadBalancers[0].DNSName' --output text
development-alb-1141512460.us-east-1.elb.amazonaws.com
```

## 6. Run the bonus Go application (ip-reverser)

The infrastructure above runs a generic demo web container by default. The bonus `ip-reverser` app is meant to be run and exercised separately, either standalone or against the provisioned RDS database.

See [`app/README.md`](../app/README.md) for the full guide — running with plain Go, with Docker, or with `docker-compose.yml` against RDS. The `app-no-db` variant is a simpler version without database connectivity.

## 7. Common operations

**Update infrastructure after a config change:**

```bash
terraform apply
```

**Rotate database credentials:** update the SSM parameter value, update `TF_VAR_database_password`, and re-apply. In production, this should move to a dedicated secret-management flow rather than manual dual updates.

**Tear down:**

```bash
terraform destroy
```

## Troubleshooting

- EC2 instance logs: AWS Console → EC2 → Instances → select instance → Actions → Monitor and troubleshoot → Get system log
- RDS logs: AWS Console → RDS → Databases → select DB → Logs & events
- ALB health: AWS Console → EC2 → Load Balancers → select ALB → Monitoring
- Terraform debug logs: set `TF_LOG=DEBUG` before any command and redirect output to a file, as shown in step 2
