#!/bin/bash

# Dual Deployment Setup Script for FinBotAiAgent
# This script sets up both GitHub Actions (EC2) and AWS CodePipeline (ECS) deployments

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# Default values
PROJECT_NAME="finbotaiagent"
ENVIRONMENT="prod"
AWS_REGION="us-east-1"
GITHUB_OWNER=""
GITHUB_REPO="FinBotAiAgent"
GITHUB_BRANCH="main"
GITHUB_TOKEN=""
EC2_INSTANCE_ID=""
EC2_SSH_KEY_NAME=""
EC2_SECURITY_GROUP_ID=""

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -p, --project PROJECT_NAME     Project name (default: $PROJECT_NAME)"
    echo "  -e, --environment ENV          Environment (default: $ENVIRONMENT)"
    echo "  -r, --region REGION           AWS region (default: $AWS_REGION)"
    echo "  -o, --github-owner OWNER       GitHub repository owner (required)"
    echo "  -n, --github-repo REPO         GitHub repository name (default: $GITHUB_REPO)"
    echo "  -b, --github-branch BRANCH     GitHub branch (default: $GITHUB_BRANCH)"
    echo "  -t, --github-token TOKEN       GitHub personal access token (required)"
    echo "  --ec2-instance-id ID          EC2 instance ID for deployment (required)"
    echo "  --ec2-ssh-key-name KEY        EC2 SSH key pair name (required)"
    echo "  --ec2-security-group-id SG    EC2 security group ID (required)"
    echo "  --skip-terraform              Skip Terraform deployment"
    echo "  --skip-database-setup         Skip database parameter setup"
    echo "  -h, --help                    Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  AWS_PROFILE                   AWS profile to use"
    echo "  AWS_REGION                    AWS region (overrides -r option)"
    echo "  GITHUB_TOKEN                  GitHub token (overrides -t option)"
    echo ""
    echo "Examples:"
    echo "  $0 -o myusername -t ghp_xxxxxxxxxxxx"
    echo "  $0 -o myusername -t ghp_xxxxxxxxxxxx --vpc-id vpc-12345678"
    echo "  $0 -o myusername -t ghp_xxxxxxxxxxxx --skip-terraform"
}

# Parse command line arguments
SKIP_TERRAFORM=false
SKIP_DATABASE_SETUP=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--project)
            PROJECT_NAME="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -r|--region)
            AWS_REGION="$2"
            shift 2
            ;;
        -o|--github-owner)
            GITHUB_OWNER="$2"
            shift 2
            ;;
        -n|--github-repo)
            GITHUB_REPO="$2"
            shift 2
            ;;
        -b|--github-branch)
            GITHUB_BRANCH="$2"
            shift 2
            ;;
        -t|--github-token)
            GITHUB_TOKEN="$2"
            shift 2
            ;;
        --ec2-instance-id)
            EC2_INSTANCE_ID="$2"
            shift 2
            ;;
        --ec2-ssh-key-name)
            EC2_SSH_KEY_NAME="$2"
            shift 2
            ;;
        --ec2-security-group-id)
            EC2_SECURITY_GROUP_ID="$2"
            shift 2
            ;;
        --skip-terraform)
            SKIP_TERRAFORM=true
            shift
            ;;
        --skip-database-setup)
            SKIP_DATABASE_SETUP=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Use environment variables if set
if [ -n "$AWS_REGION" ]; then
    AWS_REGION="$AWS_REGION"
fi
if [ -n "$GITHUB_TOKEN" ]; then
    GITHUB_TOKEN="$GITHUB_TOKEN"
fi

# Validate required parameters
if [ -z "$GITHUB_OWNER" ]; then
    print_error "GitHub owner is required. Use -o or --github-owner"
    exit 1
fi

if [ -z "$GITHUB_TOKEN" ]; then
    print_error "GitHub token is required. Use -t or --github-token"
    exit 1
fi

if [ -z "$EC2_INSTANCE_ID" ]; then
    print_error "EC2 instance ID is required. Use --ec2-instance-id"
    exit 1
fi

if [ -z "$EC2_SSH_KEY_NAME" ]; then
    print_error "EC2 SSH key name is required. Use --ec2-ssh-key-name"
    exit 1
fi

if [ -z "$EC2_SECURITY_GROUP_ID" ]; then
    print_error "EC2 security group ID is required. Use --ec2-security-group-id"
    exit 1
fi

