#!/bin/bash

# Script to properly restart all services

set -e

echo "🔄 Restarting Services..."
echo ""

# Navigate to the project root
cd "$(dirname "$0")"

# Stop all services
echo "⏹️  Stopping all services..."
docker compose -f docker-services.yaml down
cd JWStand && docker compose down && cd ..
echo "✅ All services stopped"
echo ""

# Start base services first
echo "🚀 Starting base services (postgres, redis, nginx)..."
docker compose -f docker-services.yaml up -d
echo "✅ Base services started"
echo ""

# Wait a bit for database to be ready
echo "⏳ Waiting for database to be ready..."
sleep 5
echo "✅ Database ready"
echo ""

# Start application services
echo "🚀 Starting application services..."
cd JWStand
docker compose up -d --build
cd ..
echo "✅ Application services starting"
echo ""

# Wait for services to be healthy
echo "⏳ Waiting for services to be healthy..."
sleep 10

# Check web service health
echo "🏥 Checking web service health..."
cd JWStand
WEB_HEALTH=$(docker compose ps web --format json | grep -o '"Health":"[^"]*"' | cut -d'"' -f4 || echo "unknown")
echo "Web service health: $WEB_HEALTH"

# Show service status
echo ""
echo "📊 Service Status:"
docker compose ps
cd ..

echo ""
echo "✅ All services restarted!"
echo ""
echo "📝 Useful commands:"
echo "  - Check logs: cd JWStand && docker compose logs -f web"
echo "  - Check all services: docker ps"
echo "  - Restart just web: cd JWStand && docker compose restart web"

