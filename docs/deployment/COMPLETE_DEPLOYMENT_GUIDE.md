# 🚀 Complete Deployment Guide

This comprehensive guide covers all necessary steps for deploying FinBotAiAgent with OAuth 2.0, external key management, and enterprise-grade security.

## 📋 **Prerequisites**

### **Required Infrastructure**
- **AWS EC2 Instance** (Ubuntu 20.04+)
- **PostgreSQL Database** (local or RDS)
- **Domain Name** (optional but recommended)
- **GitHub Repository** with Actions enabled
- **SSH Key Pair** for EC2 access

### **Required Tools**
- **Docker** and **Docker Compose**
- **Nginx** (for reverse proxy)
- **Git** (for code deployment)
- **OpenSSL** (for key generation)

## 🔧 **Step 1: Infrastructure Setup**

### **1.1 EC2 Instance Setup**

#### **Launch EC2 Instance**
```bash
# Choose Ubuntu 20.04+ AMI
# Instance type: t3.medium or larger
# Security group: Allow SSH (22), HTTP (80), HTTPS (443)
# Storage: 20GB+ EBS volume
```

#### **Connect to EC2**
```bash
ssh -i your-key.pem ubuntu@your-ec2-ip
```

#### **Update System**
```bash
sudo apt update && sudo apt upgrade -y
```

#### **Install Docker**
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version
```

#### **Install Nginx**
```bash
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx
```

### **1.2 PostgreSQL Setup**

#### **Install PostgreSQL**
```bash
sudo apt install -y postgresql postgresql-contrib
sudo systemctl enable postgresql
sudo systemctl start postgresql
```

#### **Configure PostgreSQL**
```bash
# Switch to postgres user
sudo -u postgres psql

# Create database and user
CREATE DATABASE finbotdb;
CREATE USER finbotuser WITH PASSWORD 'your-secure-password';
GRANT ALL PRIVILEGES ON DATABASE finbotdb TO finbotuser;
ALTER USER finbotuser CREATEDB;
\q
```

#### **Configure PostgreSQL for Docker**
```bash
# Edit postgresql.conf
sudo nano /etc/postgresql/*/main/postgresql.conf

# Add/modify these lines:
listen_addresses = '*'
port = 5432

# Edit pg_hba.conf
sudo nano /etc/postgresql/*/main/pg_hba.conf

# Add this line:
host    all             all             172.17.0.0/16           md5

# Restart PostgreSQL
sudo systemctl restart postgresql
```

## 🔐 **Step 2: Security Configuration**

### **2.1 Generate Secure Keys**

#### **Generate API Key**
```bash
# Generate 64-character hex API key
openssl rand -hex 32
# Example output: a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456
```

#### **Generate JWT Secret Key**
```bash
# Generate 128-character hex JWT secret
openssl rand -hex 64
# Example output: a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef123456
```

### **2.2 Configure GitHub Secrets**

#### **Go to GitHub Repository**
1. Navigate to your repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**

#### **Add Required Secrets**
```bash
# Database Configuration
DB_HOST=localhost
DB_USERNAME=finbotuser
DB_PASSWORD=your-secure-password
DB_NAME=finbotdb

# Security Configuration
API_KEY=a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456
JWT_SECRET_KEY=a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef123456

# EC2 Configuration
EC2_HOST=your-ec2-public-ip
EC2_USERNAME=ubuntu
EC2_SSH_KEY=your-ssh-private-key-content
EC2_PORT=22
```

#### **SSH Key Setup**
```bash
# Generate SSH key pair (if not exists)
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"

# Copy public key to EC2
ssh-copy-id -i ~/.ssh/id_rsa.pub ubuntu@your-ec2-ip

# Copy private key content for GitHub Secrets
cat ~/.ssh/id_rsa
```

## 🚀 **Step 3: Application Deployment**

### **3.1 Automated Deployment (Recommended)**

#### **Push to GitHub**
```bash
# Add all changes
git add .

