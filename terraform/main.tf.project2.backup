# AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  required_version = ">= 1.0.0"
}

provider "aws" {
  region = var.aws_region
}

# Get latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
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

# Create VPC
resource "aws_vpc" "todo_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "todo-api-vpc"
    Project     = "todo-api-docker"
    Environment = "development"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "todo_igw" {
  vpc_id = aws_vpc.todo_vpc.id

  tags = {
    Name    = "todo-api-igw"
    Project = "todo-api-docker"
  }
}

# Create Public Subnet
resource "aws_subnet" "todo_subnet" {
  vpc_id                  = aws_vpc.todo_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name    = "todo-api-subnet"
    Project = "todo-api-docker"
  }
}

# Create Route Table
resource "aws_route_table" "todo_rt" {
  vpc_id = aws_vpc.todo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.todo_igw.id
  }

  tags = {
    Name    = "todo-api-rt"
    Project = "todo-api-docker"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "todo_rta" {
  subnet_id      = aws_subnet.todo_subnet.id
  route_table_id = aws_route_table.todo_rt.id
}

# Create Security Group
resource "aws_security_group" "todo_sg" {
  name        = "todo-api-security-group"
  description = "Security group for Todo API Docker application"
  vpc_id      = aws_vpc.todo_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Todo API access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name    = "todo-api-sg"
    Project = "todo-api-docker"
  }
}

# Create Key Pair
resource "aws_key_pair" "todo_key" {
  key_name   = var.key_name
  public_key = var.public_key

  tags = {
    Name    = "todo-api-key"
    Project = "todo-api-docker"
  }
}

# Create EC2 Instance
resource "aws_instance" "todo_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.todo_subnet.id
  vpc_security_group_ids = [aws_security_group.todo_sg.id]
  key_name               = aws_key_pair.todo_key.key_name

  root_block_device {
    volume_size = 20
    volume_type = "gp2"
    encrypted   = true

    tags = {
      Name = "todo-api-root-volume"
    }
  }

  # Simplified user_data - just install Docker and Git
  user_data = <<-EOF
              #!/bin/bash
              set -e
              
              # Update system
              apt-get update
              apt-get upgrade -y
              
              # Install Docker
              curl -fsSL https://get.docker.com -o get-docker.sh
              sh get-docker.sh
              
              # Add ubuntu user to docker group
              usermod -aG docker ubuntu
              
              # Install Docker Compose
              curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose
              
              # Install Git
              apt-get install -y git
              
              echo "✅ Base setup complete - Ansible will handle the rest!"
              EOF

  tags = {
    Name        = "todo-api-server"
    Project     = "todo-api-docker"
    Environment = "development"
  }
}
