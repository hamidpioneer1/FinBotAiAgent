# FinBotAiAgent AWS CI/CD Pipeline

**Dual deployment setup using GitHub Actions and AWS CodePipeline on EC2**

This directory contains the complete AWS CI/CD pipeline implementation that deploys your .NET application using two methods simultaneously on the same EC2 instance, staying within AWS Free Tier limits.

## 🎯 What You Get

- **Two running applications** on the same EC2 instance
- **Port 8080**: GitHub Actions deployment (existing)
- **Port 8081**: AWS CodePipeline deployment (new)
- **Zero additional cost** (within AWS Free Tier)
- **Side-by-side comparison** of deployment methods

## 🏗️ Architecture

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

## 📁 Directory Structure

```
aws-cicd/
├── README.md                    # This file
├── DEPLOYMENT_README.md         # Step-by-step deployment guide
├── EC2_DUAL_DEPLOYMENT_GUIDE.md # Detailed technical guide
├── BEST_PRACTICES.md            # DevOps best practices
├── MIGRATION_GUIDE.md           # Migration from GitHub Actions
├── main.tf                      # Terraform main configuration
├── variables.tf                 # Terraform variables
├── outputs.tf                   # Terraform outputs
├── terraform.tf                 # Terraform provider configuration
├── terraform.tfvars.example     # Example Terraform variables
├── buildspec.yml                # CodeBuild build specification
├── buildspec-test.yml           # CodeBuild test specification
├── buildspec-deploy.yml         # EC2 deployment specification
├── setup-dual-deployment.sh     # Automated setup script
└── iam-policies.json            # IAM policies reference
```

## 🚀 Quick Start

### For Beginners (Zero AWS Knowledge)
👉 **[DEPLOYMENT_README.md](./DEPLOYMENT_README.md)** - Complete step-by-step guide

### For Experienced Developers
```bash
# 1. Get your EC2 information
aws ec2 describe-instances --query 'Reservations[].Instances[?State.Name==`running`].[InstanceId,PublicIpAddress,KeyName,SecurityGroups[0].GroupId]' --output table

# 2. Run the setup script
./setup-dual-deployment.sh \
  -o your-github-username \
  -t your-github-token \
  --ec2-instance-id i-1234567890abcdef0 \
  --ec2-ssh-key-name your-key-pair \
  --ec2-security-group-id sg-12345678

# 3. Push code to trigger deployments
git add .
git commit -m "Deploy dual deployment setup"
git push origin main
```

## 📊 Deployment Methods Comparison

| Feature | GitHub Actions → EC2:8080 | AWS CodePipeline → EC2:8081 |
|---------|---------------------------|------------------------------|
| **Infrastructure** | Same EC2 instance | Same EC2 instance |
| **Port** | 8080 | 8081 |
| **Folder** | `/home/ubuntu/finbotaiagent` | `/home/ubuntu/finbotaiagent-codepipeline` |
| **Container Name** | `finbotaiagent` | `finbotaiagent-codepipeline` |
| **Cost** | Free (within limits) | Free (within limits) |
| **Monitoring** | GitHub Actions logs | CloudWatch + CodeBuild logs |
| **Deployment Trigger** | Git push to main | Git push to main |

## 💰 Cost Analysis

**Total monthly cost: $0** (within AWS Free Tier limits)

| Service | Free Tier Limit | Usage | Cost |
|---------|----------------|-------|------|
| **EC2 t2.micro** | 750 hours/month | ~24 hours/day | **$0** |
| **ECR** | 500 MB storage | ~100 MB per image | **$0** |
| **CodeBuild** | 100 build minutes/month | ~5 minutes per build | **$0** |
| **CodePipeline** | 1 active pipeline | 1 pipeline | **$0** |
| **S3** | 5 GB storage | ~1 GB for artifacts | **$0** |

## 🔧 Prerequisites

- AWS account (free tier eligible)
- GitHub account with repository access
- EC2 instance running (t2.micro recommended)
- AWS CLI, Terraform, and Docker installed
- Basic terminal/command line knowledge

## 📚 Documentation

### For Different Audiences

1. **[DEPLOYMENT_README.md](./DEPLOYMENT_README.md)** - Complete beginner's guide
   - Zero AWS knowledge required
   - Step-by-step instructions
   - Troubleshooting section
   - Copy-paste commands

2. **[EC2_DUAL_DEPLOYMENT_GUIDE.md](./EC2_DUAL_DEPLOYMENT_GUIDE.md)** - Technical reference
   - Detailed configuration options
   - Advanced troubleshooting
   - Architecture deep-dive
   - Best practices

