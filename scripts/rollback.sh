#!/bin/bash

# Instant Rollback Script for Blue-Green Deployment
# Usage: ./scripts/rollback.sh

set -e

echo "🚨 INITIATING ROLLBACK..."
echo ""

# Get current active environment (simplified - in production, check ALB config)
CURRENT_ENV="green"  # Default assumption

# Determine rollback target
if [ "$CURRENT_ENV" = "green" ]; then
  TARGET_ENV="blue"
else
  TARGET_ENV="green"
fi

echo "🔄 Rolling back from $CURRENT_ENV to $TARGET_ENV..."

# Switch traffic
./scripts/switch-traffic.sh --to "$TARGET_ENV"

echo ""
echo "✅ Rollback complete!"
echo "🌐 Application is now running: $TARGET_ENV environment"

# Optional: Notify team
echo ""
echo "📧 Consider notifying your team:"
echo "   Rollback executed at $(date)"
echo "   Reason: [Add reason here]"
echo "   Previous version: $CURRENT_ENV"
echo "   Current version: $TARGET_ENV"
