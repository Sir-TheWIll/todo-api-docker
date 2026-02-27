# AWS Region
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

# Instance Type
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

# Key Pair Name
variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = "todo-api-key"
}

# Public Key (from your existing SSH key)
variable "public_key" {
  description = "SSH public key content"
  type        = string
}

# GitHub Username
variable "github_username" {
  description = "GitHub username for repository clone"
  type        = string
  default     = "Sir-TheWILL"
}
