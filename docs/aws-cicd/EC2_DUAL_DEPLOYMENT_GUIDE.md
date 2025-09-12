# EC2 Dual Deployment Technical Guide

**Advanced configuration and troubleshooting for FinBotAiAgent dual deployment**

This guide provides detailed technical information for configuring, monitoring, and troubleshooting the dual deployment setup on EC2.

## Overview

The dual deployment architecture runs two instances of the same application on a single EC2 instance:

1. **GitHub Actions → EC2 Port 8080** (existing deployment)
2. **AWS CodePipeline → EC2 Port 8081** (new deployment)

**Key Benefits:**
- Cost-effective (stays within AWS Free Tier)
- Side-by-side comparison of deployment methods
- Independent configuration and scaling
- Minimal infrastructure overhead

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   GitHub Repo   │    │   AWS CodeBuild  │    │   EC2 Instance  │
│                 │───▶│                  │───▶│                 │
│                 │    │  - Build & Test  │    │  Port 8081      │
│                 │    │  - Docker Image  │    │  (CodePipeline) │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         │                       ▼                       │
         │              ┌──────────────────┐             │
         │              │   ECR Registry   │             │
         │              │                  │             │
         │              │  - Store Images  │             │
         └──────────────┼──────────────────┘             │
                        │                                │
         ┌──────────────▼────────────────────────────────┘
         │         EC2 Instance (Same)                   │
         │                                               │
         │  - GitHub Actions Deploy (Port 8080)         │
         │  - CodePipeline Deploy (Port 8081)           │
         └───────────────────────────────────────────────┘
```

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform installed (version >= 1.0)
- GitHub personal access token with repo access
- Existing EC2 instance (t2.micro for free tier)
- EC2 instance ID, SSH key name, and security group ID
- Docker installed on EC2 instance
- SSM agent running on EC2 instance

## Quick Start

1. **Get your EC2 information:**
   ```bash
   # Get instance ID
   aws ec2 describe-instances --query 'Reservations[].Instances[?State.Name==`running`].[InstanceId,PublicIpAddress,KeyName,SecurityGroups[0].GroupId]' --output table
   ```

2. **Run the setup script:**
   ```bash
   cd aws-cicd
   ./setup-dual-deployment.sh \
     -o your-github-username \
     -t your-github-token \
     --ec2-instance-id i-1234567890abcdef0 \
     --ec2-ssh-key-name your-key-pair \
     --ec2-security-group-id sg-12345678
   ```

3. **Push code to trigger both deployments:**
   ```bash
   git add .
   git commit -m "Trigger dual deployment"
   git push origin main
   ```

## Detailed Setup

### Step 1: Prepare EC2 Instance

Ensure your EC2 instance has the required software:

```bash
# SSH to your EC2 instance
ssh -i your-key.pem ubuntu@your-ec2-ip

# Install Docker (if not already installed)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install SSM agent (if not already installed)
sudo snap install amazon-ssm-agent --classic
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

# Logout and login again
exit
ssh -i your-key.pem ubuntu@your-ec2-ip
```

### Step 2: Configure Security Group

Ensure your EC2 security group allows both ports:

```bash
# Add rule for CodePipeline deployment port
aws ec2 authorize-security-group-ingress \
    --group-id sg-12345678 \
    --protocol tcp \
    --port 8081 \
    --cidr 0.0.0.0/0
```

### Step 3: Configure Terraform Variables

Create a `terraform.tfvars` file:

```hcl
# AWS Configuration
aws_region = "us-east-1"

# Project Configuration
project_name = "finbotaiagent"
environment  = "prod"

# GitHub Configuration
github_owner = "your-github-username"
github_repo  = "FinBotAiAgent"
github_branch = "main"
github_token = "ghp_your_github_personal_access_token"

# EC2 Configuration for CodePipeline Deployment
ec2_instance_id = "i-1234567890abcdef0"
ec2_ssh_key_name = "your-key-pair-name"
ec2_security_group_id = "sg-12345678"
```

### Step 4: Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply deployment
terraform apply
```

