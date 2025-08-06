#!/bin/bash

# FinBot AI Agent Monitoring Script
# This script monitors the health and status of the deployed application

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running"
    exit 1
fi

print_header "Container Status"
docker compose ps

print_header "Container Logs (Last 20 lines)"
docker compose logs --tail=20 finbotaiagent

print_header "Resource Usage"
echo "Memory Usage:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

print_header "Health Check"
if curl -f http://localhost:8080/weatherforecast > /dev/null 2>&1; then
    print_status "✅ Application is healthy"
    echo "Response from /weatherforecast:"
    curl -s http://localhost:8080/weatherforecast | head -c 200
    echo "..."
else
    print_error "❌ Application health check failed"
fi

print_header "Network Connections"
netstat -tlnp | grep :8080 || echo "No connections on port 8080"

print_header "Disk Usage"
df -h | grep -E "(Filesystem|/dev/)"

print_header "Memory Usage"
free -h 