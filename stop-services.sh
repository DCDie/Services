#!/bin/bash

# Script to stop all services

set -e

echo "⏹️  Stopping all services..."
echo ""

cd "$(dirname "$0")"

# Stop application services
echo "Stopping application services..."
cd JWStand && docker compose down && cd ..
echo "✅ Application services stopped"
echo ""

# Stop base services
echo "Stopping base services..."
docker compose -f docker-services.yaml down
echo "✅ Base services stopped"
echo ""

echo "✅ All services stopped!"

