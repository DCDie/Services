#!/bin/bash

# Script to check status of all services

cd "$(dirname "$0")"

echo "📊 Base Services Status:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker compose -f docker-services.yaml ps
echo ""

echo "📊 Application Services Status:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd JWStand
docker compose ps
cd ..
echo ""

echo "🌐 Testing nginx connectivity..."
curl -s http://localhost/health > /dev/null && echo "✅ Nginx is responding" || echo "❌ Nginx is not responding"

echo ""
echo "🏥 Testing Django health endpoint..."
cd JWStand
CONTAINER_NAME=$(docker compose ps web -q)
if [ ! -z "$CONTAINER_NAME" ]; then
    docker exec $CONTAINER_NAME curl -sf http://localhost:8000/health/ > /dev/null && echo "✅ Django is healthy" || echo "❌ Django health check failed"
else
    echo "❌ Web container not found"
fi
cd ..