# Commit changes
git commit -m "Deploy with OAuth 2.0 and external key management"

# Push to main branch (triggers deployment)
git push origin main
```

#### **Monitor Deployment**
1. Go to **GitHub** → **Actions** tab
2. Watch the deployment workflow
3. Check for any errors or warnings

### **3.2 Manual Deployment (Alternative)**

#### **Clone Repository on EC2**
```bash
# SSH to EC2
ssh -i your-key.pem ubuntu@your-ec2-ip

# Clone repository
git clone https://github.com/your-username/FinBotAiAgent.git
cd FinBotAiAgent

# Make deployment script executable
chmod +x deploy.sh

# Run deployment
./deploy.sh
```

## 🔧 **Step 4: Configuration Setup**

### **4.1 Environment Variables**

#### **Create .env File**
```bash
# On EC2, create .env file
nano .env
```

#### **Add Environment Variables**
```bash
# Database Configuration
DB_HOST=localhost
DB_USERNAME=finbotuser
DB_PASSWORD=your-secure-password
DB_NAME=finbotdb

# Security Configuration
API_KEY=a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456
JWT_SECRET_KEY=a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef123456

# Application Configuration
ASPNETCORE_ENVIRONMENT=Production
ASPNETCORE_URLS=http://+:8080
```

### **4.2 External Key Management Setup**

#### **Create Secrets Directory**
```bash
# Create secrets directory
sudo mkdir -p /app/secrets
sudo chown -R ubuntu:ubuntu /app/secrets
chmod 700 /app/secrets
```

#### **Set API Key File**
```bash
# Write API key to file
echo "a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456" > /app/secrets/api-key.txt
chmod 600 /app/secrets/api-key.txt
```

## 🌐 **Step 5: Nginx Configuration**

### **5.1 Create Nginx Configuration**

#### **Create Site Configuration**
```bash
sudo nano /etc/nginx/sites-available/finbotaiagent
```

#### **Add Nginx Configuration**
```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req zone=api burst=20 nodelay;

    # Proxy to application
    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://localhost:8080/health;
        access_log off;
    }
}
```

#### **Enable Site**
```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/finbotaiagent /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx
```

### **5.2 SSL Configuration (Optional)**

#### **Install Certbot**
```bash
sudo apt install -y certbot python3-certbot-nginx
```

#### **Get SSL Certificate**
```bash
# Get SSL certificate
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# Test auto-renewal
sudo certbot renew --dry-run
```

## 🐳 **Step 6: Docker Deployment**

### **6.1 Build and Run Application**

#### **Build Docker Image**
```bash
# Build image
docker build -t finbotaiagent:latest .
```

#### **Run with Docker Compose**
```bash
# Start services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f finbotaiagent
```

### **6.2 Verify Deployment**

#### **Check Application Health**
```bash
# Health check
curl http://localhost:8080/health

# Check from external
curl http://your-domain.com/health
```

#### **Test Authentication**
```bash
# Test API key authentication
curl -H "X-API-Key: a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456" \
  http://your-domain.com/api/expenses

# Test OAuth token generation
curl -X POST http://your-domain.com/oauth/token \
  -H "Content-Type: application/json" \
  -d '{
    "grant_type": "client_credentials",
    "client_id": "copilot-studio-client",
    "client_secret": "copilot-studio-secret-12345",
    "scope": "api.read api.write"
  }'
```

## 🔍 **Step 7: Verification and Testing**

### **7.1 Health Checks**

#### **Application Health**
```bash
# Check application status
curl -s http://your-domain.com/health | jq .