print_status "FinBotAiAgent Dual Deployment Setup"
echo "=========================================="
print_debug "Project: $PROJECT_NAME"
print_debug "Environment: $ENVIRONMENT"
print_debug "AWS Region: $AWS_REGION"
print_debug "GitHub Owner: $GITHUB_OWNER"
print_debug "GitHub Repo: $GITHUB_REPO"
print_debug "GitHub Branch: $GITHUB_BRANCH"
print_debug "EC2 Instance ID: $EC2_INSTANCE_ID"
print_debug "EC2 SSH Key: $EC2_SSH_KEY_NAME"
print_debug "EC2 Security Group: $EC2_SECURITY_GROUP_ID"
print_debug "Skip Terraform: $SKIP_TERRAFORM"
print_debug "Skip Database Setup: $SKIP_DATABASE_SETUP"
echo ""

# Function to check if AWS CLI is installed and configured
check_aws_cli() {
    print_status "Checking AWS CLI..."
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity --region "$AWS_REGION" &> /dev/null; then
        print_error "AWS credentials not configured or invalid."
        print_warning "Please run 'aws configure' or set AWS_PROFILE environment variable."
        exit 1
    fi
    
    print_status "AWS CLI is configured correctly"
}

# Function to check if Terraform is installed
check_terraform() {
    if [ "$SKIP_TERRAFORM" = true ]; then
        return
    fi
    
    print_status "Checking Terraform..."
    
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    print_status "Terraform is available"
}

# Function to check if required tools are installed
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check for required tools
    local missing_tools=()
    
    if ! command -v jq &> /dev/null; then
        missing_tools+=("jq")
    fi
    
    if ! command -v curl &> /dev/null; then
        missing_tools+=("curl")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_warning "Please install the missing tools and run the script again."
        exit 1
    fi
    
    print_status "All prerequisites are met"
}

# Function to create terraform.tfvars file
create_terraform_vars() {
    if [ "$SKIP_TERRAFORM" = true ]; then
        return
    fi
    
    print_status "Creating terraform.tfvars file..."
    
    local tfvars_file="terraform.tfvars"
    
    cat > "$tfvars_file" << EOF
# AWS Configuration
aws_region = "$AWS_REGION"

# Project Configuration
project_name = "$PROJECT_NAME"
environment  = "$ENVIRONMENT"

# GitHub Configuration
github_owner = "$GITHUB_OWNER"
github_repo  = "$GITHUB_REPO"
github_branch = "$GITHUB_BRANCH"
github_token = "$GITHUB_TOKEN"

# EC2 Configuration for CodePipeline Deployment
ec2_instance_id = "$EC2_INSTANCE_ID"
ec2_ssh_key_name = "$EC2_SSH_KEY_NAME"
ec2_security_group_id = "$EC2_SECURITY_GROUP_ID"
EOF
    
    print_status "Created $tfvars_file"
}

# Function to deploy Terraform infrastructure
deploy_terraform() {
    if [ "$SKIP_TERRAFORM" = true ]; then
        print_warning "Skipping Terraform deployment"
        return
    fi
    
    print_status "Deploying Terraform infrastructure..."
    
    # Initialize Terraform
    print_debug "Initializing Terraform..."
    terraform init
    
    # Plan Terraform deployment
    print_debug "Planning Terraform deployment..."
    terraform plan -out=tfplan
    
    # Apply Terraform deployment
    print_debug "Applying Terraform deployment..."
    terraform apply tfplan
    
    print_status "Terraform deployment completed"
}

