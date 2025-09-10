# ⚡ Quick Start Deployment

## 🚀 **Deploy in 15 Minutes**

This guide provides the fastest path to deploy FinBotAiAgent with OAuth 2.0 and external key management.

## 📋 **Prerequisites**

- AWS EC2 instance (Ubuntu 20.04+)
- GitHub repository with Actions enabled
- Domain name (optional)

## ⚡ **Step 1: Generate Keys (2 minutes)**

```bash
# Generate API key
API_KEY=$(openssl rand -hex 32)
echo "API Key: $API_KEY"

# Generate JWT secret
JWT_SECRET=$(openssl rand -hex 64)
echo "JWT Secret: $JWT_SECRET"

# Generate database password
DB_PASSWORD=$(openssl rand -hex 16)
echo "DB Password: $DB_PASSWORD"
```

## ⚡ **Step 2: Set GitHub Secrets (3 minutes)**

Go to **GitHub Repository** → **Settings** → **Secrets and variables** → **Actions**

Add these secrets:
```
DB_HOST=localhost
DB_USERNAME=finbotuser
DB_PASSWORD=your-generated-db-password
DB_NAME=finbotdb
API_KEY=your-generated-api-key
JWT_SECRET_KEY=your-generated-jwt-secret
EC2_HOST=your-ec2-public-ip
EC2_USERNAME=ubuntu
EC2_SSH_KEY=your-ssh-private-key-content
```

## ⚡ **Step 3: Deploy (5 minutes)**

```bash
# Commit and push
git add .
git commit -m "Deploy with OAuth 2.0"
git push origin main
```

**That's it!** GitHub Actions will automatically:
- ✅ Build the application
- ✅ Deploy to EC2
- ✅ Configure PostgreSQL
- ✅ Set up external key management
- ✅ Start the application

## ⚡ **Step 4: Verify (5 minutes)**

### **Check Health**
```bash
curl http://your-ec2-ip/health
```

### **Test API Key Authentication**
```bash
curl -H "X-API-Key: your-generated-api-key" \
  http://your-ec2-ip/api/expenses
```

### **Test OAuth 2.0**
```bash
# Get OAuth token
curl -X POST http://your-ec2-ip/oauth/token \
  -H "Content-Type: application/json" \
  -d '{
    "grant_type": "client_credentials",
    "client_id": "copilot-studio-client",
    "client_secret": "copilot-studio-secret-12345",
    "scope": "api.read api.write"
  }'

# Use JWT token (replace YOUR_TOKEN with actual token)
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://your-ec2-ip/api/expenses
```

## 🎯 **Quick Configuration**

### **For Production with Domain**
1. **Update GitHub Secrets** with your domain
2. **Configure SSL** with Let's Encrypt
3. **Update CORS** settings for your domain

### **For Copilot Studio Integration**
Use these settings in your custom connector:
```json
{
  "authentication": {
    "type": "oauth2_client_credentials",
    "tokenUrl": "http://your-ec2-ip/oauth/token",
    "clientId": "copilot-studio-client",
    "clientSecret": "copilot-studio-secret-12345",
    "scope": "api.read api.write"
  }
}
```

## 🚨 **Troubleshooting**

### **Application Not Starting**
```bash
# Check GitHub Actions logs
# Go to your repository → Actions tab

# Check application logs on EC2
ssh -i your-key.pem ubuntu@your-ec2-ip
docker logs finbotaiagent
```

### **Database Connection Issues**
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Restart PostgreSQL
sudo systemctl restart postgresql
```

### **Authentication Not Working**
```bash
# Check API key file
cat /app/secrets/api-key.txt

# Check environment variables
docker exec finbotaiagent env | grep -E "(API_KEY|JWT_SECRET)"
```

## 📊 **What You Get**

After deployment, your FinBotAiAgent will have:

- ✅ **OAuth 2.0 Client Credentials** authentication
- ✅ **API Key** authentication fallback
- ✅ **External key management** with rotation
- ✅ **Rate limiting** and security features
- ✅ **Copilot Studio** integration ready
- ✅ **Health checks** for monitoring
- ✅ **Swagger UI** for API documentation

## 🔧 **Next Steps**

1. **Configure Domain** (optional) - Set up custom domain and SSL
2. **Set Up Monitoring** - Configure external monitoring
3. **Integrate with Copilot Studio** - Use the OAuth credentials
4. **Rotate Keys** - Set up regular key rotation schedule

## 📞 **Need Help?**

- **Detailed Guide**: [Complete Deployment Guide](COMPLETE_DEPLOYMENT_GUIDE.md)
- **Checklist**: [Deployment Checklist](DEPLOYMENT_CHECKLIST.md)
- **Troubleshooting**: Check application logs and GitHub Actions

---

**Your FinBotAiAgent is now live and ready for integration!** 🎉
