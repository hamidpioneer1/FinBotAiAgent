# FinBot AI Agent - .NET 9 Web API

A minimal .NET 9 web API for financial bot operations with PostgreSQL integration.

## 🔐 Security Configuration

**Important**: This application uses secure configuration management. See [SECURITY_SETUP.md](SECURITY_SETUP.md) for detailed instructions on:

- Setting up User Secrets for local development
- Configuring environment variables for production
- Security best practices
- Troubleshooting guide

**For Production Deployment**: See [GITHUB_SECRETS_SETUP.md](GITHUB_SECRETS_SETUP.md) for setting up GitHub Secrets for secure CI/CD deployment to AWS EC2.

### Quick Security Setup

**For Local Development:**
```bash
# Initialize User Secrets
dotnet user-secrets init

# Add your database connection string
dotnet user-secrets set "ConnectionStrings:PostgreSql" "Host=localhost;Username=postgres;Password=your_password;Database=finbotdb"
```

**For Production:**
Update the environment variables in `docker-compose.yml` with your actual database credentials.

## 🚀 Quick Start

### Local Development
```bash
# Clone the repository
git clone <your-repo-url>
cd FinBotAiAgent

# Set up User Secrets (see SECURITY_SETUP.md)
dotnet user-secrets init
dotnet user-secrets set "ConnectionStrings:PostgreSql" "your-connection-string"

# Run locally
dotnet run

# Or with Docker
docker-compose up
```

### Production Deployment

#### Prerequisites
- Ubuntu 20.04+ EC2 instance
- Docker and Docker Compose installed
- Nginx for reverse proxy
- Domain name (optional)
- GitHub repository with GitHub Secrets configured

#### Step-by-Step Deployment

**Option 1: Automated Deployment (Recommended)**
1. **Set up GitHub Secrets** - Follow [GITHUB_SECRETS_SETUP.md](GITHUB_SECRETS_SETUP.md)
2. **Push to main branch** - Deployment happens automatically via GitHub Actions
3. **Monitor deployment** - Check Actions tab in GitHub repository

**Option 2: Manual Deployment**
1. **EC2 Instance Setup**
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

# Install Nginx
sudo apt install -y nginx
```

2. **Deploy Application**
```bash
# Clone repository
git clone <your-repo-url> /home/ubuntu/finbotaiagent
cd /home/ubuntu/finbotaiagent

# Make deployment script executable
chmod +x deploy.sh

# Run deployment
./deploy.sh
```

3. **Configure Nginx**
```bash
# Copy nginx configuration
sudo cp nginx.conf /etc/nginx/sites-available/finbotaiagent
sudo ln -s /etc/nginx/sites-available/finbotaiagent /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default

# Test and reload nginx
sudo nginx -t
sudo systemctl reload nginx
```

4. **Setup SSL (Optional)**
```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d your-domain.com
```

## 🔧 Configuration

### Environment Variables
- `ASPNETCORE_ENVIRONMENT`: Set to `Production`
- `ASPNETCORE_URLS`: Set to `http://+:8080`
- Database connection string in `appsettings.Production.json`

### Security Best Practices
- ✅ Non-root Docker user
- ✅ Security headers in Nginx
- ✅ Resource limits in Docker
- ✅ Health checks
- ✅ Logging configuration

## 📊 Monitoring

### Health Check
```bash
# Check application health
curl http://your-domain.com/health

# Check container status
docker-compose ps

# View logs
docker-compose logs -f finbotaiagent
```

### Performance Monitoring
```bash
# Monitor resource usage
docker stats

# Check disk usage
df -h

# Monitor memory
free -h
```

## 🔄 CI/CD Pipeline

### GitHub Actions Setup

1. **Repository Secrets**
Add these secrets to your GitHub repository:
- `EC2_HOST`: Your EC2 public IP
- `EC2_USERNAME`: ubuntu
- `EC2_SSH_KEY`: Your private SSH key

2. **Automatic Deployment**
- Push to `main` branch triggers deployment
- Pull requests run tests only
- Deployment includes health checks

### Manual Deployment
```bash
# SSH to EC2
ssh -i your-key.pem ubuntu@your-ec2-ip

# Navigate to project
cd /home/ubuntu/finbotaiagent

# Pull latest changes
git pull origin main

# Deploy
./deploy.sh
```

## 🐳 Docker Commands

```bash
# Build image
docker-compose build

# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f

# Update and restart
docker-compose pull && docker-compose up -d
```

## 📝 API Endpoints

- `GET /weatherforecast` - Sample weather data
- `POST /api/expenses` - Create expense
- `GET /api/expenses/{id}` - Get expense by ID
- `GET /api/policies` - Get expense policies
- `GET /swagger` - API documentation

## 🔍 Troubleshooting

### Common Issues

1. **Application not starting**
```bash
# Check logs
docker-compose logs finbotaiagent

# Check if port is in use
sudo netstat -tlnp | grep 8080
```

2. **Database connection issues**
```bash
# Test database connection
docker exec -it finbotaiagent curl -f http://localhost:8080/weatherforecast
```

3. **Nginx issues**
```bash
# Check nginx status
sudo systemctl status nginx

# Check nginx configuration
sudo nginx -t

# View nginx logs
sudo tail -f /var/log/nginx/error.log
```

## 📈 Performance Optimization

- Connection pooling enabled
- Gzip compression
- Resource limits configured
- Health checks implemented
- Log rotation enabled

## 🔒 Security Checklist

- [ ] Non-root Docker user
- [ ] Security headers configured
- [ ] Resource limits set
- [ ] Health checks enabled
- [ ] Logging configured
- [ ] SSL certificate (if using domain)
- [ ] Firewall rules configured
- [ ] Regular security updates

## 📞 Support

For issues or questions:
1. Check the troubleshooting section
2. Review container logs
3. Check GitHub Issues
4. Contact the development team 