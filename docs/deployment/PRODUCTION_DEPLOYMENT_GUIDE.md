# Production Deployment Guide

This guide covers the complete production deployment setup for FinBotAiAgent using GitHub Secrets and AWS EC2.

## 🎯 Overview

The deployment architecture uses:
- **GitHub Actions** for CI/CD
- **GitHub Secrets** for secure configuration
- **AWS EC2** for hosting
- **Docker Compose** for containerization
- **Environment variables** for production configuration

## 📋 Prerequisites

### 1. AWS EC2 Instance
- Ubuntu 20.04+ instance
- At least 1GB RAM (t2.micro for free tier)
- Security group configured for SSH (port 22) and HTTP (port 8080)

### 2. Database
- PostgreSQL database (local, RDS, or external)
- Database credentials ready

### 3. GitHub Repository
- Repository with main branch
- Access to repository settings

## 🚀 Quick Start

### Step 1: Prepare GitHub Secrets

Run the helper script to prepare your secrets:
```bash
./scripts/setup-github-secrets.sh
```

Or manually set up the following secrets in your GitHub repository:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `EC2_HOST` | EC2 public IP | `3.250.123.45` |
| `EC2_USERNAME` | SSH username | `ubuntu` |
| `EC2_SSH_KEY` | Private SSH key | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `EC2_PORT` | SSH port | `22` |
| `DB_HOST` | Database host | `localhost` or `your-rds-endpoint` |
| `DB_USERNAME` | Database username | `postgres` |
| `DB_PASSWORD` | Database password | `MySecurePassword123!` |
| `DB_NAME` | Database name | `finbotdb` |

### Step 2: Set Up EC2 Instance

SSH to your EC2 instance and run:
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Logout and login again
exit
ssh -i your-key.pem ubuntu@your-ec2-ip
```

### Step 3: Deploy

Push to the main branch:
```bash
git add .
git commit -m "Initial deployment"
git push origin main
```

Monitor deployment in GitHub Actions tab.

## 🔧 Detailed Setup

### 1. GitHub Secrets Configuration

#### Access GitHub Secrets
1. Go to your GitHub repository
2. Click **Settings** tab
3. Click **Secrets and variables** → **Actions**
4. Click **New repository secret**

#### Required Secrets

**EC2 Connection:**
- `EC2_HOST`: Your EC2 public IP address
- `EC2_USERNAME`: SSH username (usually `ubuntu`)
- `EC2_SSH_KEY`: Your private SSH key content
- `EC2_PORT`: SSH port (optional, defaults to 22)

**Database:**
- `DB_HOST`: Database server address
- `DB_USERNAME`: Database username
- `DB_PASSWORD`: Database password
- `DB_NAME`: Database name

### 2. EC2 Security Group Configuration

Configure your EC2 security group to allow:
- **Port 22**: SSH access
- **Port 8080**: Application access
- **Port 80**: HTTP (if using nginx)
- **Port 443**: HTTPS (if using SSL)

### 3. Database Setup

#### Option A: Local PostgreSQL on EC2
```bash
# Install PostgreSQL
sudo apt install postgresql postgresql-contrib

# Start PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create database and user
sudo -u postgres psql
CREATE DATABASE finbotdb;
CREATE USER finbotuser WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE finbotdb TO finbotuser;
\q

# Update PostgreSQL configuration
sudo nano /etc/postgresql/*/main/postgresql.conf
# Add: listen_addresses = '*'

sudo nano /etc/postgresql/*/main/pg_hba.conf
# Add: host all all 0.0.0.0/0 md5

# Restart PostgreSQL
sudo systemctl restart postgresql
```

#### Option B: AWS RDS
1. Create RDS PostgreSQL instance
2. Note the endpoint, username, and password
3. Update security group to allow EC2 access

#### Option C: External Database
1. Ensure database is accessible from EC2 IP
2. Configure firewall rules accordingly

### 4. Application Deployment

The GitHub Actions workflow will:
1. Build the application
2. Create deployment package
3. SSH to EC2 instance
4. Create `.env` file with secrets
5. Build and start Docker containers
6. Verify deployment health

## 🔍 Monitoring and Troubleshooting

### Check Deployment Status

#### GitHub Actions
1. Go to **Actions** tab in repository
2. Click on the latest workflow run
3. Check for any errors in the logs

#### EC2 Instance
```bash
# SSH to EC2
ssh -i your-key.pem ubuntu@your-ec2-ip

# Check container status
docker-compose ps

# Check application logs
docker-compose logs finbotaiagent

# Test application
curl http://localhost:8080/weatherforecast
```

### Common Issues

#### 1. SSH Connection Failed
```
Error: ssh: connect to host xxx.xxx.xxx.xxx port 22: Connection refused
```
**Solutions:**
- Verify EC2 instance is running
- Check security group allows SSH (port 22)
- Ensure SSH key is correct
- Test SSH connection manually

#### 2. Database Connection Failed
```
Error: Unable to connect to database
```
**Solutions:**
- Verify database credentials in GitHub Secrets
- Check if database server is accessible from EC2
- Ensure database server allows connections from EC2 IP
- Test database connection manually

#### 3. Application Not Starting
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

### 1. Secrets Management
- ✅ Use GitHub Secrets for sensitive data
- ✅ Never commit secrets to repository
- ✅ Rotate secrets regularly
- ✅ Use strong passwords

### 2. Network Security
- ✅ Configure security groups properly
- ✅ Use least privilege principle
- ✅ Restrict database access to EC2 IP only
- ✅ Consider using VPC for additional security

### 3. Application Security
- ✅ Run containers as non-root user
- ✅ Use resource limits in Docker
- ✅ Implement health checks
- ✅ Monitor application logs

### 4. Infrastructure Security
- ✅ Keep system packages updated
- ✅ Use SSH keys instead of passwords
- ✅ Configure firewall rules
- ✅ Regular security audits

## 📊 Monitoring and Maintenance

### 1. Application Monitoring
```bash
# Check application health
curl http://your-ec2-ip:8080/weatherforecast

# Monitor resource usage
docker stats

# Check logs
docker-compose logs -f finbotaiagent
```

### 2. System Monitoring
```bash
# Check system resources
htop
df -h
free -h

# Check Docker resources
docker system df
```

### 3. Backup Strategy
- Backup database regularly
- Keep deployment configurations in version control
- Document recovery procedures

## 🎯 Next Steps

After successful deployment:

1. **Set up monitoring** - Implement application and system monitoring
2. **Configure SSL/TLS** - Set up HTTPS if using a domain
3. **Set up logging** - Implement centralized logging
4. **Automate backups** - Set up automated database backups
5. **Scale horizontally** - Consider load balancing for high traffic
6. **Implement CI/CD** - Set up automated testing and deployment

## 📞 Support

If you encounter issues:

1. **Check GitHub Actions logs** for detailed error messages
2. **Review troubleshooting section** above
3. **Check EC2 instance logs** and Docker container logs
4. **Verify all secrets are correctly set** in GitHub repository
5. **Test connectivity** manually using SSH

## 📚 Additional Resources

- [GitHub Secrets Setup Guide](GITHUB_SECRETS_SETUP.md)
- [Security Setup Guide](SECURITY_SETUP.md)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions) 