#!/bin/bash

# Blue-Green Deployment Setup for Single EC2 Instance
# This script configures Docker-based Blue-Green on one server

set -e

echo "🚀 Setting up Docker-based Blue-Green Deployment..."
echo ""

# SSH into EC2
EC2_IP=$(cd terraform && terraform output -raw public_ip)

ssh -i ~/.ssh/todo-api-key ubuntu@$EC2_IP << 'ENDSSH'
cd /home/ubuntu/todo-api-docker

echo "1️⃣ Creating Blue-Green Docker Compose..."

# Create docker-compose.blue-green.yml
cat > docker-compose.blue-green.yml << 'COMPOSE'
version: '3.8'

services:
  # BLUE Environment
  blue:
    build: .
    container_name: todo-blue
    ports:
      - "8080:3000"
    environment:
      - PORT=3000
      - MONGODB_URI=mongodb://mongo:27017/todos
      - NODE_ENV=production
    depends_on:
      - mongo
    networks:
      - todo-network
    restart: unless-stopped
    labels:
      - "environment=blue"

  # GREEN Environment
  green:
    build: .
    container_name: todo-green
    ports:
      - "8081:3000"
    environment:
      - PORT=3000
      - MONGODB_URI=mongodb://mongo:27017/todos
      - NODE_ENV=production
    depends_on:
      - mongo
    networks:
      - todo-network
    restart: unless-stopped
    labels:
      - "environment=green"

  # MongoDB (Shared)
  mongo:
    image: mongo:7
    container_name: todo-mongo
    ports:
      - "27017:27017"
    volumes:
      - mongo-data:/data/db
    networks:
      - todo-network
    restart: unless-stopped

  # Nginx (Traffic Router)
  nginx:
    image: nginx:alpine
    container_name: todo-nginx-bluegreen
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx-bluegreen.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
    depends_on:
      - blue
      - green
    networks:
      - todo-network
    restart: unless-stopped

networks:
  todo-network:
    driver: bridge

volumes:
  mongo-data:
COMPOSE

echo "2️⃣ Creating Nginx config for Blue-Green..."

# Create nginx-bluegreen.conf (routes to BLUE by default)
cat > nginx-bluegreen.conf << 'NGINX'
events {
    worker_connections 1024;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    
    gzip on;
    gzip_types text/plain text/css application/json application/javascript;
    
    # Security headers
    server_tokens off;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Upstream for active environment (BLUE by default)
    upstream active_backend {
        server blue:3000;
    }
    
    # HTTP - Redirect to HTTPS
    server {
        listen 80;
        server_name _;
        return 301 https://$host$request_uri;
    }
    
    # HTTPS Server
    server {
        listen 443 ssl http2;
        server_name _;
        
        # SSL certificates (self-signed for now)
        ssl_certificate /etc/nginx/ssl/nginx.crt;
        ssl_certificate_key /etc/nginx/ssl/nginx.key;
        
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers on;
        
        # Frontend
        location / {
            proxy_pass http://active_backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
        # API
        location /api/ {
            proxy_pass http://active_backend;
        }
        
        # Health Check
        location /health {
            proxy_pass http://active_backend/health;
        }
    }
}
NGINX

echo "3️⃣ Stopping old containers..."
docker-compose down 2>/dev/null || true

echo "4️⃣ Building and starting Blue-Green setup..."
docker-compose -f docker-compose.blue-green.yml build
docker-compose -f docker-compose.blue-green.yml up -d

echo "5️⃣ Waiting for services..."
sleep 15

echo "6️⃣ Checking status..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "✅ Blue-Green setup complete!"
echo ""
echo "📊 Current Status:"
echo "   - BLUE container:  http://localhost:8080"
echo "   - GREEN container: http://localhost:8081"
echo "   - Active (via Nginx): http://localhost"
echo ""
echo "🔧 Switch traffic:"
echo "   ./scripts/switch-blue-green.sh --to green"
echo ""
ENDSSH

echo ""
echo "✅ Docker-based Blue-Green deployment configured!"
echo ""
echo "🌐 Access your app: https://$EC2_IP.sslip.io"
echo ""
echo "📝 Next steps:"
echo "   1. Deploy to inactive environment (GREEN)"
echo "   2. Test the deployment"
echo "   3. Switch traffic with: ./scripts/switch-blue-green.sh --to green"
