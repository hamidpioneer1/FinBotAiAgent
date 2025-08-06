# Deployment Verification Guide

This guide helps you verify that your FinBotAiAgent application is properly deployed and accessible through nginx on your EC2 instance.

## 🔍 Quick Verification

### **Step 1: Check if Application is Running**

SSH to your EC2 instance:
```bash
ssh -i your-key.pem ubuntu@your-ec2-ip
```

Check Docker containers:
```bash
# Check if containers are running
docker-compose ps

# Check application logs
docker-compose logs finbotaiagent

# Test application directly
curl http://localhost:8080/weatherforecast
```

### **Step 2: Check Nginx Status**

On your EC2 instance:
```bash
# Check nginx status
sudo systemctl status nginx

# Check nginx configuration
sudo nginx -t

# Test nginx proxy
curl http://localhost/weatherforecast
```

### **Step 3: Test External Access**

From your local machine:
```bash
# Test application via EC2 IP
curl http://your-ec2-ip/weatherforecast

# Test Swagger UI
curl http://your-ec2-ip/swagger

# Test health endpoint
curl http://your-ec2-ip/health
```

## 🛠️ Using the Verification Script

### **Run Complete Verification**
```bash
# Run the verification script
./scripts/verify-deployment.sh

# Or specify your EC2 IP
EC2_HOST=your-ec2-ip ./scripts/verify-deployment.sh
```

### **Run Specific Checks**
```bash
# Check local deployment only
./scripts/verify-deployment.sh local

# Check nginx configuration only
./scripts/verify-deployment.sh nginx

# Check external access only
./scripts/verify-deployment.sh external

# Show useful URLs
./scripts/verify-deployment.sh urls
```

## 🌐 Accessing Your Application

### **Main URLs**

Once deployed successfully, you can access:

| URL | Description |
|-----|-------------|
| `http://your-ec2-ip/` | Main application |
| `http://your-ec2-ip/weatherforecast` | Weather forecast API |
| `http://your-ec2-ip/swagger` | Swagger UI documentation |
| `http://your-ec2-ip/health` | Health check endpoint |

### **API Endpoints**

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/weatherforecast` | Get weather forecast |
| POST | `/api/expenses` | Create expense |
| GET | `/api/expenses/{id}` | Get expense by ID |
| GET | `/api/policies` | Get expense policies |

## 🔧 Troubleshooting

### **Application Not Responding**

#### **Check Docker Containers**
```bash
# SSH to EC2
ssh -i your-key.pem ubuntu@your-ec2-ip

# Check container status
docker-compose ps

# If containers are not running, start them
docker-compose up -d

# Check logs for errors
docker-compose logs finbotaiagent
```

#### **Check Application Logs**
```bash
# View real-time logs
docker-compose logs -f finbotaiagent

# Check for specific errors
docker-compose logs finbotaiagent | grep -i error
```

### **Nginx Issues**

#### **Check Nginx Status**
```bash
# Check if nginx is running
sudo systemctl status nginx

# Start nginx if not running
sudo systemctl start nginx

# Enable nginx to start on boot
sudo systemctl enable nginx
```

#### **Check Nginx Configuration**
```bash
# Test nginx configuration
sudo nginx -t

# If configuration is invalid, check the config
sudo nano /etc/nginx/sites-available/finbotaiagent

# Reload nginx after changes
sudo systemctl reload nginx
```

#### **Check Nginx Logs**
```bash
# Check nginx error logs
sudo tail -f /var/log/nginx/error.log

# Check nginx access logs
sudo tail -f /var/log/nginx/access.log
```

### **Security Group Issues**

#### **Check AWS Security Group**
1. Go to AWS Console → EC2 → Security Groups
2. Find your EC2 instance's security group
3. Ensure these rules are configured:

| Type | Protocol | Port Range | Source |
|------|----------|------------|--------|
| SSH | TCP | 22 | Your IP or 0.0.0.0/0 |
| HTTP | TCP | 80 | 0.0.0.0/0 |
| Custom TCP | TCP | 8080 | 0.0.0.0/0 (optional) |

### **Database Connection Issues**

#### **Check Database Connection**
```bash
# Test database connection from EC2
docker-compose exec finbotaiagent curl -f http://localhost:8080/weatherforecast

# Check environment variables
docker-compose exec finbotaiagent env | grep DB_
```

#### **Verify Database Credentials**
```bash
# Check if database is accessible
docker-compose exec finbotaiagent ping your-database-host

# Test database connection manually
docker-compose exec finbotaiagent psql -h your-db-host -U your-db-user -d your-db-name
```

## 📊 Monitoring Commands

### **Check System Resources**
```bash
# Check memory usage
free -h

# Check disk usage
df -h

# Check CPU usage
top

# Check Docker resources
docker stats
```

### **Check Application Health**
```bash
# Test application health
curl -f http://your-ec2-ip/weatherforecast

# Check response time
curl -w "@-" -o /dev/null -s "http://your-ec2-ip/weatherforecast" <<'EOF'
     time_namelookup:  %{time_namelookup}\n
        time_connect:  %{time_connect}\n
     time_appconnect:  %{time_appconnect}\n
    time_pretransfer:  %{time_pretransfer}\n
       time_redirect:  %{time_redirect}\n
  time_starttransfer:  %{time_starttransfer}\n
                     ----------\n
          time_total:  %{time_total}\n
EOF
```

## 🔒 Security Verification

### **Check Security Headers**
```bash
# Check if security headers are present
curl -I http://your-ec2-ip/weatherforecast

# You should see headers like:
# X-Frame-Options: SAMEORIGIN
# X-XSS-Protection: 1; mode=block
# X-Content-Type-Options: nosniff
```

### **Check SSL/TLS** (if configured)
```bash
# Test HTTPS (if SSL is configured)
curl -I https://your-ec2-ip/weatherforecast

# Check SSL certificate
openssl s_client -connect your-ec2-ip:443 -servername your-ec2-ip
```

## 🎯 Success Indicators

Your deployment is successful when:

✅ **Docker containers are running**
```bash
docker-compose ps
# Should show: finbotaiagent | Up
```

✅ **Application responds locally**
```bash
curl http://localhost:8080/weatherforecast
# Should return JSON response
```

✅ **Nginx is running**
```bash
sudo systemctl status nginx
# Should show: Active: active (running)
```

✅ **Nginx proxy works**
```bash
curl http://localhost/weatherforecast
# Should return same response as direct app
```

✅ **External access works**
```bash
curl http://your-ec2-ip/weatherforecast
# Should return JSON response
```

✅ **Swagger UI is accessible**
```bash
curl http://your-ec2-ip/swagger
# Should return HTML page
```

## 📞 Common Issues & Solutions

### **Issue: "Connection refused"**
**Solution**: Check if application is running and security group allows port 80

### **Issue: "502 Bad Gateway"**
**Solution**: Check nginx configuration and application logs

### **Issue: "404 Not Found"**
**Solution**: Check if nginx is properly configured to proxy to port 8080

### **Issue: "Database connection failed"**
**Solution**: Verify database credentials in GitHub Secrets and network connectivity

### **Issue: "Application not starting"**
**Solution**: Check Docker logs and ensure all environment variables are set

## 🚀 Next Steps

After successful verification:

1. **Set up monitoring** - Implement application monitoring
2. **Configure SSL/TLS** - Set up HTTPS for production
3. **Set up logging** - Implement centralized logging
4. **Configure backups** - Set up automated database backups
5. **Set up alerts** - Configure alerts for downtime

Your application should now be fully accessible via `http://your-ec2-ip/`! 🎉 