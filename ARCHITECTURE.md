# Architecture Overview

## Components

- AWS VPC with Public and Private Subnets

<img src="./assets/vpc_created.png" alt="Logo">

- Application Load Balancer (ALB)
- Auto-Scaling Group (ASG)
- AWS RDS Database (PostgreSQL)

<img src="./assets/rds_created.png" alt="Logo">

- AWS EC2 Instances
- AWS CloudWatch Monitoring

## Network Flow

1. Traffic enters through ALB
2. Requests are distributed to EC2 instances
3. Application connects to RDS in Private Subnet