### Step 5: Configure Database Parameters

The application requires these AWS SSM parameters and secrets:

```bash
# SSM Parameters
aws ssm put-parameter --name "/finbotaiagent/db/host" --value "localhost" --type "String"
aws ssm put-parameter --name "/finbotaiagent/db/username" --value "postgres" --type "String"
aws ssm put-parameter --name "/finbotaiagent/db/name" --value "finbotdb" --type "String"

# Secrets Manager
aws secretsmanager create-secret \
    --name "finbotaiagent/db/password" \
    --description "Database password" \
    --secret-string "your-db-password"
```

## Deployment Methods Comparison

| Feature | GitHub Actions → EC2:8080 | AWS CodePipeline → EC2:8081 |
|---------|---------------------------|------------------------------|
| **Infrastructure** | Same EC2 instance | Same EC2 instance |
| **Port** | 8080 | 8081 |
| **Folder** | `/home/ubuntu/finbotaiagent` | `/home/ubuntu/finbotaiagent-codepipeline` |
| **Container Name** | `finbotaiagent` | `finbotaiagent-codepipeline` |
| **Cost** | Free (within limits) | Free (within limits) |
| **Scaling** | Manual | Manual |
| **Monitoring** | GitHub Actions logs | CloudWatch + CodeBuild logs |
| **Deployment Trigger** | Git push to main | Git push to main |

## Configuration Options

### Environment-Specific Deployments

You can deploy to different environments:

```bash
# Development environment
./setup-dual-deployment.sh -e dev -o your-username -t your-token --ec2-instance-id i-xxx

# Staging environment  
./setup-dual-deployment.sh -e staging -o your-username -t your-token --ec2-instance-id i-xxx

# Production environment
./setup-dual-deployment.sh -e prod -o your-username -t your-token --ec2-instance-id i-xxx
```

### Custom Port Configuration

You can change the CodePipeline deployment port by modifying the environment variable in the CodeBuild project:

```bash
# Update the deployment port in Terraform
# Change DEPLOYMENT_PORT from 8081 to your preferred port
```

## Monitoring and Troubleshooting

### View Logs

**GitHub Actions Logs:**
- Check the Actions tab in your GitHub repository

**CodePipeline Logs:**
```bash
# View CodePipeline status
aws codepipeline get-pipeline-state --name finbotaiagent-prod-pipeline --region us-east-1

# View CodeBuild logs
aws logs describe-log-groups --log-group-name-prefix "/aws/codebuild/finbotaiagent"
```

**EC2 Container Logs:**
```bash
# SSH to EC2 instance
ssh -i your-key.pem ubuntu@your-ec2-ip

# View GitHub Actions container logs
sudo docker logs finbotaiagent

# View CodePipeline container logs
sudo docker logs finbotaiagent-codepipeline

# View all running containers
sudo docker ps
```

### Health Checks

**Application Health:**
```bash
# GitHub Actions deployment (port 8080)
curl http://your-ec2-ip:8080/weatherforecast

# CodePipeline deployment (port 8081)
curl http://your-ec2-ip:8081/weatherforecast
```

### Common Issues

1. **Port Already in Use:**
   ```bash
   # Check what's using port 8081
   sudo netstat -tlnp | grep :8081
   
   # Kill process if needed
   sudo kill -9 <PID>
   ```

2. **Docker Permission Issues:**
   ```bash
   # Add user to docker group
   sudo usermod -aG docker $USER
   # Logout and login again
   ```

3. **SSM Agent Not Running:**
   ```bash
   # Check SSM agent status
   sudo systemctl status amazon-ssm-agent
   
   # Start SSM agent
   sudo systemctl start amazon-ssm-agent
   ```

4. **Database Connection Issues:**
   - Verify SSM parameters exist
   - Check Secrets Manager secret
   - Ensure database is running and accessible

## Cost Analysis

