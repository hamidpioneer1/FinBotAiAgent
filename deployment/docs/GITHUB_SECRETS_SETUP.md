# GitHub Secrets Setup Guide

This guide explains how to set up GitHub Secrets for secure deployment of your FinBotAiAgent application to AWS EC2.

## 🔐 Required GitHub Secrets

You need to configure the following secrets in your GitHub repository:

### 1. **EC2 Connection Secrets**
- `EC2_HOST` - Your EC2 instance public IP address
- `EC2_USERNAME` - SSH username (usually `ubuntu`)
- `EC2_SSH_KEY` - Your private SSH key for EC2 access
- `EC2_PORT` - SSH port (optional, defaults to 22)

### 2. **Database Secrets**
- `DB_HOST` - Your database host address
- `DB_USERNAME` - Database username
- `DB_PASSWORD` - Database password
- `DB_NAME` - Database name

## 📋 Step-by-Step Setup

### Step 1: Access GitHub Secrets

1. Go to your GitHub repository
2. Click on **Settings** tab
3. In the left sidebar, click **Secrets and variables** → **Actions**
4. Click **New repository secret**

### Step 2: Add EC2 Connection Secrets

#### EC2_HOST
```
Name: EC2_HOST
Value: your-ec2-public-ip
Example: 3.250.123.45
```

#### EC2_USERNAME
```
Name: EC2_USERNAME
Value: ubuntu
```

#### EC2_SSH_KEY
```
Name: EC2_SSH_KEY
Value: -----BEGIN OPENSSH PRIVATE KEY-----
your-private-key-content
-----END OPENSSH PRIVATE KEY-----
```

**How to get your SSH key:**
```bash
# If you don't have a key pair, create one:
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"

# Copy your private key content:
cat ~/.ssh/id_rsa
```

#### EC2_PORT (Optional)
```
Name: EC2_PORT
Value: 22
```

### Step 3: Add Database Secrets

#### DB_HOST
```
Name: DB_HOST
Value: your-database-host
Examples:
- For local PostgreSQL: localhost
- For AWS RDS: your-rds-endpoint.region.rds.amazonaws.com
- For external database: your-db-server-ip
```

#### DB_USERNAME
```
Name: DB_USERNAME
Value: your-database-username
Example: postgres
```

#### DB_PASSWORD
```
Name: DB_PASSWORD
Value: your-database-password
Example: MySecurePassword123!
```

#### DB_NAME
```
Name: DB_NAME
Value: your-database-name
Example: finbotdb
```

## 🔧 EC2 Setup Requirements

### 1. Install Docker and Docker Compose
```bash
# Connect to your EC2 instance
ssh -i your-key.pem ubuntu@your-ec2-ip

# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Logout and login again to apply docker group
exit
ssh -i your-key.pem ubuntu@your-ec2-ip
```

### 2. Configure SSH Access
```bash
# On your EC2 instance, ensure SSH key is properly set up
# The public key should be in ~/.ssh/authorized_keys

# Test SSH connection from your local machine
ssh -i your-key.pem ubuntu@your-ec2-ip
```

### 3. Open Required Ports
```bash
# Configure security group to allow:
# - Port 22 (SSH)
# - Port 8080 (Application)
# - Port 80 (HTTP, if using nginx)
# - Port 443 (HTTPS, if using SSL)
```

## 🚀 Testing the Setup

### 1. Test GitHub Actions
1. Push a change to the `main` branch
2. Go to **Actions** tab in your GitHub repository
3. Monitor the deployment workflow
4. Check for any errors in the logs

### 2. Verify Deployment
```bash
# SSH to your EC2 instance
ssh -i your-key.pem ubuntu@your-ec2-ip

# Check if containers are running
docker-compose ps

# Check application logs
docker-compose logs finbotaiagent

# Test the application
curl http://localhost:8080/weatherforecast
```

## 🔍 Troubleshooting

### Common Issues

#### 1. SSH Connection Failed
```
Error: ssh: connect to host xxx.xxx.xxx.xxx port 22: Connection refused
```
**Solutions:**
- Check if EC2 instance is running
- Verify security group allows SSH (port 22)
- Ensure SSH key is correct
- Check if EC2_USERNAME is correct (usually `ubuntu`)

#### 2. Docker Permission Denied
```
Error: Got permission denied while trying to connect to the Docker daemon
```
**Solutions:**
- Ensure user is in docker group: `sudo usermod -aG docker $USER`
- Logout and login again
- Or run: `newgrp docker`

#### 3. Database Connection Failed
```
Error: Unable to connect to database
```
**Solutions:**
- Verify database credentials in GitHub Secrets
- Check if database server is accessible from EC2
- Ensure database server allows connections from EC2 IP
- Test database connection manually

#### 4. Application Not Starting
```
Error: Application health check failed
```
**Solutions:**
- Check container logs: `docker-compose logs`
- Verify environment variables are set correctly
- Ensure database is accessible
- Check if port 8080 is available

### Debug Commands

```bash
# Check GitHub Actions logs
# Go to Actions tab → Click on failed workflow → Check logs

# SSH to EC2 and debug
ssh -i your-key.pem ubuntu@your-ec2-ip

# Check Docker status
docker ps
docker-compose ps

# Check application logs
docker-compose logs finbotaiagent

# Check environment variables
docker-compose exec finbotaiagent env

# Test database connection
docker-compose exec finbotaiagent curl -f http://localhost:8080/weatherforecast

# Check disk space
df -h

# Check memory usage
free -h
```

## 🔒 Security Best Practices

1. **Rotate Secrets Regularly**
   - Change database passwords periodically
   - Rotate SSH keys when needed
   - Update access credentials

2. **Limit Access**
   - Use least privilege principle
   - Restrict database access to EC2 IP only
   - Use strong passwords

3. **Monitor Deployments**
   - Set up alerts for failed deployments
   - Monitor application health
   - Review logs regularly

4. **Backup Strategy**
   - Backup database regularly
   - Keep deployment configurations in version control
   - Document recovery procedures

## 📞 Support

If you encounter issues:

1. **Check GitHub Actions logs** for detailed error messages
2. **Review this troubleshooting guide**
3. **Check EC2 instance logs** and Docker container logs
4. **Verify all secrets are correctly set** in GitHub repository
5. **Test connectivity** manually using SSH

## 🎯 Next Steps

After setting up GitHub Secrets:

1. **Test the deployment** by pushing to main branch
2. **Set up monitoring** for your application
3. **Configure SSL/TLS** if using a domain
4. **Set up automated backups** for your database
5. **Implement logging and alerting** for production monitoring 