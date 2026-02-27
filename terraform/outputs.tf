output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.todo_server.id
}

output "public_ip" {
  description = "EC2 Public IP Address"
  value       = aws_instance.todo_server.public_ip
}

output "public_dns" {
  description = "EC2 Public DNS"
  value       = aws_instance.todo_server.public_dns
}

output "sslip_url" {
  description = "SSLIP.io URL for HTTPS access"
  value       = "https://${aws_instance.todo_server.public_ip}.sslip.io"
}

output "ssh_command" {
  description = "SSH command to connect to instance"
  value       = "ssh -i ~/.ssh/todo-api-key ubuntu@${aws_instance.todo_server.public_ip}"
}
