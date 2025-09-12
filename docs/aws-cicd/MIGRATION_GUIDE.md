# Migration Guide: GitHub Actions to Dual Deployment

**Step-by-step migration from GitHub Actions to dual deployment setup**

This guide helps you migrate from a single GitHub Actions deployment to a dual deployment setup with both GitHub Actions and AWS CodePipeline on the same EC2 instance.

## 🎯 Migration Overview

### Current Setup (GitHub Actions Only)
- **Build**: GitHub Actions runners
- **Deploy**: SSH to EC2, Docker Compose
- **Secrets**: GitHub Secrets
- **Monitoring**: GitHub Actions logs
- **Port**: 8080

### Target Setup (Dual Deployment)
- **GitHub Actions**: Port 8080 (existing)
- **AWS CodePipeline**: Port 8081 (new)
- **Secrets**: AWS Parameter Store + Secrets Manager
- **Monitoring**: GitHub Actions + CloudWatch logs
- **Cost**: $0 (within AWS Free Tier)

## 📋 Pre-Migration Checklist

- [ ] AWS CLI installed and configured
- [ ] Terraform installed (>= 1.0)
- [ ] Existing EC2 instance running
- [ ] GitHub Personal Access Token created
- [ ] AWS account with appropriate permissions
- [ ] Database accessible from EC2

## 🚀 Step-by-Step Migration

### Step 1: Prepare AWS Environment

#### 1.1 Create GitHub Personal Access Token
1. Go to GitHub Settings → Developer settings → Personal access tokens
2. Create token with these permissions:
   - `repo` (Full control of private repositories)
   - `workflow` (Update GitHub Action workflows)

#### 1.2 Configure AWS CLI
```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter your default region (e.g., us-east-1)
# Enter your default output format (json)
```

#### 1.3 Verify AWS Permissions
```bash
# Test AWS access
aws sts get-caller-identity

# Test EC2 access
aws ec2 describe-instances --query 'Reservations[].Instances[?State.Name==`running`].[InstanceId,PublicIpAddress]' --output table
```

### Step 2: Get EC2 Information

```bash
# Get your EC2 instance details
aws ec2 describe-instances --query 'Reservations[].Instances[?State.Name==`running`].[InstanceId,PublicIpAddress,KeyName,SecurityGroups[0].GroupId]' --output table
```

**Write down:**
- Instance ID (starts with `i-`)
- Public IP Address
- Key Name (your SSH key)
- Security Group ID (starts with `sg-`)

### Step 3: Prepare EC2 Instance

#### 3.1 Install Required Software
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

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install SSM agent
sudo snap install amazon-ssm-agent --classic
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

# Logout and login again
exit
ssh -i your-key.pem ubuntu@your-ec2-ip
```

#### 3.2 Configure Security Group
```bash
# Add port 8081 for CodePipeline deployment
aws ec2 authorize-security-group-ingress \
    --group-id sg-your-security-group-id \
    --protocol tcp \
    --port 8081 \
    --cidr 0.0.0.0/0
```

### Step 4: Deploy Dual Deployment Setup

#### 4.1 Run the Setup Script
```bash
# Navigate to aws-cicd directory
cd /path/to/your/FinBotAiAgent/aws-cicd

# Make script executable
chmod +x setup-dual-deployment.sh

# Run the setup (replace with your actual values)
./setup-dual-deployment.sh \
  -o your-github-username \
  -t ghp_your_github_token_here \
  --ec2-instance-id i-1234567890abcdef0 \
  --ec2-ssh-key-name your-key-pair-name \
  --ec2-security-group-id sg-12345678
```

#### 4.2 Configure Database Parameters
When prompted by the script, choose option 1 to configure database:

```bash
# Enter your database details when prompted:
Database Host: localhost
Database Username: postgres
Database Name: finbotdb
Database Password: your_password_here
```

### Step 5: Verify Migration

#### 5.1 Test Both Deployments
```bash
# Test GitHub Actions deployment (existing)
curl http://your-ec2-ip:8080/weatherforecast

# Test CodePipeline deployment (new)
curl http://your-ec2-ip:8081/weatherforecast
```

Both should return JSON data if successful.

#### 5.2 Check Container Status
```bash
# SSH to EC2
ssh -i your-key.pem ubuntu@your-ec2-ip

# View running containers
sudo docker ps

# Should show both containers:
# - finbotaiagent (GitHub Actions)
# - finbotaiagent-codepipeline (CodePipeline)
```

### Step 6: Update Monitoring

#### 6.1 GitHub Actions Monitoring
- **Existing**: Continue using GitHub Actions logs
- **Location**: GitHub repository → Actions tab
- **Port**: 8080

#### 6.2 CodePipeline Monitoring
```bash
# Check CodePipeline status
aws codepipeline get-pipeline-state --name finbotaiagent-prod-pipeline

