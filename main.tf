# AWS as main provider
provider "aws" {
  region = var.aws_region
}

# Reference to `networking` module
module "networking" {
  source = "./modules/networking"

  environment           = var.environment
  vpc_cidr              = var.vpc_cidr
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
}

# Reference to `security` module
module "security" {
  source = "./modules/security"

  environment                 = var.environment
  vpc_id                      = module.networking.vpc_id
  database_security_group_id  = module.database.db_security_group_id
}

# Reference to `compute` module
module "compute" {
  source = "./modules/compute"

  environment   = var.environment
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_ids    = module.networking.private_subnet_ids
  public_subnet_ids = module.networking.public_subnet_ids
  vpc_id        = module.networking.vpc_id
  asg_config    = var.asg_config
  
  db_host     = module.database.db_instance_endpoint
  db_port     = 5432
  db_name     = var.database_config.database_name
  db_username = var.database_config.username
  db_password = var.database_password 
}

# Reference to `database` module
module "database" {
  source = "./modules/database"

  environment       = var.environment
  vpc_id            = module.networking.vpc_id
  subnet_ids        = module.networking.private_subnet_ids
  instance_class    = var.database_config.instance_class
  allocated_storage = var.database_config.allocated_storage
  engine            = var.database_config.engine
  engine_version    = var.database_config.engine_version
  database_name     = var.database_config.database_name
  database_username = var.database_config.username
  database_password = var.database_password
  multi_az          = var.database_config.multi_az
  app_security_group_id = module.compute.app_security_group_id

  depends_on = [module.networking]
}

# Reference to `cloudwatch` module
module "cloudwatch" {
  source = "./modules/cloudwatch"

  environment       = var.environment
  retention_days    = var.log_retention_days
  application_name  = "web-app"
}
