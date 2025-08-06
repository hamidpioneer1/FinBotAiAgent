#!/bin/bash

# Deploy script for FinBotAiAgent
# This script handles deployment with proper secret management

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if we're in CI/CD environment
if [ -n "$CI" ]; then
    print_status "Running in CI/CD environment"
    DEPLOYMENT_MODE="ci"
else
    print_status "Running in local environment"
    DEPLOYMENT_MODE="local"
fi

# Function to create .env file from environment variables
create_env_file() {
    print_status "Creating .env file..."
    
    cat > .env << EOF
# Database Configuration
DB_HOST=${DB_HOST:-localhost}
DB_USERNAME=${DB_USERNAME:-postgres}
DB_PASSWORD=${DB_PASSWORD:-password}
DB_NAME=${DB_NAME:-finbotdb}

# Application Configuration
ASPNETCORE_ENVIRONMENT=${ASPNETCORE_ENVIRONMENT:-Production}
ASPNETCORE_URLS=${ASPNETCORE_URLS:-http://+:8080}

# Performance Settings
ASPNETCORE_Kestrel__Limits__MaxConcurrentConnections=${ASPNETCORE_Kestrel__Limits__MaxConcurrentConnections:-100}
ASPNETCORE_Kestrel__Limits__MaxConcurrentUpgradedConnections=${ASPNETCORE_Kestrel__Limits__MaxConcurrentUpgradedConnections:-100}
EOF

    print_status ".env file created successfully"
}

# Function to validate environment variables
validate_environment() {
    print_status "Validating environment variables..."
    
    local required_vars=("DB_HOST" "DB_USERNAME" "DB_PASSWORD" "DB_NAME")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -ne 0 ]; then
        print_error "Missing required environment variables: ${missing_vars[*]}"
        print_warning "Please set these variables in your environment or GitHub Secrets"
        exit 1
    fi
    
    print_status "Environment validation passed"
}

# Function to deploy application
deploy_application() {
    print_status "Starting deployment..."
    
    # Stop existing containers
    print_status "Stopping existing containers..."
    docker-compose down || true
    
    # Remove old image
    print_status "Removing old Docker image..."
    docker rmi finbotaiagent:latest || true
    
    # Build and start containers
    print_status "Building and starting containers..."
    docker-compose build
    docker-compose up -d
    
    # Wait for health check
    print_status "Waiting for application to start..."
    sleep 30
    
    # Verify deployment
    print_status "Verifying deployment..."
    if curl -f http://localhost:8080/weatherforecast > /dev/null 2>&1; then
        print_status "Deployment successful! 🎉"
        print_status "Application is running at http://localhost:8080"
    else
        print_error "Deployment failed! ❌"
        print_status "Container logs:"
        docker-compose logs
        exit 1
    fi
}

# Function to show deployment status
show_status() {
    print_status "Deployment Status:"
    echo "=================="
    
    # Show container status
    docker-compose ps
    
    # Show environment info
    echo ""
    print_status "Environment Information:"
    echo "ASPNETCORE_ENVIRONMENT: ${ASPNETCORE_ENVIRONMENT:-Production}"
    echo "DB_HOST: ${DB_HOST:-localhost}"
    echo "DB_NAME: ${DB_NAME:-finbotdb}"
    
    # Show application health
    echo ""
    print_status "Application Health:"
    if curl -f http://localhost:8080/weatherforecast > /dev/null 2>&1; then
        echo "✅ Application is healthy"
    else
        echo "❌ Application is not responding"
    fi
}

# Main deployment logic
main() {
    print_status "FinBotAiAgent Deployment Script"
    echo "=================================="
    
    # Validate environment
    validate_environment
    
    # Create .env file
    create_env_file
    
    # Deploy application
    deploy_application
    
    # Show status
    show_status
    
    print_status "Deployment completed successfully!"
}

# Handle command line arguments
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "status")
        show_status
        ;;
    "validate")
        validate_environment
        ;;
    "help")
        echo "Usage: $0 [deploy|status|validate|help]"
        echo ""
        echo "Commands:"
        echo "  deploy   - Deploy the application (default)"
        echo "  status   - Show deployment status"
        echo "  validate - Validate environment variables"
        echo "  help     - Show this help message"
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac 