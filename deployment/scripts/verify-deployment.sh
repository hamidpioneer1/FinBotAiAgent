#!/bin/bash

# Deployment Verification Script
# This script verifies that the application is properly deployed and accessible

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Deployment Verification Script${NC}"
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

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to get EC2 IP
get_ec2_ip() {
    if [ -n "$EC2_HOST" ]; then
        echo "$EC2_HOST"
    else
        echo -n "Enter your EC2 public IP: "
        read -r ec2_ip
        echo "$ec2_ip"
    fi
}

# Function to verify local deployment
verify_local_deployment() {
    print_info "Verifying local deployment..."
    
    # Check if Docker is running
    if ! command_exists docker; then
        print_error "Docker is not installed"
        return 1
    fi
    
    # Check if containers are running
    if docker-compose ps | grep -q "finbotaiagent.*Up"; then
        print_success "Docker containers are running"
    else
        print_error "Docker containers are not running"
        return 1
    fi
    
    # Test local application
    if curl -f http://localhost:8080/weatherforecast >/dev/null 2>&1; then
        print_success "Application is responding on localhost:8080"
    else
        print_error "Application is not responding on localhost:8080"
        return 1
    fi
    
    # Test Swagger
    if curl -f http://localhost:8080/swagger >/dev/null 2>&1; then
        print_success "Swagger is accessible on localhost:8080/swagger"
    else
        print_warning "Swagger is not accessible on localhost:8080/swagger"
    fi
}

# Function to verify nginx configuration
verify_nginx() {
    print_info "Verifying nginx configuration..."
    
    # Check if nginx is installed
    if ! command_exists nginx; then
        print_error "Nginx is not installed"
        return 1
    fi
    
    # Check nginx status
    if sudo systemctl is-active --quiet nginx; then
        print_success "Nginx is running"
    else
        print_error "Nginx is not running"
        return 1
    fi
    
    # Test nginx configuration
    if sudo nginx -t >/dev/null 2>&1; then
        print_success "Nginx configuration is valid"
    else
        print_error "Nginx configuration is invalid"
        return 1
    fi
    
    # Test nginx proxy
    if curl -f http://localhost/weatherforecast >/dev/null 2>&1; then
        print_success "Nginx proxy is working (localhost)"
    else
        print_error "Nginx proxy is not working (localhost)"
        return 1
    fi
}

# Function to verify external access
verify_external_access() {
    local ec2_ip="$1"
    
    print_info "Verifying external access..."
    
    # Test application via EC2 IP
    if curl -f "http://$ec2_ip/weatherforecast" >/dev/null 2>&1; then
        print_success "Application is accessible via EC2 IP: http://$ec2_ip/weatherforecast"
    else
        print_error "Application is not accessible via EC2 IP"
        return 1
    fi
    
    # Test Swagger via EC2 IP
    if curl -f "http://$ec2_ip/swagger" >/dev/null 2>&1; then
        print_success "Swagger is accessible via EC2 IP: http://$ec2_ip/swagger"
    else
        print_warning "Swagger is not accessible via EC2 IP"
    fi
    
    # Test health endpoint
    if curl -f "http://$ec2_ip/health" >/dev/null 2>&1; then
        print_success "Health endpoint is accessible: http://$ec2_ip/health"
    else
        print_warning "Health endpoint is not accessible"
    fi
}

# Function to check security group
check_security_group() {
    print_info "Checking security group configuration..."
    
    echo "Make sure your EC2 security group allows:"
    echo "  - Port 22 (SSH)"
    echo "  - Port 80 (HTTP)"
    echo "  - Port 8080 (Application - optional, for direct access)"
    echo ""
    echo "You can check this in AWS Console → EC2 → Security Groups"
}

# Function to show useful URLs
show_urls() {
    local ec2_ip="$1"
    
    print_info "Useful URLs:"
    echo ""
    echo "🌐 Application:"
    echo "  - Main app: http://$ec2_ip/"
    echo "  - Weather forecast: http://$ec2_ip/weatherforecast"
    echo "  - Health check: http://$ec2_ip/health"
    echo ""
    echo "📚 API Documentation:"
    echo "  - Swagger UI: http://$ec2_ip/swagger"
    echo "  - OpenAPI spec: http://$ec2_ip/swagger/v1/swagger.json"
    echo ""
    echo "🔧 API Endpoints:"
    echo "  - GET /weatherforecast"
    echo "  - POST /api/expenses"
    echo "  - GET /api/expenses/{id}"
    echo "  - GET /api/policies"
}

# Function to run all verifications
run_verifications() {
    local ec2_ip="$1"
    
    print_header
    
    print_info "Starting deployment verification..."
    echo ""
    
    # Check if we're on EC2 or local
    if [ -f /etc/nginx/nginx.conf ] || command_exists nginx; then
        print_info "Running on EC2 instance"
        
        # Verify local deployment
        if verify_local_deployment; then
            print_success "Local deployment verification passed"
        else
            print_error "Local deployment verification failed"
            return 1
        fi
        
        # Verify nginx
        if verify_nginx; then
            print_success "Nginx verification passed"
        else
            print_error "Nginx verification failed"
            return 1
        fi
        
    else
        print_info "Running on local machine"
        
        # Verify external access
        if verify_external_access "$ec2_ip"; then
            print_success "External access verification passed"
        else
            print_error "External access verification failed"
            return 1
        fi
    fi
    
    # Show security group info
    check_security_group
    
    # Show useful URLs
    show_urls "$ec2_ip"
    
    echo ""
    print_success "Deployment verification completed!"
}

# Main execution
main() {
    local ec2_ip
    
    case "${1:-verify}" in
        "verify")
            ec2_ip=$(get_ec2_ip)
            run_verifications "$ec2_ip"
            ;;
        "local")
            verify_local_deployment
            ;;
        "nginx")
            verify_nginx
            ;;
        "external")
            ec2_ip=$(get_ec2_ip)
            verify_external_access "$ec2_ip"
            ;;
        "urls")
            ec2_ip=$(get_ec2_ip)
            show_urls "$ec2_ip"
            ;;
        "help")
            echo "Usage: $0 [verify|local|nginx|external|urls|help]"
            echo ""
            echo "Commands:"
            echo "  verify   - Run all verifications (default)"
            echo "  local    - Verify local deployment only"
            echo "  nginx    - Verify nginx configuration only"
            echo "  external - Verify external access only"
            echo "  urls     - Show useful URLs"
            echo "  help     - Show this help message"
            ;;
        *)
            print_error "Unknown command: $1"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Check if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 