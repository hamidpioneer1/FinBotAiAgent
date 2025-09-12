# Nginx Load Balancer Guide for FinBotAiAgent

**Professional load balancing setup for dual deployment with GitHub Actions and AWS CodePipeline**

## 🎯 Overview

This guide sets up nginx as a reverse proxy and load balancer to provide unified access to both your GitHub Actions (port 8080) and AWS CodePipeline (port 8081) deployments.

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   End Users     │    │   Nginx Load     │    │   Backend       │
│                 │───▶│   Balancer       │───▶│   Services      │
│                 │    │   (Port 80)      │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                ├── GitHub Actions (Port 8080)
                                └── CodePipeline (Port 8081)
```

## 🚀 Quick Start

### 1. Setup Nginx Load Balancer

```bash
# Make the manager script executable
chmod +x deployment/scripts/nginx-manager.sh

# Start all services
./deployment/scripts/nginx-manager.sh start

# Check status
./deployment/scripts/nginx-manager.sh status

# Test endpoints
./deployment/scripts/nginx-manager.sh test
```

### 2. Access Your Application

| Service | URL | Description |
|---------|-----|-------------|
| **Main Application** | `http://your-ec2-ip` | Load balanced (both services) |
| **GitHub Actions** | `http://your-ec2-ip:8080` | Direct access to GitHub Actions |
| **CodePipeline** | `http://your-ec2-ip:8081` | Direct access to CodePipeline |
| **Status Page** | `http://your-ec2-ip/status` | Service status and health |
| **Health Check** | `http://your-ec2-ip/health` | Health check endpoint |
| **API Docs** | `http://your-ec2-ip/swagger` | Swagger documentation |

## 🔧 Configuration

### Nginx Configuration Features

1. **Load Balancing**
   - Round-robin between both services
   - Health checks and failover
   - Least connections algorithm

2. **Security Headers**
   - X-Frame-Options
   - X-XSS-Protection
   - X-Content-Type-Options
   - Content Security Policy

3. **Performance**
   - Gzip compression
   - Static file caching
   - Connection keep-alive
   - Rate limiting

4. **Monitoring**
   - Health check endpoints
   - Status page
   - Access and error logs

### Docker Compose Services

```yaml
services:
  nginx:                    # Load balancer (port 80)
  finbotaiagent-github:     # GitHub Actions (port 8080)
  finbotaiagent-codepipeline: # CodePipeline (port 8081)
  postgres:                 # Database (port 5432)
```

## 📊 Load Balancing Strategy

### Current Configuration
- **Method**: Least connections
- **Health Checks**: Active monitoring
- **Failover**: Automatic failover to healthy service
- **Sticky Sessions**: Not configured (stateless)

### Load Distribution
```
Traffic → Nginx → {
  GitHub Actions (50%) ← Port 8080
  CodePipeline (50%)   ← Port 8081
}
```

## 🛠️ Management Commands

### Basic Operations

```bash
# Start all services
./deployment/scripts/nginx-manager.sh start

# Stop all services
./deployment/scripts/nginx-manager.sh stop

# Restart all services
./deployment/scripts/nginx-manager.sh restart

# Show status
./deployment/scripts/nginx-manager.sh status
```

### Monitoring and Debugging

```bash
# Test all endpoints
./deployment/scripts/nginx-manager.sh test

# Show logs
./deployment/scripts/nginx-manager.sh logs nginx
./deployment/scripts/nginx-manager.sh logs github
./deployment/scripts/nginx-manager.sh logs codepipeline

# Monitor in real-time
./deployment/scripts/nginx-manager.sh monitor
```

### Configuration Management

```bash
# Validate nginx config
./deployment/scripts/nginx-manager.sh validate

# Update nginx config
./deployment/scripts/nginx-manager.sh update
```

## 🔍 Monitoring and Health Checks

### Health Check Endpoints

| Endpoint | Purpose | Response |
|----------|---------|----------|
| `/health` | Application health | JSON health status |
| `/status` | Service status | JSON service info |
| `/weatherforecast` | API test | JSON data |

### Health Check Configuration

```nginx
# Health check for both services
location /health {
    proxy_pass http://health_check/weatherforecast;
    error_page 502 503 504 = @health_fallback;
}

# Fallback to other service
location @health_fallback {
    proxy_pass http://localhost:8081/weatherforecast;
}
```

## 🚨 Troubleshooting

### Common Issues

