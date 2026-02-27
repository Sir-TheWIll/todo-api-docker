#!/bin/bash

# Traffic Switching Script for Blue-Green Deployment
# Usage: ./scripts/switch-traffic.sh --to green

set -e

ALB_ARN=""
BLUE_TG_ARN=""
GREEN_TG_ARN=""
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

# Get ALB and Target Group ARNs from Terraform output
ALB_ARN=$(cd terraform && terraform output -raw alb_arn)
BLUE_TG_ARN=$(cd terraform && terraform output -raw blue_target_group_arn)
GREEN_TG_ARN=$(cd terraform && terraform output -raw green_target_group_arn)

# Determine target group
if [ "$TARGET_ENV" = "blue" ]; then
  TARGET_TG_ARN="$BLUE_TG_ARN"
  OTHER_TG_ARN="$GREEN_TG_ARN"
else
  TARGET_TG_ARN="$GREEN_TG_ARN"
  OTHER_TG_ARN="$BLUE_TG_ARN"
fi

# Update ALB listener to point to new target group
echo "📡 Updating ALB listener..."
aws elbv2 modify-listener \
  --listener-arn "$ALB_ARN" \
  --default-actions Type=forward,TargetGroupArn="$TARGET_TG_ARN"

echo "✅ Traffic switched to $TARGET_ENV environment"

# Health check
echo "🏥 Running health check..."
ALB_DNS=$(cd terraform && terraform output -raw alb_dns_name)
for i in {1..5}; do
  if curl -sf "https://$ALB_DNS/health" | grep -q "OK"; then
    echo "✅ Health check passed!"
    break
  fi
  echo "Attempt $i: Waiting for service..."
  sleep 5
done

echo ""
echo "🌐 Application URL: https://$ALB_DNS"
echo "📊 Current active environment: $TARGET_ENV"
