environment           = "development" # Name of environment or project
aws_region            = "us-east-1" # Site
vpc_cidr              = "10.100.0.0/16" # IPv4 CIDR
public_subnet_cidrs   = ["10.100.10.0/24", "10.100.20.0/24"]
private_subnet_cidrs  = ["10.100.30.0/24", "10.100.40.0/24"]
instance_type         = "t3.micro" # type of provisioned EC2 instance
key_name              = "deployer-key" # SSH RSA key name

database_config = {
  instance_class    = "db.t3.micro" # typo of RDS instance
  allocated_storage = 20
  engine           = "postgres" # type of RDS engine (postgres or aurora)
  engine_version   = "14" # desired version
  database_name    = "appdb" # DB name
  username         = "dbadmin" # DB main Admin
  multi_az         = false # AZ option - enable for better reliability
}

database_password = "YourSecurePasswordHere123!" # Password for DB

# Block for controlling Auto-Scaling Group (default 2 servers are provisioned)
asg_config = {
  min_size                  = 1
  max_size                  = 4
  desired_capacity          = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  default_cooldown          = 300
  protect_from_scale_in     = false
}

# Log rotation related to CloudWatch aggregation
log_retention_days = 30  # number of days