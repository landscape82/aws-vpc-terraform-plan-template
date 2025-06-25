# AMI data source
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM roles and policies definition
resource "aws_iam_role" "web_role" {
  name = "${var.environment}-web-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "web_profile" {
  name = "${var.environment}-web-profile"
  role = aws_iam_role.web_role.name
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.web_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Security Groups block for ALB
resource "aws_security_group" "web" {
  name_prefix = "${var.environment}-web-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-web-sg"
    Environment = var.environment
  }
}

resource "aws_security_group" "alb" {
  name_prefix = "${var.environment}-alb-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-alb-sg"
    Environment = var.environment
  }
}

# Security Groups block for Bastion host
resource "aws_security_group" "bastion" {
  name_prefix = "${var.environment}-bastion-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-bastion-sg"
    Environment = var.environment
  }
}

# Bastion to Web EC2s rule - allow ssh from bastion to EC2 (webservers)
resource "aws_security_group_rule" "allow_ssh_from_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.web.id
}

# SSH RSA Key 
resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = file("${path.module}/ssh/${var.key_name}.pub")
}

# Config for launching EC2 (template)

resource "aws_launch_template" "web" {
  name_prefix   = "${var.environment}-template"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y

              # install CloudWatch agent to stream logs
              yum install -y amazon-cloudwatch-agent

              # install Docker, enable so after restart it will be up & running
              yum install -y docker
              systemctl start docker
              systemctl enable docker

              # install AWS SSM consol - to use it for accessing EC2s (alternative to ssh key based login)
              yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
              systemctl enable amazon-ssm-agent
              systemctl start amazon-ssm-agent

              # Create environment file for database connection - mapped variable in tfvars
              cat > /etc/docker-environment <<EOL
              DB_HOST=${var.db_host}
              DB_PORT=5432
              DB_NAME=${var.db_name}
              DB_USER=${var.db_username}
              DB_PASSWORD=${var.db_password}
              EOL

              # Pull and run container with env file
              docker pull yeasy/simple-web
              docker run -d \
                --env-file /etc/docker-environment \
                -p 80:80 \
                yeasy/simple-web
              EOF
  )

  network_interfaces {
    associate_public_ip_address = true
    security_groups            = [aws_security_group.web.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.web_profile.name
  }
}

# Auto-Scaling Group configuration
resource "aws_autoscaling_group" "web" {
  name                = "${var.environment}-web-asg"
  desired_capacity    = var.asg_config.desired_capacity
  max_size           = var.asg_config.max_size
  min_size           = var.asg_config.min_size
  target_group_arns  = [aws_lb_target_group.web.arn]
  vpc_zone_identifier = var.subnet_ids
  
  health_check_type         = var.asg_config.health_check_type
  health_check_grace_period = var.asg_config.health_check_grace_period
  default_cooldown         = var.asg_config.default_cooldown
  protect_from_scale_in    = var.asg_config.protect_from_scale_in

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}

# Application Load Balancer configuration
resource "aws_lb" "web" {
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets           = var.subnet_ids
}

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_lb_target_group" "web" {
  name     = "${var.environment}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher            = "200"
    path               = "/"
    port               = "traffic-port"
    protocol           = "HTTP"
    timeout            = 5
    unhealthy_threshold = 2
  }
}

# Bastion host template
resource "aws_instance" "bastion" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"
  subnet_id     = var.public_subnet_ids[0]
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.bastion.id]

  tags = {
    Name        = "${var.environment}-bastion"
    Environment = var.environment
  }

  associate_public_ip_address = true
}

# CloudWatch IAM policy
resource "aws_iam_role_policy" "cloudwatch_policy" {
  name = "${var.environment}-cloudwatch-policy"
  role = aws_iam_role.web_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = ["arn:aws:logs:*:*:*"]
      }
    ]
  })
}