# Function to setup database parameters
setup_database_parameters() {
    if [ "$SKIP_DATABASE_SETUP" = true ]; then
        print_warning "Skipping database parameter setup"
        return
    fi
    
    print_status "Setting up database parameters..."
    
    # Get account ID
    local account_id=$(aws sts get-caller-identity --query Account --output text)
    
    # Create SSM parameters
    print_debug "Creating SSM parameters..."
    
    # Check if parameters already exist
    local db_host_exists=$(aws ssm get-parameter --name "/$PROJECT_NAME/db/host" --region "$AWS_REGION" 2>/dev/null || echo "not found")
    local db_username_exists=$(aws ssm get-parameter --name "/$PROJECT_NAME/db/username" --region "$AWS_REGION" 2>/dev/null || echo "not found")
    local db_name_exists=$(aws ssm get-parameter --name "/$PROJECT_NAME/db/name" --region "$AWS_REGION" 2>/dev/null || echo "not found")
    
    if [ "$db_host_exists" != "not found" ] && [ "$db_username_exists" != "not found" ] && [ "$db_name_exists" != "not found" ]; then
        print_warning "Database parameters already exist. Skipping creation."
        return
    fi
    
    # Prompt for database configuration
    echo ""
    print_warning "Database configuration required for the application to work properly."
    echo "You can either:"
    echo "1. Provide database details now"
    echo "2. Skip and configure later"
    echo ""
    read -p "Do you want to configure database now? (y/N): " configure_db
    
    if [[ $configure_db =~ ^[Yy]$ ]]; then
        read -p "Database Host: " db_host
        read -p "Database Username: " db_username
        read -p "Database Name: " db_name
        read -s -p "Database Password: " db_password
        echo ""
        
        # Create SSM parameters
        aws ssm put-parameter --name "/$PROJECT_NAME/db/host" --value "$db_host" --type "String" --region "$AWS_REGION" --overwrite
        aws ssm put-parameter --name "/$PROJECT_NAME/db/username" --value "$db_username" --type "String" --region "$AWS_REGION" --overwrite
        aws ssm put-parameter --name "/$PROJECT_NAME/db/name" --value "$db_name" --type "String" --region "$AWS_REGION" --overwrite
        
        # Create Secrets Manager secret
        aws secretsmanager create-secret \
            --name "$PROJECT_NAME/db/password" \
            --description "Database password for $PROJECT_NAME" \
            --secret-string "$db_password" \
            --region "$AWS_REGION" \
            --overwrite
        
        print_status "Database parameters created successfully"
    else
        print_warning "Skipping database configuration. You'll need to set these up manually:"
        echo "  - /$PROJECT_NAME/db/host"
        echo "  - /$PROJECT_NAME/db/username"
        echo "  - /$PROJECT_NAME/db/name"
        echo "  - $PROJECT_NAME/db/password (in Secrets Manager)"
    fi
}

# Function to display deployment information
display_deployment_info() {
    print_status "Deployment Information"
    echo "========================"
    
    if [ "$SKIP_TERRAFORM" = false ]; then
        # Get Terraform outputs
        local ecr_url=$(terraform output -raw ecr_repository_url 2>/dev/null || echo "Not available")
        local pipeline_name=$(terraform output -raw pipeline_name 2>/dev/null || echo "Not available")
        local ec2_role=$(terraform output -raw ec2_deployment_role_arn 2>/dev/null || echo "Not available")
        
        echo "ECR Repository URL: $ecr_url"
        echo "CodePipeline Name: $pipeline_name"
        echo "EC2 Deployment Role: $ec2_role"
        echo ""
    fi
    
    # Get EC2 instance public IP
    local instance_ip=$(aws ec2 describe-instances --instance-ids $EC2_INSTANCE_ID --region $AWS_REGION --query 'Reservations[0].Instances[0].PublicIpAddress' --output text 2>/dev/null || echo "Unknown")
    
    echo "Deployment Methods Available:"
    echo "1. GitHub Actions → EC2 Port 8080 (existing)"
    echo "2. AWS CodePipeline → EC2 Port 8081 (new)"
    echo ""
    echo "Application Endpoints:"
    echo "  - GitHub Actions: http://$instance_ip:8080"
    echo "  - CodePipeline: http://$instance_ip:8081"
    echo ""
    echo "Next Steps:"
    echo "1. Push code to GitHub to trigger both deployments"
    echo "2. Monitor CodePipeline in AWS Console"
    echo "3. Access both application versions via different ports"
    echo ""
    echo "Useful Commands:"
    echo "  - View CodePipeline: aws codepipeline get-pipeline --name $PROJECT_NAME-prod-pipeline --region $AWS_REGION"
    echo "  - View ECR images: aws ecr list-images --repository-name $PROJECT_NAME-prod --region $AWS_REGION"
    echo "  - View EC2 instance: aws ec2 describe-instances --instance-ids $EC2_INSTANCE_ID --region $AWS_REGION"
}

# Main function
main() {
    print_status "Starting dual deployment setup..."
    
    # Pre-flight checks
    check_prerequisites
    check_aws_cli
    check_terraform
    
    # Create configuration
    create_terraform_vars
    
    # Deploy infrastructure
    deploy_terraform
    
    # Setup database
    setup_database_parameters
    
    # Display information
    display_deployment_info
    
    print_status "Dual deployment setup completed successfully! 🎉"
    echo ""
    print_warning "Remember:"
    echo "- Your existing GitHub Actions deployment to EC2 will continue to work"
    echo "- The new CodePipeline deployment to ECS will start automatically on code push"
    echo "- Both deployments can run simultaneously with different configurations"
}

# Run main function
main "$@"
