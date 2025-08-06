#!/bin/bash

# Immediate Fix Script for Database Connection Issues
# Run this on EC2 to fix the "Name or service not known" error

set -e

echo "🔧 Immediate Fix: Database Connection Issue"
echo "==========================================="

# Get EC2 internal IP
EC2_INTERNAL_IP=$(hostname -I | awk '{print $1}')
echo "📊 EC2 Internal IP: $EC2_INTERNAL_IP"

# 1. Configure PostgreSQL for Docker Access
echo ""
echo "🗄️ Configuring PostgreSQL for Docker Access..."

# Update postgresql.conf to listen on all interfaces
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/*/main/postgresql.conf

# Add Docker network ranges to pg_hba.conf (only if not already present)
if ! grep -q "172.16.0.0/12" /etc/postgresql/*/main/pg_hba.conf; then
    sudo tee -a /etc/postgresql/*/main/pg_hba.conf << 'EOF'

# Allow connections from Docker bridge networks
host    all             all             172.16.0.0/12           md5
host    all             all             192.168.0.0/16          md5
host    all             all             10.0.0.0/8              md5
EOF
fi

# Restart PostgreSQL
sudo systemctl restart postgresql
echo "✅ PostgreSQL configured and restarted"

# 2. Create Database User and Database
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

# 3. Update Environment File
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

# 4. Test Database Connectivity
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

# 5. Restart Application
echo ""
echo "🚀 Restarting Application..."

cd /home/ubuntu/finbotaiagent
sudo docker-compose down
sudo docker-compose up -d

# Wait for startup
echo "⏳ Waiting for application to start..."
sleep 30

# 6. Final Verification
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