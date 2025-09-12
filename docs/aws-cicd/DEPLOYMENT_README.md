# FinBotAiAgent Dual Deployment Guide

**Deploy your .NET app using both GitHub Actions and AWS CodePipeline on the same EC2 instance**

## 🎯 What You'll Get

- **Two running copies** of your app on the same EC2 instance
- **Port 8080**: GitHub Actions deployment (existing)
- **Port 8081**: AWS CodePipeline deployment (new)
- **Zero additional cost** (stays within AWS Free Tier)

---

## 📋 Prerequisites Checklist

Before starting, ensure you have:

- [ ] AWS account (free tier eligible)
- [ ] GitHub account with your repository
- [ ] EC2 instance running (t2.micro recommended)
- [ ] Basic terminal/command line knowledge

---

## 🚀 Step-by-Step Deployment

### Step 1: Install Required Tools

**On your local machine:**

```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install Terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verify installations
aws --version
terraform --version
```

### Step 2: Configure AWS Access

```bash
# Configure AWS credentials
aws configure

# Enter when prompted:
# AWS Access Key ID: [Your access key]
# AWS Secret Access Key: [Your secret key]
# Default region name: us-east-1
# Default output format: json

# Test connection
aws sts get-caller-identity
```

### Step 3: Get Your EC2 Information

```bash
# Get your EC2 instance details
aws ec2 describe-instances --query 'Reservations[].Instances[?State.Name==`running`].[InstanceId,PublicIpAddress,KeyName,SecurityGroups[0].GroupId]' --output table
```

**Write down these values:**
- Instance ID (starts with `i-`)
- Public IP Address
- Key Name (your SSH key)
- Security Group ID (starts with `sg-`)

### Step 4: Prepare Your EC2 Instance

**SSH to your EC2 instance:**

```bash
# Replace with your actual values
ssh -i your-key.pem ubuntu@your-ec2-ip

# Install Docker
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

### Step 5: Configure Security Group

**Add port 8081 to your EC2 security group:**

```bash
# Replace sg-12345678 with your actual security group ID
aws ec2 authorize-security-group-ingress \
    --group-id sg-12345678 \
    --protocol tcp \
    --port 8081 \
    --cidr 0.0.0.0/0
```

### Step 6: Create GitHub Personal Access Token

1. Go to GitHub.com → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Select scopes: `repo`, `workflow`
4. Copy the token (starts with `ghp_`)

### Step 7: Run the Deployment Script

**Navigate to the aws-cicd folder:**

```bash
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

**The script will:**
- Create AWS infrastructure (ECR, CodeBuild, CodePipeline)
- Set up database parameters
- Configure everything automatically

### Step 8: Configure Database Parameters

**When prompted by the script, choose option 1 to configure database:**

```bash
# Enter your database details when prompted:
Database Host: localhost
Database Username: postgres
Database Name: finbotdb
Database Password: your_password_here
```

### Step 9: Deploy Your Application

**Push code to trigger both deployments:**

```bash
# In your project root
git add .
git commit -m "Deploy dual deployment setup"
git push origin main
```

**This will trigger:**
- GitHub Actions deployment (port 8080)
- AWS CodePipeline deployment (port 8081)

### Step 10: Verify Deployment

**Check both applications are running:**

```bash
# Test GitHub Actions deployment
curl http://your-ec2-ip:8080/weatherforecast

# Test CodePipeline deployment
curl http://your-ec2-ip:8081/weatherforecast
```

**Both should return JSON data if successful.**

---

## 🔍 Troubleshooting

### Problem: "AWS credentials not configured"
**Solution:**
```bash
aws configure
# Enter your AWS access key and secret key
```

### Problem: "Instance is not running"
**Solution:**
```bash
# Check instance status
aws ec2 describe-instances --instance-ids i-your-instance-id
# Start instance if stopped
aws ec2 start-instances --instance-ids i-your-instance-id
```

### Problem: "Port 8081 not accessible"
**Solution:**
```bash
# Check security group rules
aws ec2 describe-security-groups --group-ids sg-your-security-group-id
# Add port 8081 rule if missing
aws ec2 authorize-security-group-ingress --group-id sg-your-security-group-id --protocol tcp --port 8081 --cidr 0.0.0.0/0
```

### Problem: "Docker permission denied"
**Solution:**
```bash
# SSH to EC2 and run:
sudo usermod -aG docker $USER
# Logout and login again
```

### Problem: "CodePipeline failed"
**Solution:**
```bash
# Check CodePipeline status
aws codepipeline get-pipeline-state --name finbotaiagent-prod-pipeline
# Check CodeBuild logs
aws logs describe-log-groups --log-group-name-prefix "/aws/codebuild/finbotaiagent"
```

---

## 📊 Monitoring Your Deployments

### View Application Logs

```bash
# SSH to EC2
ssh -i your-key.pem ubuntu@your-ec2-ip

# View GitHub Actions container logs
sudo docker logs finbotaiagent

# View CodePipeline container logs
sudo docker logs finbotaiagent-codepipeline

# View all running containers
sudo docker ps
```

### Check Deployment Status

```bash
# GitHub Actions: Check Actions tab in your GitHub repository
# CodePipeline: Check AWS Console → CodePipeline
# Or use CLI:
aws codepipeline get-pipeline-state --name finbotaiagent-prod-pipeline
```

---

## 🎉 Success!

If everything worked correctly, you should have:

- **Two running applications** on your EC2 instance
- **Port 8080**: GitHub Actions deployment
- **Port 8081**: CodePipeline deployment
- **Both accessible** via your EC2 public IP

### Your Application URLs:
- GitHub Actions: `http://your-ec2-ip:8080`
- CodePipeline: `http://your-ec2-ip:8081`

---

## 💰 Cost

**Total monthly cost: $0** (within AWS Free Tier limits)

- EC2 t2.micro: 750 hours/month free
- ECR: 500 MB storage free
- CodeBuild: 100 build minutes/month free
- CodePipeline: 1 active pipeline free

---

## 🆘 Need Help?

1. **Check the logs** using the commands above
2. **Verify AWS credentials** are configured correctly
3. **Ensure EC2 instance** is running and accessible
4. **Check security group** allows ports 8080 and 8081
5. **Verify database** is running and accessible

---

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

**To restart deployments:**
```bash
# Start containers
sudo docker start finbotaiagent finbotaiagent-codepipeline
```

---

## 🧹 Cleanup (Optional)

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

---

**That's it! You now have a dual deployment setup running on AWS for free! 🎉**
