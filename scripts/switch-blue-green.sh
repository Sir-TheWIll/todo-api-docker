#!/bin/bash

# Switch Traffic Between Blue and Green Environments
# Usage: ./scripts/switch-blue-green.sh --to green

set -e

EC2_IP=$(cd terraform && terraform output -raw public_ip)
TARGET_ENV=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --to)
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
  echo "❌ Usage: $0 --to blue|green"
  exit 1
fi

if [[ ! "$TARGET_ENV" =~ ^(blue|green)$ ]]; then
  echo "❌ Target must be 'blue' or 'green'"
  exit 1
fi

echo "🔄 Switching traffic to $TARGET_ENV environment..."
echo ""

# SSH and switch
ssh -i ~/.ssh/todo-api-key ubuntu@$EC2_IP << ENDSSH
cd /home/ubuntu/todo-api-docker

# Update Nginx config
if [ "$TARGET_ENV" = "blue" ]; then
  sed -i 's/server green:3000;/server blue:3000;/' nginx-bluegreen.conf
  echo "✅ Switched to BLUE environment"
else
  sed -i 's/server blue:3000;/server green:3000;/' nginx-bluegreen.conf
  echo "✅ Switched to GREEN environment"
fi

# Reload Nginx
docker-compose -f docker-compose.blue-green.yml restart nginx

# Wait
sleep 3

# Health check
if curl -sf http://localhost/health | grep -q "OK"; then
  echo "✅ Health check passed!"
else
  echo "⚠️  Health check may need more time"
fi

echo ""
echo "📊 Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}"
ENDSSH

echo ""
echo "🌐 Application: https://$EC2_IP.sslip.io"
echo "✅ Traffic switched to $TARGET_ENV"
