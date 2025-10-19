#!/bin/bash

# Script to view logs from all services

cd "$(dirname "$0")/JWStand"

if [ -z "$1" ]; then
    echo "📋 Showing logs for all services..."
    docker compose logs -f
else
    echo "📋 Showing logs for $1..."
    docker compose logs -f "$1"
fi

