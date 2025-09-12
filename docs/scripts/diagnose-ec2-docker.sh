#!/bin/bash

# Senior Engineer Diagnostic Script for EC2 Docker PostgreSQL Connection
# This script identifies and fixes database connectivity issues

set -e

echo "🔍 Senior Engineer Diagnostic: EC2 Docker PostgreSQL Connection"
echo "================================================================"

# 1. System Information
echo "📊 System Information:"
echo "OS: $(lsb_release -d | cut -f2)"
echo "Docker Version: $(docker --version)"
echo "EC2 Internal IP: $(hostname -I | awk '{print $1}')"
echo "EC2 Public IP: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo 'Not available')"

# 2. PostgreSQL Status
echo ""
echo "🗄️ PostgreSQL Status:"
if systemctl is-active --quiet postgresql; then
    echo "✅ PostgreSQL is running"
    echo "PostgreSQL Version: $(sudo -u postgres psql -c 'SELECT version();' | head -2 | tail -1)"
else
    echo "❌ PostgreSQL is not running"
fi

# 3. PostgreSQL Configuration
echo ""
echo "⚙️ PostgreSQL Configuration:"
echo "Listen Addresses: $(sudo -u postgres psql -c 'SHOW listen_addresses;' | tail -1)"
echo "Port: $(sudo -u postgres psql -c 'SHOW port;' | tail -1)"

# 4. Docker Network Information
echo ""
echo "🐳 Docker Network Information:"
if docker ps | grep -q finbotaiagent; then
    echo "✅ Application container is running"
    CONTAINER_IP=$(docker inspect finbotaiagent --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
    echo "Container IP: $CONTAINER_IP"
else
    echo "❌ Application container is not running"
fi

# 5. Network Connectivity Tests
echo ""
echo "🔗 Network Connectivity Tests:"

# Test from host to PostgreSQL
echo "Host → PostgreSQL:"
if nc -z localhost 5432 2>/dev/null; then
    echo "✅ Host can connect to PostgreSQL"
else
    echo "❌ Host cannot connect to PostgreSQL"
fi

# Test from container to host gateway
echo "Container → Host Gateway:"
if docker exec finbotaiagent ping -c 1 172.17.0.1 >/dev/null 2>&1; then
    echo "✅ Container can reach host gateway"
else
    echo "❌ Container cannot reach host gateway"
fi

# Test host.docker.internal resolution
echo "Container → host.docker.internal:"
if docker exec finbotaiagent ping -c 1 host.docker.internal >/dev/null 2>&1; then
    echo "✅ host.docker.internal resolves"
else
    echo "❌ host.docker.internal does not resolve"
fi

# 6. Environment Variables
echo ""
echo "🔧 Environment Variables:"
if [ -f /home/ubuntu/finbotaiagent/.env ]; then
    echo "✅ .env file exists"
    echo "DB_HOST: $(grep DB_HOST /home/ubuntu/finbotaiagent/.env | cut -d'=' -f2)"
else
    echo "❌ .env file not found"
fi

# 7. Docker Compose Configuration
echo ""
echo "📋 Docker Compose Configuration:"
if [ -f /home/ubuntu/finbotaiagent/docker-compose.yml ]; then
    echo "✅ docker-compose.yml exists"
    if grep -q "extra_hosts" /home/ubuntu/finbotaiagent/docker-compose.yml; then
        echo "✅ extra_hosts configured"
    else
        echo "❌ extra_hosts not configured"
    fi
else
    echo "❌ docker-compose.yml not found"
fi

echo ""
echo "🎯 Diagnostic Complete" 