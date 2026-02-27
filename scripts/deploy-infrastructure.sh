#!/bin/bash

set -e

echo "🚀 Deploying Todo API Infrastructure to AWS"
echo "============================================"

# Check prerequisites
command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform is required but not installed."; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI is required but not installed."; exit 1; }

# Navigate to terraform directory
cd "$(dirname "$0")/../terraform"

# Initialize Terraform
echo "📦 Initializing Terraform..."
terraform init

# Get SSH public key
if [ -f ~/.ssh/todo-api-key.pub ]; then
    PUBLIC_KEY=$(cat ~/.ssh/todo-api-key.pub)
    echo "✅ Found existing SSH key: ~/.ssh/todo-api-key"
else
    echo "⚠️  SSH key not found. Generating new key pair..."
    ssh-keygen -t ed25519 -f ~/.ssh/todo-api-key -N "" -C "todo-api-deployment"
    PUBLIC_KEY=$(cat ~/.ssh/todo-api-key.pub)
    echo "✅ New SSH key generated: ~/.ssh/todo-api-key"
fi

# Create terraform.tfvars
cat > terraform.tfvars << EOF
public_key = "$PUBLIC_KEY"
aws_region = "us-east-1"
instance_type = "t2.micro"
key_name = "todo-api-key"
github_username = "Sir-TheWILL"
EOF

echo "📝 Terraform variables configured"

# Plan
echo "📋 Creating Terraform plan..."
terraform plan -out=tfplan

# Apply
echo "🏗️  Applying Terraform configuration..."
terraform apply tfplan

# Get outputs
PUBLIC_IP=$(terraform output -raw public_ip)
SSLIP_URL=$(terraform output -raw sslip_url)

echo ""
echo "============================================"
echo "✅ Infrastructure Deployed Successfully!"
echo "============================================"
echo ""
echo "📍 Public IP: $PUBLIC_IP"
echo "🌐 Application URL: $SSLIP_URL"
echo "🔑 SSH Command: ssh -i ~/.ssh/todo-api-key ubuntu@$PUBLIC_IP"
echo ""
echo "⏳ Waiting 60 seconds for server initialization..."
sleep 60

echo ""
echo "🔧 Running Ansible playbook..."
cd ../ansible

# Update inventory with actual IP
cat > inventory.ini << EOF
[todo_servers]
todo_server ansible_host=$PUBLIC_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/todo-api-key

[todo_servers:vars]
ansible_python_interpreter=/usr/bin/python3
EOF

# Run Ansible
export GITHUB_USERNAME="Sir-TheWILL"
ansible-playbook -i inventory.ini playbook.yml

echo ""
echo "============================================"
echo "🎉 Deployment Complete!"
echo "============================================"
echo ""
echo "🌐 Live Application: $SSLIP_URL"
echo "📊 Health Check: http://$PUBLIC_IP:3000/health"
echo ""
