#!/bin/bash

# Deployment Orchestrator Script
# This script orchestrates the entire deployment process following best practices
# Handles database setup, application deployment, and verification

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Deployment Orchestrator${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
PROJECT_DIR="/home/ubuntu/finbotaiagent"
DEPLOYMENT_DIR="$PROJECT_DIR/deployment"
SCRIPTS_DIR="$DEPLOYMENT_DIR/scripts"
CONFIGS_DIR="$DEPLOYMENT_DIR/configs"
BACKUP_DIR="$PROJECT_DIR/backups"
LOG_DIR="$PROJECT_DIR/logs"

# Function to create necessary directories
create_directories() {
    print_info "Creating necessary directories..."
    
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$LOG_DIR"
    mkdir -p "$PROJECT_DIR/secrets"
    
    print_info "✅ Directories created"
}

# Function to set up database
setup_database() {
    print_info "Setting up database..."
    
    if [ -f "$CONFIGS_DIR/database-setup.sh" ]; then
        chmod +x "$CONFIGS_DIR/database-setup.sh"
        "$CONFIGS_DIR/database-setup.sh" setup
        print_info "✅ Database setup completed"
    else
        print_error "Database setup script not found"
        return 1
    fi
}

# Function to backup existing application
backup_existing() {
    print_info "Creating backup of existing application..."
    
    if [ -f "$SCRIPTS_DIR/container-manager.sh" ]; then
        chmod +x "$SCRIPTS_DIR/container-manager.sh"
        "$SCRIPTS_DIR/container-manager.sh" backup
        print_info "✅ Backup completed"
    else
        print_warning "Container manager script not found, skipping backup"
    fi
}

# Function to deploy application
deploy_application() {
    print_info "Deploying application..."
    
    cd "$PROJECT_DIR"
    
    # Create production docker-compose file
    if [ -f "$CONFIGS_DIR/docker-compose.production.yml" ]; then
        cp "$CONFIGS_DIR/docker-compose.production.yml" docker-compose.yml
        print_info "✅ Production docker-compose configuration applied"
    fi
    
    # Build and start application
    print_info "Building and starting application..."
    docker-compose build
    docker-compose up -d
    
    print_info "✅ Application deployed"
}

# Function to configure external key management
configure_key_management() {
    print_info "Configuring external key management..."
    
    # Create secrets directory in container
    docker exec finbotaiagent mkdir -p /app/secrets
    
    # Set up API key
    if [ -n "$API_KEY" ]; then
        echo "$API_KEY" | docker exec -i finbotaiagent tee /app/secrets/api-key.txt > /dev/null
        docker exec finbotaiagent chmod 600 /app/secrets/api-key.txt
        print_info "✅ API key configured"
    else
        print_warning "API_KEY not set, using fallback configuration"
    fi
    
    # Set up JWT secret
    if [ -n "$JWT_SECRET_KEY" ]; then
        echo "$JWT_SECRET_KEY" | docker exec -i finbotaiagent tee /app/secrets/jwt-secret.txt > /dev/null
        docker exec finbotaiagent chmod 600 /app/secrets/jwt-secret.txt
        print_info "✅ JWT secret configured"
    else
        print_warning "JWT_SECRET_KEY not set, using fallback configuration"
    fi
}

# Function to verify deployment
verify_deployment() {
    print_info "Verifying deployment..."
    
    # Wait for application to start
    print_info "Waiting for application to start..."
    sleep 30
    
    # Check container status
    if [ -f "$SCRIPTS_DIR/container-manager.sh" ]; then
        "$SCRIPTS_DIR/container-manager.sh" status
    fi
    
    # Test health endpoint
    print_info "Testing health endpoint..."
    if curl -f http://localhost:8080/health; then
        print_info "✅ Health check passed"
    else
        print_error "❌ Health check failed"
        return 1
    fi
    
    # Test API authentication
    if [ -n "$API_KEY" ]; then
        print_info "Testing API authentication..."
        if curl -f -H "X-API-Key: $API_KEY" http://localhost:8080/api/expenses; then
            print_info "✅ API authentication passed"
        else
            print_warning "⚠️ API authentication test failed"
        fi
    fi
    
    # Test OAuth token generation
    print_info "Testing OAuth token generation..."
    if curl -s -X POST http://localhost:8080/oauth/token \
      -H "Content-Type: application/json" \
      -d '{"grant_type":"client_credentials","client_id":"copilot-studio-client","client_secret":"copilot-studio-secret-12345","scope":"api.read api.write"}' \
      | grep -q "access_token"; then
        print_info "✅ OAuth token generation passed"
    else
        print_warning "⚠️ OAuth token generation test failed"
    fi
    
    print_info "✅ Deployment verification completed"
}

# Function to rollback deployment
rollback_deployment() {
    print_info "Rolling back deployment..."
    
    if [ -f "$SCRIPTS_DIR/container-manager.sh" ]; then
        # Stop current application
        "$SCRIPTS_DIR/container-manager.sh" stop
        
        # Restore from backup
        local latest_backup=$(ls -t "$BACKUP_DIR"/finbotaiagent_backup_*.tar.gz 2>/dev/null | head -1)
        if [ -n "$latest_backup" ]; then
            "$SCRIPTS_DIR/container-manager.sh" restore "$latest_backup"
            print_info "✅ Rollback completed"
        else
            print_error "No backup found for rollback"
            return 1
        fi
    else
        print_error "Container manager script not found"
        return 1
    fi
}

# Function to show deployment status
show_status() {
    print_header
    
    if [ -f "$SCRIPTS_DIR/container-manager.sh" ]; then
        "$SCRIPTS_DIR/container-manager.sh" status
    else
        print_error "Container manager script not found"
    fi
}

# Function to show deployment logs
show_logs() {
    local lines="${1:-50}"
    
    if [ -f "$SCRIPTS_DIR/container-manager.sh" ]; then
        "$SCRIPTS_DIR/container-manager.sh" logs "$lines"
    else
        print_error "Container manager script not found"
    fi
}

# Function to update application
update_application() {
    print_info "Updating application..."
    
    # Backup existing
    backup_existing
    
    # Deploy new version
    deploy_application
    
    # Configure key management
    configure_key_management
    
    # Verify deployment
    verify_deployment
    
    print_info "✅ Application update completed"
}

# Function to show help
show_help() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  deploy              Complete deployment (database + application)"
    echo "  deploy-app          Deploy application only"
    echo "  setup-database      Setup database only"
    echo "  update              Update existing application"
    echo "  rollback            Rollback to previous version"
    echo "  status              Show deployment status"
    echo "  logs [LINES]        Show deployment logs (default: 50 lines)"
    echo "  verify              Verify current deployment"
    echo "  help                Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  API_KEY             API key for authentication"
    echo "  JWT_SECRET_KEY      JWT secret key for OAuth"
    echo "  DB_USERNAME         Database username"
    echo "  DB_PASSWORD         Database password"
    echo "  DB_NAME             Database name"
    echo ""
    echo "Examples:"
    echo "  $0 deploy                    # Complete deployment"
    echo "  $0 deploy-app                # Deploy application only"
    echo "  $0 update                    # Update application"
    echo "  $0 logs 100                  # Show last 100 lines of logs"
}

# Main function
main() {
    local command="$1"
    local arg="$2"
    
    # Create necessary directories
    create_directories
    
    case "$command" in
        "deploy")
            print_header
            setup_database
            backup_existing
            deploy_application
            configure_key_management
            verify_deployment
            print_info "🎉 Complete deployment successful!"
            ;;
        "deploy-app")
            print_header
            backup_existing
            deploy_application
            configure_key_management
            verify_deployment
            print_info "🎉 Application deployment successful!"
            ;;
        "setup-database")
            print_header
            setup_database
            print_info "🎉 Database setup successful!"
            ;;
        "update")
            print_header
            update_application
            print_info "🎉 Application update successful!"
            ;;
        "rollback")
            print_header
            rollback_deployment
            print_info "🎉 Rollback successful!"
            ;;
        "status")
            show_status
            ;;
        "logs")
            print_header
            show_logs "$arg"
            ;;
        "verify")
            print_header
            verify_deployment
            print_info "🎉 Verification successful!"
            ;;
        "help"|"--help"|"-h"|"")
            show_help
            ;;
        *)
            print_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Check if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