#### 1. Services Not Starting
```bash
# Check Docker status
docker ps -a

# Check logs
./deployment/scripts/nginx-manager.sh logs all

# Restart services
./deployment/scripts/nginx-manager.sh restart
```

#### 2. Load Balancer Not Working
```bash
# Validate nginx config
./deployment/scripts/nginx-manager.sh validate

# Check nginx logs
./deployment/scripts/nginx-manager.sh logs nginx

# Test individual services
curl http://localhost:8080/weatherforecast
curl http://localhost:8081/weatherforecast
```

#### 3. Database Connection Issues
```bash
# Check PostgreSQL logs
./deployment/scripts/nginx-manager.sh logs postgres

# Test database connection
docker exec -it finbotaiagent-postgres psql -U your_username -d your_database
```

### Debug Commands

```bash
# Check container status
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check nginx configuration
docker exec finbotaiagent-nginx nginx -t

# Check service connectivity
docker exec finbotaiagent-nginx wget -qO- http://localhost:8080/weatherforecast
docker exec finbotaiagent-nginx wget -qO- http://localhost:8081/weatherforecast
```

## 🔒 Security Considerations

### 1. Network Security
- Services communicate through Docker network
- External access only through nginx (port 80)
- Database not exposed externally

### 2. Rate Limiting
```nginx
# Rate limiting configuration
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req zone=api burst=20 nodelay;
```

### 3. Security Headers
```nginx
# Security headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header X-Content-Type-Options "nosniff" always;
```

## 📈 Performance Optimization

### 1. Caching
```nginx
# Static file caching
location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

### 2. Compression
```nginx
# Gzip compression
gzip on;
gzip_types text/plain text/css application/json application/javascript;
```

### 3. Connection Pooling
```nginx
# Upstream connection pooling
upstream finbotaiagent_backend {
    server localhost:8080;
    server localhost:8081;
    keepalive 32;
}
```

## 🔄 Deployment Workflow

### 1. GitHub Actions Deployment
1. Code pushed to main branch
2. GitHub Actions builds and deploys to port 8080
3. Nginx automatically includes new deployment
4. Health checks ensure service is ready

### 2. AWS CodePipeline Deployment
1. Code pushed to main branch
2. CodePipeline builds and deploys to port 8081
3. Nginx automatically includes new deployment
4. Health checks ensure service is ready

### 3. Load Balancer Updates
- Nginx automatically detects new deployments
- Health checks ensure only healthy services receive traffic
- Zero-downtime deployments

## 📊 Monitoring Dashboard

### Service Status
```bash
# Real-time monitoring
./deployment/scripts/nginx-manager.sh monitor
```

### Key Metrics
- Service availability
- Response times
- Error rates
- Traffic distribution

### Log Analysis
```bash
# Access logs
tail -f logs/nginx/finbotaiagent_access.log

# Error logs
tail -f logs/nginx/finbotaiagent_error.log
```

## 🚀 Advanced Configuration

### 1. SSL/HTTPS Setup
```nginx
# HTTPS server block (uncomment when SSL is configured)
server {
    listen 443 ssl http2;
    ssl_certificate /path/to/certificate.crt;
    ssl_certificate_key /path/to/private.key;
    # ... rest of configuration
}
```

### 2. Custom Load Balancing
```nginx
# Custom load balancing algorithm
upstream finbotaiagent_backend {
    server localhost:8080 weight=3;  # 75% traffic
    server localhost:8081 weight=1;  # 25% traffic
}
```

### 3. Sticky Sessions
```nginx
# Sticky sessions (if needed)
upstream finbotaiagent_backend {
    ip_hash;  # Sticky sessions by IP
    server localhost:8080;
    server localhost:8081;
}
```

## 📋 Best Practices

### 1. Health Checks
- Implement comprehensive health checks
- Monitor both services independently
- Set up alerts for failures

### 2. Logging
- Centralize logs
- Monitor error rates
- Set up log rotation

### 3. Security
- Keep nginx updated
- Use security headers
- Implement rate limiting

### 4. Performance
- Monitor response times
- Optimize caching
- Use compression

## 🎉 Benefits

### 1. High Availability
- Automatic failover
- Health checks
- Zero-downtime deployments

### 2. Load Distribution
- Even traffic distribution
- Performance optimization
- Scalability

### 3. Monitoring
- Centralized logging
- Health monitoring
- Performance metrics

### 4. Security
- Single entry point
- Security headers
- Rate limiting

---

**Your FinBotAiAgent application now has professional load balancing with nginx, providing high availability, monitoring, and seamless access to both deployment methods! 🚀**
