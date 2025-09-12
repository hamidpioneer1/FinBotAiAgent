# FinBotAiAgent

**Dual deployment .NET web service with GitHub Actions and AWS CodePipeline**

A comprehensive .NET 9.0 web service that demonstrates dual deployment strategies using both GitHub Actions and AWS CodePipeline on the same EC2 instance, staying within AWS Free Tier limits.

## 🎯 Project Overview

This project showcases a modern .NET web service with:
- **Dual deployment** on the same EC2 instance
- **Port 8080**: GitHub Actions deployment
- **Port 8081**: AWS CodePipeline deployment
- **Zero additional cost** (within AWS Free Tier)
- **Comprehensive documentation** for all skill levels

## 🏗️ Project Structure

```
FinBotAiAgent/
├── 📁 src/                          # Source code
│   ├── Program.cs                   # Main application entry point
│   ├── Configuration/               # Configuration classes
│   │   ├── DatabaseSettings.cs
│   │   └── LoggingSettings.cs
│   ├── Services/                    # Application services
│   │   └── StructuredLoggingService.cs
│   └── Properties/
│       └── launchSettings.json
├── 📁 infrastructure/               # Infrastructure as Code
│   └── aws-cicd/                   # AWS CI/CD pipeline
│       ├── main.tf                 # Terraform main configuration
│       ├── variables.tf            # Terraform variables
│       ├── outputs.tf              # Terraform outputs
│       ├── terraform.tf            # Terraform provider config
│       ├── terraform.tfvars.example # Example variables
│       ├── buildspec.yml           # CodeBuild build spec
│       ├── buildspec-test.yml      # CodeBuild test spec
│       ├── buildspec-deploy.yml    # EC2 deployment spec
│       ├── setup-dual-deployment.sh # Automated setup script
│       └── iam-policies.json       # IAM policies reference
├── 📁 deployment/                   # Deployment configurations
│   ├── docker/                     # Docker configurations
│   │   ├── Dockerfile
│   │   ├── docker-compose.yml
│   │   └── nginx.conf
│   └── scripts/                    # Deployment scripts
│       ├── deploy.sh
│       ├── setup-github-secrets.sh
│       ├── verify-deployment.sh
│       └── verify-network.sh
├── 📁 config/                      # Configuration files
│   ├── appsettings.json
│   ├── appsettings.Development.json
│   ├── appsettings.Production.json
│   └── env.example
├── 📁 docs/                        # Documentation
│   ├── aws-cicd/                   # AWS CI/CD documentation
│   │   ├── README.md               # Main entry point
│   │   ├── DEPLOYMENT_README.md    # Beginner's guide
│   │   ├── EC2_DUAL_DEPLOYMENT_GUIDE.md # Technical reference
│   │   ├── BEST_PRACTICES.md       # DevOps best practices
│   │   ├── MIGRATION_GUIDE.md      # Migration guide
│   │   └── DOCUMENTATION_STRUCTURE.md # Doc overview
│   ├── deployment/                 # Deployment documentation
│   │   ├── GITHUB_SECRETS_SETUP.md
│   │   ├── PRODUCTION_DEPLOYMENT_GUIDE.md
│   │   ├── SECURITY_SETUP.md
│   │   └── SECURITY_SUMMARY.md
│   └── scripts/                    # Script documentation
├── 📁 logs/                        # Application logs
├── 📄 FinBotAiAgent.csproj         # .NET project file
├── 📄 FinBotAiAgent.sln            # Visual Studio solution
├── 📄 FinBotAiAgent.http           # HTTP test file
└── 📄 README.md                    # This file
```

## 🚀 Quick Start

### For Beginners (Zero AWS Knowledge)
👉 **[docs/aws-cicd/DEPLOYMENT_README.md](docs/aws-cicd/DEPLOYMENT_README.md)** - Complete step-by-step guide

### For Experienced Developers
```bash
# 1. Get your EC2 information
aws ec2 describe-instances --query 'Reservations[].Instances[?State.Name==`running`].[InstanceId,PublicIpAddress,KeyName,SecurityGroups[0].GroupId]' --output table

# 2. Run the setup script
./infrastructure/aws-cicd/setup-dual-deployment.sh \
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

## 📊 Deployment Architecture

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

1. **[docs/aws-cicd/DEPLOYMENT_README.md](docs/aws-cicd/DEPLOYMENT_README.md)** - Complete beginner's guide
   - Zero AWS knowledge required
   - Step-by-step instructions
   - Troubleshooting section
   - Copy-paste commands

2. **[docs/aws-cicd/EC2_DUAL_DEPLOYMENT_GUIDE.md](docs/aws-cicd/EC2_DUAL_DEPLOYMENT_GUIDE.md)** - Technical reference
   - Detailed configuration options
   - Advanced troubleshooting
   - Architecture deep-dive
   - Best practices

3. **[docs/aws-cicd/BEST_PRACTICES.md](docs/aws-cicd/BEST_PRACTICES.md)** - DevOps best practices
   - Security recommendations
   - Monitoring setup
   - Cost optimization
   - Maintenance procedures

4. **[docs/aws-cicd/MIGRATION_GUIDE.md](docs/aws-cicd/MIGRATION_GUIDE.md)** - Migration from GitHub Actions
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

## 🛠️ Development

### Local Development
```bash
# Restore dependencies
dotnet restore

# Build application
dotnet build

# Run application
dotnet run

# Run tests
dotnet test
```

### Docker Development
```bash
# Build Docker image
docker build -t finbotaiagent .

# Run container
docker run -p 8080:8080 finbotaiagent
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
./infrastructure/aws-cicd/setup-dual-deployment.sh -t v1.2.3

# Deploy to different environment
./infrastructure/aws-cicd/setup-dual-deployment.sh -e staging
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
cd infrastructure/aws-cicd
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

**Ready to deploy? Start with [docs/aws-cicd/DEPLOYMENT_README.md](docs/aws-cicd/DEPLOYMENT_README.md) for a complete step-by-step guide! 🚀**