# View CodeBuild logs
aws logs describe-log-groups --log-group-name-prefix "/aws/codebuild/finbotaiagent"

# View EC2 container logs
ssh -i your-key.pem ubuntu@your-ec2-ip
sudo docker logs finbotaiagent-codepipeline
```

## 🔄 Post-Migration Tasks

### 1. Update Documentation
- Update team documentation
- Update monitoring dashboards
- Update runbooks and procedures

### 2. Configure Alerts
```bash
# Set up CloudWatch alarms for CodePipeline
aws cloudwatch put-metric-alarm \
  --alarm-name "FinBotAiAgent-CodePipeline-Failures" \
  --alarm-description "CodePipeline deployment failures" \
  --metric-name FailedExecutions \
  --namespace AWS/CodePipeline \
  --statistic Sum \
  --period 300 \
  --threshold 1 \
  --comparison-operator GreaterThanOrEqualToThreshold
```

### 3. Test Rollback Procedures
```bash
# Test stopping CodePipeline deployment
ssh -i your-key.pem ubuntu@your-ec2-ip
sudo docker stop finbotaiagent-codepipeline

# Test restarting CodePipeline deployment
sudo docker start finbotaiagent-codepipeline
```

## 🚨 Rollback Plan

If you need to rollback to GitHub Actions only:

### 1. Stop CodePipeline Deployment
```bash
# SSH to EC2
ssh -i your-key.pem ubuntu@your-ec2-ip

# Stop CodePipeline container
sudo docker stop finbotaiagent-codepipeline
sudo docker rm finbotaiagent-codepipeline
```

### 2. Remove AWS Infrastructure
```bash
# Navigate to aws-cicd directory
cd /path/to/your/FinBotAiAgent/aws-cicd

# Destroy AWS infrastructure
terraform destroy
```

### 3. Verify GitHub Actions Still Works
```bash
# Test GitHub Actions deployment
curl http://your-ec2-ip:8080/weatherforecast
```

## 🔍 Troubleshooting

### Common Issues

#### 1. CodePipeline Fails to Deploy
```bash
# Check CodePipeline status
aws codepipeline get-pipeline-state --name finbotaiagent-prod-pipeline

# Check CodeBuild logs
aws logs tail /aws/codebuild/finbotaiagent-prod-deploy --follow
```

#### 2. Port 8081 Not Accessible
```bash
# Check security group rules
aws ec2 describe-security-groups --group-ids sg-your-security-group-id

# Add port 8081 rule if missing
aws ec2 authorize-security-group-ingress \
    --group-id sg-your-security-group-id \
    --protocol tcp \
    --port 8081 \
    --cidr 0.0.0.0/0
```

#### 3. Database Connection Issues
```bash
# Check SSM parameters
aws ssm get-parameter --name "/finbotaiagent/db/host"
aws ssm get-parameter --name "/finbotaiagent/db/username"
aws ssm get-parameter --name "/finbotaiagent/db/name"

# Check Secrets Manager
aws secretsmanager get-secret-value --secret-id "finbotaiagent/db/password"
```

#### 4. Container Not Starting
```bash
# SSH to EC2
ssh -i your-key.pem ubuntu@your-ec2-ip

# Check container logs
sudo docker logs finbotaiagent-codepipeline

# Check container status
sudo docker ps -a
```

## 📊 Migration Validation

### 1. Functional Testing
- [ ] GitHub Actions deployment works (port 8080)
- [ ] CodePipeline deployment works (port 8081)
- [ ] Both applications respond correctly
- [ ] Database connections work for both
- [ ] Health checks pass for both

### 2. Performance Testing
- [ ] Both deployments handle load
- [ ] Response times are acceptable
- [ ] Resource usage is within limits
- [ ] No conflicts between deployments

### 3. Monitoring Testing
- [ ] GitHub Actions logs are accessible
- [ ] CodePipeline logs are accessible
- [ ] CloudWatch metrics are working
- [ ] Alerts are configured correctly

## 🎉 Migration Complete!

After successful migration, you should have:

- **Two running applications** on the same EC2 instance
- **Port 8080**: GitHub Actions deployment (existing)
- **Port 8081**: CodePipeline deployment (new)
- **Zero additional cost** (within AWS Free Tier)
- **Independent monitoring** for both deployments

### Your Application URLs:
- GitHub Actions: `http://your-ec2-ip:8080`
- CodePipeline: `http://your-ec2-ip:8081`

## 📚 Next Steps

1. **Monitor both deployments** for a few days
2. **Compare performance** between the two methods
3. **Optimize configuration** based on monitoring data
4. **Consider gradual migration** to CodePipeline if preferred
5. **Update team procedures** and documentation

---

**Need help? Check the [DEPLOYMENT_README.md](./DEPLOYMENT_README.md) for detailed setup instructions or [EC2_DUAL_DEPLOYMENT_GUIDE.md](./EC2_DUAL_DEPLOYMENT_GUIDE.md) for technical reference.**