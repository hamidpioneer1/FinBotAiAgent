# FinBot AI Agent - EC2 Deployment Guide

## Overview
This guide provides step-by-step instructions for deploying the FinBot AI Agent .NET 9 web API to an EC2 Ubuntu instance using Docker.

## Prerequisites
- EC2 Ubuntu instance (t2.micro or higher recommended)
- SSH access to the instance
- Security group configured to allow HTTP (port 8080) and SSH (port 22)

## Step 1: EC2 Instance Setup

### Connect to your EC2 instance:
```bash
ssh -i your-key.pem ubuntu@your-ec2-ip
```

### Update system packages:
```bash
sudo apt update && sudo apt upgrade -y
```

### Install essential packages:
```bash
sudo apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release
```

## Step 2: Install Docker

### Add Docker's official GPG key:
```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```

### Add Docker repository:
```bash
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### Install Docker:
```bash
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

### Add ubuntu user to docker group:
```bash
sudo usermod -aG docker ubuntu
```

### Start and enable Docker:
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

### Verify Docker installation:
```bash
docker --version
docker compose version
```

**Note:** You may need to log out and back in for the docker group changes to take effect.

## Step 3: Deploy the Application

### Clone or upload your project to EC2:
```bash
# Option 1: Clone from Git
git clone <your-repository-url>
cd FinBotAiAgent

# Option 2: Upload files via SCP
# scp -r -i your-key.pem ./FinBotAiAgent ubuntu@your-ec2-ip:~/
```

### Make deployment script executable:
```bash
chmod +x deploy.sh
chmod +x monitoring.sh
```

### Run the deployment:
```bash
./deploy.sh
```

## Step 4: Configure Auto-start (Optional)

### Copy the service file:
```bash
sudo cp finbotaiagent.service /etc/systemd/system/
```

### Enable and start the service:
```bash
sudo systemctl daemon-reload
sudo systemctl enable finbotaiagent
sudo systemctl start finbotaiagent
```

### Check service status:
```bash
sudo systemctl status finbotaiagent
```

## Step 5: Configure Security Group

Ensure your EC2 security group allows:
- **SSH (Port 22)**: For remote access
- **HTTP (Port 8080)**: For API access
- **HTTPS (Port 443)**: If using SSL (optional)

## Step 6: Verify Deployment

### Check application status:
```bash
./monitoring.sh
```

### Test the API:
```bash
curl http://localhost:8080/weatherforecast
curl http://localhost:8080/swagger
```

### Access from external:
```bash
curl http://your-ec2-public-ip:8080/weatherforecast
```

## Step 7: Monitoring and Maintenance

### View logs:
```bash
docker compose logs -f finbotaiagent
```

### Restart application:
```bash
docker compose restart finbotaiagent
```

### Update application:
```bash
git pull  # if using Git
./deploy.sh
```

### Check resource usage:
```bash
docker stats
```

## Troubleshooting

### Common Issues:

1. **Port 8080 not accessible**:
   - Check security group settings
   - Verify application is running: `docker compose ps`
   - Check logs: `docker compose logs finbotaiagent`

2. **Database connection issues**:
   - Verify PostgreSQL server is accessible
   - Check connection string in `appsettings.Production.json`
   - Ensure network connectivity

3. **Docker permission issues**:
   - Log out and back in after adding user to docker group
   - Or run: `newgrp docker`

4. **Application not starting**:
   - Check logs: `docker compose logs finbotaiagent`
   - Verify all files are present
   - Check disk space: `df -h`

### Useful Commands:

```bash
# View running containers
docker compose ps

# View logs
docker compose logs finbotaiagent

# Restart application
docker compose restart finbotaiagent

# Stop application
docker compose down

# View resource usage
docker stats

# Clean up unused images
docker image prune -f
```

## Security Best Practices

1. **Use environment variables** for sensitive data instead of hardcoding
2. **Regularly update** Docker images and system packages
3. **Monitor logs** for suspicious activity
4. **Use HTTPS** in production with proper SSL certificates
5. **Implement rate limiting** for API endpoints
6. **Regular backups** of application data and configuration

## Performance Optimization

1. **Use multi-stage builds** (already implemented in Dockerfile)
2. **Implement connection pooling** for database connections
3. **Use caching** for frequently accessed data
4. **Monitor resource usage** and scale accordingly
5. **Implement health checks** (already configured)

## Next Steps

1. Set up CI/CD pipeline for automated deployments
2. Implement SSL/TLS certificates
3. Set up monitoring and alerting
4. Configure automated backups
5. Implement load balancing for high availability 