3. **[BEST_PRACTICES.md](./BEST_PRACTICES.md)** - DevOps best practices
   - Security recommendations
   - Monitoring setup
   - Cost optimization
   - Maintenance procedures

4. **[MIGRATION_GUIDE.md](./MIGRATION_GUIDE.md)** - Migration from GitHub Actions
   - Step-by-step migration
   - Rollback procedures
   - Testing strategies

## 🔍 Monitoring & Troubleshooting

### View Application Status
```bash
# Test both deployments
curl http://your-ec2-ip:8080/weatherforecast  # GitHub Actions
curl http://your-ec2-ip:8081/weatherforecast  # CodePipeline
```

### View Logs
```bash
# SSH to EC2
ssh -i your-key.pem ubuntu@your-ec2-ip

# View container logs
sudo docker logs finbotaiagent              # GitHub Actions
sudo docker logs finbotaiagent-codepipeline # CodePipeline
```

### Check Pipeline Status
```bash
# CodePipeline status
aws codepipeline get-pipeline-state --name finbotaiagent-prod-pipeline

# CodeBuild logs
aws logs describe-log-groups --log-group-name-prefix "/aws/codebuild/finbotaiagent"
```

## 🛠️ Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `AWS_REGION` | AWS region | `us-east-1` |
| `PROJECT_NAME` | Project name | `finbotaiagent` |
| `ENVIRONMENT` | Environment | `prod` |
| `GITHUB_OWNER` | GitHub username/org | Required |
| `GITHUB_REPO` | Repository name | `FinBotAiAgent` |
| `GITHUB_BRANCH` | Branch to monitor | `main` |
| `GITHUB_TOKEN` | Personal access token | Required |
| `EC2_INSTANCE_ID` | EC2 instance ID | Required |
| `EC2_SSH_KEY_NAME` | SSH key pair name | Required |
| `EC2_SECURITY_GROUP_ID` | Security group ID | Required |

### Terraform Variables

Create `terraform.tfvars`:

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

# EC2 Configuration
ec2_instance_id = "i-1234567890abcdef0"
ec2_ssh_key_name = "your-key-pair-name"
ec2_security_group_id = "sg-12345678"
```

## 🔒 Security Features

- **IAM Roles**: Least privilege access
- **Secrets Management**: AWS Secrets Manager + SSM Parameter Store
- **Network Security**: Security groups with minimal required ports
- **Encryption**: All secrets encrypted at rest
- **Audit Logging**: CloudTrail integration

## 🚀 Deployment Options

### 1. Automatic Deployment
- Triggered by code push to main branch
- Both deployments run simultaneously
- Independent container management

### 2. Manual Deployment
```bash
# Deploy specific image tag
./setup-dual-deployment.sh -t v1.2.3

# Deploy to different environment
./setup-dual-deployment.sh -e staging
```

### 3. Blue/Green Deployment
- Use different ports for zero-downtime deployments
- Test new version on port 8082
- Switch traffic when ready

## 🔄 Making Changes

**To update your application:**

1. Make code changes
2. Commit and push to GitHub:
   ```bash
   git add .
   git commit -m "Update application"
   git push origin main
   ```
3. Both deployments will automatically update

**To stop deployments:**
```bash
# SSH to EC2
ssh -i your-key.pem ubuntu@your-ec2-ip

# Stop containers
sudo docker stop finbotaiagent finbotaiagent-codepipeline
```

## 🧹 Cleanup

**To remove everything:**

```bash
# Destroy AWS infrastructure
cd aws-cicd
terraform destroy

# Stop containers on EC2
ssh -i your-key.pem ubuntu@your-ec2-ip
sudo docker stop finbotaiagent finbotaiagent-codepipeline
sudo docker rm finbotaiagent finbotaiagent-codepipeline
```

## 🆘 Support

1. **Check the logs** using the commands above
2. **Verify AWS credentials** are configured correctly
3. **Ensure EC2 instance** is running and accessible
4. **Check security group** allows ports 8080 and 8081
5. **Verify database** is running and accessible

## 📈 Next Steps

1. **Set up monitoring**: Configure CloudWatch alarms and dashboards
2. **Implement CI/CD**: Add automated testing and quality gates
3. **Add security scanning**: Integrate vulnerability scanning
4. **Optimize performance**: Monitor resource usage
5. **Add load balancing**: Implement reverse proxy for traffic distribution

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the pipeline
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Ready to deploy? Start with [DEPLOYMENT_README.md](./DEPLOYMENT_README.md) for a complete step-by-step guide! 🚀**