### AWS Free Tier Usage

| Service | Free Tier Limit | Usage |
|---------|----------------|-------|
| **EC2 t2.micro** | 750 hours/month | ~24 hours/day |
| **ECR** | 500 MB storage | ~100 MB per image |
| **CodeBuild** | 100 build minutes/month | ~5 minutes per build |
| **CodePipeline** | 1 active pipeline | 1 pipeline |
| **S3** | 5 GB storage | ~1 GB for artifacts |
| **CloudWatch Logs** | 5 GB storage | ~100 MB per month |

**Total Monthly Cost: $0** (within free tier limits)

## Security Considerations

### IAM Permissions
The setup creates these IAM roles:
- `finbotaiagent-prod-codebuild-role` - For CodeBuild operations
- `finbotaiagent-prod-codepipeline-role` - For CodePipeline operations
- `finbotaiagent-prod-ec2-deployment-role` - For EC2 deployment operations

### Network Security
- Both deployments use the same security group
- Port 8080: GitHub Actions deployment
- Port 8081: CodePipeline deployment
- Database access through localhost (same instance)

### Secrets Management
- Database credentials stored in AWS Secrets Manager
- ECR authentication handled automatically
- No hardcoded secrets in code

## Advanced Configuration

### Custom Buildspec
Modify `buildspec-deploy.yml` for custom deployment steps:

```yaml
version: 0.2
phases:
  pre_build:
    commands:
      - echo "Custom pre-deployment steps"
  build:
    commands:
      - echo "Custom deployment steps"
  post_build:
    commands:
      - echo "Custom post-deployment steps"
```

### Blue-Green Deployment
Use different ports for zero-downtime deployments:

```bash
# Deploy to port 8082 (green)
# Test the new version
# Switch traffic from 8081 to 8082
# Decommission old version on 8081
```

### Load Balancing
Use a reverse proxy to distribute traffic:

```nginx
# Nginx configuration
upstream finbotaiagent {
    server localhost:8080;  # GitHub Actions
    server localhost:8081;  # CodePipeline
}

server {
    listen 80;
    location / {
        proxy_pass http://finbotaiagent;
    }
}
```

## Cleanup

To remove all resources:

```bash
# Destroy Terraform infrastructure
terraform destroy

# Delete SSM parameters
aws ssm delete-parameter --name "/finbotaiagent/db/host"
aws ssm delete-parameter --name "/finbotaiagent/db/username"
aws ssm delete-parameter --name "/finbotaiagent/db/name"

# Delete Secrets Manager secret
aws secretsmanager delete-secret --secret-id "finbotaiagent/db/password" --force-delete-without-recovery

# Stop containers on EC2
ssh -i your-key.pem ubuntu@your-ec2-ip
sudo docker stop finbotaiagent finbotaiagent-codepipeline
sudo docker rm finbotaiagent finbotaiagent-codepipeline
```

## Support

For issues or questions:
1. Check the logs using the commands above
2. Verify IAM permissions and network connectivity
3. Ensure all required services are running on EC2
4. Check AWS Console for error messages

## Next Steps

1. **Set up monitoring:** Configure CloudWatch alarms and dashboards
2. **Implement CI/CD:** Add automated testing and quality gates
3. **Add security scanning:** Integrate vulnerability scanning in the pipeline
4. **Optimize performance:** Monitor resource usage and optimize configurations
5. **Add load balancing:** Implement reverse proxy for traffic distribution

## Conclusion

The EC2 dual deployment setup allows you to run both GitHub Actions and AWS CodePipeline deployments on the same EC2 instance using different ports. This approach:

- **Stays within AWS Free Tier** limits
- **Provides redundancy** with minimal cost
- **Allows side-by-side comparison** of deployment methods
- **Maintains simplicity** with single EC2 instance
- **Enables easy testing** of different configurations

Both deployments will use the same codebase and Docker image, but can be configured independently for different testing scenarios or gradual migration strategies.
