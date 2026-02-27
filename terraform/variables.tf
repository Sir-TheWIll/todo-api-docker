variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = "todo-api-key"
}

variable "public_key" {
  description = "SSH public key"
  type        = string
}

variable "active_environment" {
  description = "Active environment (blue or green)"
  type        = string
  default     = "blue"
  
  validation {
    condition     = var.active_environment == "blue" || var.active_environment == "green"
    error_message = "Must be 'blue' or 'green'."
  }
}

variable "certificate_arn" {
  description = "SSL certificate ARN for ALB"
  type        = string
  default     = ""
}
