#!/bin/bash

# Network Verification Script for Bridge Networking
# This script verifies the Docker bridge network configuration

set -e

echo "🔍 Verifying Bridge Network Configuration..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running"
    exit 1
fi

# Check if the application container is running
if ! docker ps | grep -q finbotaiagent; then
    echo "❌ Application container is not running"
    exit 1
fi

# Get container network info
echo "📊 Container Network Information:"
docker inspect finbotaiagent --format='{{range .NetworkSettings.Networks}}{{.NetworkID}} {{.IPAddress}}{{end}}'

# Get bridge network info
echo "🌉 Bridge Network Information:"
docker network ls | grep finbot
docker network inspect finbotaiagent_finbot-network --format='{{.IPAM.Config}}'

# Test host connectivity from container
echo "🔗 Testing Host Connectivity:"
docker exec finbotaiagent wget --no-verbose --tries=1 --spider http://host.docker.internal:5432 || echo "⚠️ PostgreSQL not accessible via host.docker.internal"

# Test application health
echo "🏥 Testing Application Health:"
if curl -f http://localhost:8080/weatherforecast > /dev/null 2>&1; then
    echo "✅ Application is healthy"
else
    echo "❌ Application health check failed"
fi

# Test database connectivity (if PostgreSQL is running)
echo "🗄️ Testing Database Connectivity:"
if command -v psql > /dev/null 2>&1; then
    if psql -h localhost -U finbotuser -d finbotdb -c "SELECT 1;" > /dev/null 2>&1; then
        echo "✅ Database connection successful"
    else
        echo "❌ Database connection failed"
    fi
else
    echo "⚠️ psql not available, skipping database test"
fi

echo "✅ Network verification completed" 