variable "environment_name" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ami_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "key_name" {
  type = string
}

variable "user_data" {
  type = string
}

resource "aws_instance" "todo_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_name
  
  user_data = var.user_data
  
  root_block_device {
    volume_size = 20
    volume_type = "gp2"
    encrypted   = true
  }

  tags = {
    Name        = "todo-api-${var.environment_name}"
    Environment = var.environment_name
    Project     = "todo-api-blue-green"
  }
}

output "instance_id" {
  value = aws_instance.todo_server.id
}

output "public_ip" {
  value = aws_instance.todo_server.public_ip
}

output "private_ip" {
  value = aws_instance.todo_server.private_ip
}
