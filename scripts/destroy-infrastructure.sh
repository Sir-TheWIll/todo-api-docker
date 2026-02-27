#!/bin/bash

set -e

echo "⚠️  WARNING: This will destroy ALL infrastructure!"
echo "=================================================="
read -p "Are you sure? Type 'yes' to confirm: " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Aborted"
    exit 1
fi

cd "$(dirname "$0")/../terraform"

echo "🗑️  Destroying infrastructure..."
terraform destroy -auto-approve

echo ""
echo "✅ Infrastructure destroyed!"
