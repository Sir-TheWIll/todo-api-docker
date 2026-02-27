#!/bin/bash

# Deploy to Blue or Green Environment
# Usage: ./scripts/deploy-blue-green.sh --target green

set -e

EC2_IP=$(cd terraform && terraform output -raw public_ip)
TARGET_ENV=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --target)
      TARGET_ENV="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [ -z "$TARGET_ENV" ]; then
  echo "❌ Usage: $0 --target blue|green"
  exit 1
fi

echo "🚀 Deploying to $TARGET_ENV environment..."
echo ""

# SSH and deploy
ssh -i ~/.ssh/todo-api-key ubuntu@$EC2_IP << ENDSSH
cd /home/ubuntu/todo-api-docker

echo "1️⃣ Pulling latest code..."
git pull origin main

echo "2️⃣ Building $TARGET_ENV container..."
docker-compose -f docker-compose.blue-green.yml build $TARGET_ENV

echo "3️⃣ Restarting $TARGET_ENV container..."
docker-compose -f docker-compose.blue-green.yml up -d $TARGET_ENV

echo "4️⃣ Waiting for startup..."
sleep 10

echo "5️⃣ Health check..."
if [ "$TARGET_ENV" = "blue" ]; then
  PORT=8080
else
  PORT=8081
fi

if curl -sf http://localhost:$PORT/health | grep -q "OK"; then
  echo "✅ $TARGET_ENV health check passed!"
else
  echo "❌ $TARGET_ENV health check failed!"
  exit 1
fi

echo ""
echo "✅ Deployment to $TARGET_ENV complete!"
echo ""
echo "📊 Status:"
docker ps --format "table {{.Names}}\t{{.Status}}"
ENDSSH

echo ""
echo "🎯 Next step:"
echo "   Switch traffic: ./scripts/switch-blue-green.sh --to $TARGET_ENV"
