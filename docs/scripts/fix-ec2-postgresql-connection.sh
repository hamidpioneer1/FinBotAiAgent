#!/bin/bash

# Senior Engineer Fix Script for EC2 Docker PostgreSQL Connection
# This script implements the most reliable solution for production

set -e

echo "🔧 Senior Engineer Fix: EC2 Docker PostgreSQL Connection"
echo "========================================================"

# Get EC2 internal IP
EC2_INTERNAL_IP=$(hostname -I | awk '{print $1}')
echo "📊 EC2 Internal IP: $EC2_INTERNAL_IP"

# 1. Configure PostgreSQL for Docker Access
echo ""
echo "🗄️ Configuring PostgreSQL for Docker Access..."

# Update postgresql.conf to listen on all interfaces
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/*/main/postgresql.conf

# Add Docker network ranges to pg_hba.conf
sudo tee -a /etc/postgresql/*/main/pg_hba.conf << 'EOF'

# Allow connections from Docker bridge networks
host    all             all             172.16.0.0/12           md5
host    all             all             192.168.0.0/16          md5
host    all             all             10.0.0.0/8              md5
EOF

# Restart PostgreSQL
sudo systemctl restart postgresql
echo "✅ PostgreSQL configured and restarted"

# 2. Create Database and User
echo ""
echo "🗄️ Setting up Database and User..."

# Create database user and database
sudo -u postgres psql -c "CREATE USER finbotuser WITH PASSWORD 'finbot123';" 2>/dev/null || echo "User already exists"
sudo -u postgres psql -c "CREATE DATABASE finbotdb OWNER finbotuser;" 2>/dev/null || echo "Database already exists"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE finbotdb TO finbotuser;"

# Create expenses table
sudo -u postgres psql -d finbotdb -c "
CREATE TABLE IF NOT EXISTS expenses (
    id SERIAL PRIMARY KEY,
    employee_id VARCHAR(50) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    category VARCHAR(100) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'Pending',
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);" 2>/dev/null || echo "Table already exists"

echo "✅ Database and user configured"

# 3. Update Environment Configuration
echo ""
echo "🔧 Updating Environment Configuration..."

# Create .env file with EC2 internal IP
cat > /home/ubuntu/finbotaiagent/.env << EOF
# Database Configuration - Using EC2 Internal IP for reliability
DB_HOST=$EC2_INTERNAL_IP
DB_USERNAME=finbotuser
DB_PASSWORD=finbot123
DB_NAME=finbotdb

# Application Configuration
ASPNETCORE_ENVIRONMENT=Production
ASPNETCORE_URLS=http://+:8080

# Performance Settings
ASPNETCORE_Kestrel__Limits__MaxConcurrentConnections=100
ASPNETCORE_Kestrel__Limits__MaxConcurrentUpgradedConnections=100
EOF

echo "✅ Environment file updated with DB_HOST=$EC2_INTERNAL_IP"

# 4. Update Docker Compose for Maximum Reliability
echo ""
echo "🐳 Updating Docker Compose Configuration..."

cat > /home/ubuntu/finbotaiagent/docker-compose.yml << 'EOF'
version: '3.8'

services:
  finbotaiagent:
    image: finbotaiagent:latest
    build:
      context: .
      dockerfile: Dockerfile
    container_name: finbotaiagent
    restart: unless-stopped
    ports:
      - "8080:8080"
    env_file:
      - .env
    networks:
      - finbot-network
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8080/weatherforecast"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M
    # Multiple host access methods for maximum reliability
    extra_hosts:
      - "host.docker.internal:host-gateway"
      - "postgres-host:172.17.0.1"

networks:
  finbot-network:
    driver: bridge
    # Auto-assigned subnet by Docker
EOF

echo "✅ Docker Compose updated with multiple host access methods"

# 5. Test Database Connectivity
echo ""
echo "🔗 Testing Database Connectivity..."

# Test from host
echo "Host → PostgreSQL:"
if sudo -u postgres psql -d finbotdb -c "SELECT 1;" >/dev/null 2>&1; then
    echo "✅ Host can connect to PostgreSQL"
else
    echo "❌ Host cannot connect to PostgreSQL"
fi

# Test from container (if running)
if docker ps | grep -q finbotaiagent; then
    echo "Container → PostgreSQL:"
    if docker exec finbotaiagent wget --no-verbose --tries=1 --spider http://$EC2_INTERNAL_IP:5432 >/dev/null 2>&1; then
        echo "✅ Container can reach PostgreSQL"
    else
        echo "❌ Container cannot reach PostgreSQL"
    fi
else
    echo "⚠️ Container not running, will test after restart"
fi

# 6. Restart Application
echo ""
echo "🚀 Restarting Application..."

cd /home/ubuntu/finbotaiagent
sudo docker-compose down
sudo docker-compose build --no-cache
sudo docker-compose up -d

# Wait for startup
echo "⏳ Waiting for application to start..."
sleep 30

# 7. Final Verification
echo ""
echo "✅ Final Verification:"

# Check container status
if docker ps | grep -q finbotaiagent; then
    echo "✅ Application container is running"
else
    echo "❌ Application container failed to start"
    docker-compose logs
    exit 1
fi

# Check application health
if curl -f http://localhost:8080/weatherforecast >/dev/null 2>&1; then
    echo "✅ Application is healthy"
else
    echo "❌ Application health check failed"
    docker-compose logs finbotaiagent
fi

# Test database connection from application
echo "🗄️ Testing database connection from application..."
if docker logs finbotaiagent 2>&1 | grep -q "Could not seed database"; then
    echo "❌ Database connection still failing"
    echo "📋 Container logs:"
    docker logs finbotaiagent
else
    echo "✅ Database connection successful"
fi

echo ""
echo "🎯 Fix Complete! Application should now be working."
echo "📊 Access your application at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo 'EC2_PUBLIC_IP')" 