# Expected response:
{
  "status": "Healthy",
  "timestamp": "2025-01-18T10:30:00Z",
  "version": "1.0.0",
  "environment": "Production"
}
```

#### **Database Health**
```bash
# Check database connection
docker exec finbotaiagent psql -h localhost -U finbotuser -d finbotdb -c "SELECT 1;"
```

### **7.2 Security Testing**

#### **Test Rate Limiting**
```bash
# Test rate limiting
for i in {1..15}; do
  curl -H "X-API-Key: a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456" \
    http://your-domain.com/api/expenses
  echo "Request $i"
done
```

#### **Test CORS**
```bash
# Test CORS headers
curl -H "Origin: https://your-domain.com" \
  -H "Access-Control-Request-Method: GET" \
  -H "Access-Control-Request-Headers: X-API-Key" \
  -X OPTIONS http://your-domain.com/api/expenses
```

### **7.3 OAuth Testing**

#### **Test Token Generation**
```bash
# Generate OAuth token
TOKEN_RESPONSE=$(curl -s -X POST http://your-domain.com/oauth/token \
  -H "Content-Type: application/json" \
  -d '{
    "grant_type": "client_credentials",
    "client_id": "copilot-studio-client",
    "client_secret": "copilot-studio-secret-12345",
    "scope": "api.read api.write"
  }')

echo $TOKEN_RESPONSE | jq .
```

#### **Test JWT Authentication**
```bash
# Extract access token
ACCESS_TOKEN=$(echo $TOKEN_RESPONSE | jq -r '.access_token')

# Use JWT token
curl -H "Authorization: Bearer $ACCESS_TOKEN" \
  http://your-domain.com/api/expenses
```

## 📊 **Step 8: Monitoring and Maintenance**

### **8.1 Log Monitoring**

#### **View Application Logs**
```bash
# View real-time logs
docker-compose logs -f finbotaiagent

# View specific log levels
docker-compose logs finbotaiagent | grep ERROR
docker-compose logs finbotaiagent | grep WARN
```

#### **View Nginx Logs**
```bash
# Access logs
sudo tail -f /var/log/nginx/access.log

# Error logs
sudo tail -f /var/log/nginx/error.log
```

### **8.2 Performance Monitoring**

#### **Resource Usage**
```bash
# Check container resources
docker stats finbotaiagent

# Check system resources
htop
df -h
free -h
```

#### **Database Monitoring**
```bash
# Check database connections
sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity;"

# Check database size
sudo -u postgres psql -c "SELECT pg_size_pretty(pg_database_size('finbotdb'));"
```

### **8.3 Security Monitoring**

#### **Check Security Headers**
```bash
# Check security headers
curl -I http://your-domain.com/health
```

#### **Monitor Authentication**
```bash
# Check authentication logs
docker-compose logs finbotaiagent | grep -i "authentication\|oauth\|jwt"
```

## 🔄 **Step 9: Key Management**

### **9.1 API Key Rotation**

#### **Rotate API Key**
```bash
# Generate new API key
NEW_API_KEY=$(openssl rand -hex 32)
echo "New API key: $NEW_API_KEY"

# Update key file
echo "$NEW_API_KEY" > /app/secrets/api-key.txt
chmod 600 /app/secrets/api-key.txt

# Restart application
docker-compose restart finbotaiagent
```

#### **Update GitHub Secrets**
1. Go to GitHub → Settings → Secrets
2. Update `API_KEY` with new value
3. Update any client applications

### **9.2 JWT Secret Rotation**

#### **Rotate JWT Secret**
```bash
# Generate new JWT secret
NEW_JWT_SECRET=$(openssl rand -hex 64)
echo "New JWT secret: $NEW_JWT_SECRET"

# Update environment variable
export JWT_SECRET_KEY="$NEW_JWT_SECRET"

# Restart application
docker-compose restart finbotaiagent
```

## 🚨 **Step 10: Troubleshooting**

### **10.1 Common Issues**

#### **Application Won't Start**
```bash
# Check logs
docker-compose logs finbotaiagent

# Check configuration
docker-compose config

