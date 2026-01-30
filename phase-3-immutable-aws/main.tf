terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {
  state = "available"
}


# -----------------------------
# Network: VPC + Public Subnet
# -----------------------------
resource "aws_vpc" "main" {
  cidr_block           = "10.30.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "phase3-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "phase3-igw" }
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.30.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = { Name = "phase3-public-1" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "phase3-public-rt" }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

# -----------------------------
# Security Group: HTTP + SSH
# -----------------------------
resource "aws_security_group" "web_ssh" {
  name        = "phase3-web-ssh"
  description = "Allow HTTP + SSH from my IP"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "phase3-web-ssh" }
}

# -----------------------------
# AMI: Ubuntu 22.04
# -----------------------------
data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# -----------------------------
# Launch Template + ASG (desired=1)
# -----------------------------
locals {
  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    apt-get update -y
    apt-get install -y nginx

    cat >/var/www/html/index.html <<HTML
    <!doctype html>
    <html>
    <head><meta charset="utf-8"><title>Immutable Demo</title></head>
    <body style="font-family: Arial, sans-serif;">
      <h1>Immutable Infrastructure Demo</h1>
      <p><b>VERSION=${var.app_version}</b></p>
      <p>hostname: $(hostname)</p>
      <p>boot_time: $(uptime -s)</p>
      <p>rendered_at: $(date -Is)</p>
    </body>
    </html>
    HTML

    systemctl enable nginx
    systemctl restart nginx
  EOF
}

resource "aws_launch_template" "web" {
  name_prefix            = "phase3-web-"
  image_id               = data.aws_ami.ubuntu_2204.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.web_ssh.id]
  user_data              = base64encode(local.user_data)

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "phase3-web"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web" {
  name                = "phase3-web-asg"
  min_size            = 1
  max_size            = 1
  desired_capacity    = 1
  vpc_zone_identifier = [aws_subnet.public_1.id]

  health_check_type         = "EC2"
  health_check_grace_period = 60

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "phase3-web-asg"
    propagate_at_launch = true
  }

  # Auto replace instance when Launch Template changes (e.g., VERSION update)
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 0
      instance_warmup        = 30
    }  
    }
}

# -----------------------------
# Outputs (simple)
# -----------------------------
output "asg_name" {
  value = aws_autoscaling_group.web.name
}

output "launch_template_id" {
  value = aws_launch_template.web.id
}