# Check environment variables
docker exec finbotaiagent env | grep -E "(API_KEY|JWT_SECRET|DB_)"
```

#### **Database Connection Issues**
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Test database connection
psql -h localhost -U finbotuser -d finbotdb

# Check database logs
sudo tail -f /var/log/postgresql/postgresql-*.log
```

#### **Authentication Issues**
```bash
# Check API key file
cat /app/secrets/api-key.txt

# Check OAuth configuration
docker exec finbotaiagent cat /app/appsettings.Production.json | grep -A 10 OAuth
```

### **10.2 Performance Issues**

#### **High Memory Usage**
```bash
# Check memory usage
docker stats finbotaiagent

# Restart if needed
docker-compose restart finbotaiagent
```

#### **Slow Response Times**
```bash
# Check nginx logs
sudo tail -f /var/log/nginx/access.log

# Check application logs
docker-compose logs finbotaiagent | grep -i "slow\|timeout"
```

## 📈 **Step 11: Scaling and Optimization**

### **11.1 Horizontal Scaling**

#### **Load Balancer Setup**
```bash
# Install HAProxy (optional)
sudo apt install -y haproxy

# Configure load balancer
sudo nano /etc/haproxy/haproxy.cfg
```

#### **Multiple Instances**
```bash
# Scale application
docker-compose up -d --scale finbotaiagent=3
```

### **11.2 Database Optimization**

#### **Connection Pooling**
```bash
# Check connection pool settings
docker exec finbotaiagent cat /app/appsettings.Production.json | grep -i connection
```

#### **Database Indexing**
```sql
-- Connect to database
psql -h localhost -U finbotuser -d finbotdb

-- Create indexes
CREATE INDEX idx_expenses_employee_id ON expenses(employee_id);
CREATE INDEX idx_expenses_date ON expenses(date);
```

## 🎯 **Step 12: Production Checklist**

### **✅ Pre-Deployment Checklist**
- [ ] EC2 instance configured
- [ ] PostgreSQL installed and configured
- [ ] Docker and Docker Compose installed
- [ ] Nginx configured
- [ ] GitHub Secrets configured
- [ ] SSL certificate obtained (if using domain)
- [ ] Security keys generated
- [ ] External key management configured

### **✅ Post-Deployment Checklist**
- [ ] Application health check passes
- [ ] Database connection working
- [ ] API key authentication working
- [ ] OAuth 2.0 token generation working
- [ ] JWT authentication working
- [ ] Rate limiting active
- [ ] CORS headers configured
- [ ] Security headers present
- [ ] Logging configured
- [ ] Monitoring set up

### **✅ Security Checklist**
- [ ] Non-root Docker user
- [ ] Secure file permissions
- [ ] HTTPS enabled (if using domain)
- [ ] Rate limiting configured
- [ ] CORS properly configured
- [ ] Security headers present
- [ ] API keys rotated regularly
- [ ] JWT secrets rotated regularly
- [ ] Database access restricted
- [ ] Firewall rules configured

## 🎉 **Deployment Complete!**

Your FinBotAiAgent is now deployed with:

- ✅ **OAuth 2.0 Client Credentials** authentication
- ✅ **API Key** authentication fallback
- ✅ **External key management** with rotation
- ✅ **Rate limiting** and security features
- ✅ **Copilot Studio** integration ready
- ✅ **Comprehensive monitoring** and logging
- ✅ **Production-ready** configuration

## 📞 **Support and Maintenance**

### **Regular Maintenance Tasks**
- **Weekly**: Check logs for errors
- **Monthly**: Rotate API keys and JWT secrets
- **Quarterly**: Update dependencies and security patches
- **Annually**: Review and update security policies

### **Monitoring and Alerts**
- Set up external monitoring for health endpoints
- Configure alerts for authentication failures
- Monitor resource usage and performance
- Track security events and anomalies

---

**Your FinBotAiAgent is now production-ready with enterprise-grade security!** 🚀🔐
