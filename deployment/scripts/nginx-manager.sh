#!/bin/bash

# Nginx Manager for FinBotAiAgent Dual Deployment
# Manages nginx load balancer and both services

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILE="deployment/docker/docker-compose-nginx.yml"
NGINX_CONF="deployment/docker/nginx.conf"
LOG_DIR="logs/nginx"

# Functions
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  FinBotAiAgent Nginx Manager${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
}

# Check if nginx configuration is valid
validate_nginx_config() {
    print_info "Validating nginx configuration..."
    if docker run --rm -v "$(pwd)/$NGINX_CONF:/etc/nginx/conf.d/default.conf" nginx:alpine nginx -t; then
        print_success "Nginx configuration is valid"
    else
        print_error "Nginx configuration is invalid"
        exit 1
    fi
}

# Create necessary directories
setup_directories() {
    print_info "Setting up directories..."
    mkdir -p "$LOG_DIR"
    print_success "Directories created"
}

# Start all services
start_services() {
    print_info "Starting all services..."
    docker-compose -f "$COMPOSE_FILE" up -d
    print_success "All services started"
}

# Stop all services
stop_services() {
    print_info "Stopping all services..."
    docker-compose -f "$COMPOSE_FILE" down
    print_success "All services stopped"
}

# Restart all services
restart_services() {
    print_info "Restarting all services..."
    docker-compose -f "$COMPOSE_FILE" restart
    print_success "All services restarted"
}

# Show status of all services
show_status() {
    print_info "Service Status:"
    echo ""
    
    # Check nginx
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "finbotaiagent-nginx"; then
        print_success "Nginx Load Balancer: Running"
    else
        print_error "Nginx Load Balancer: Not running"
    fi
    
    # Check GitHub Actions service
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "finbotaiagent-github"; then
        print_success "GitHub Actions Service (8080): Running"
    else
        print_error "GitHub Actions Service (8080): Not running"
    fi
    
    # Check CodePipeline service
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "finbotaiagent-codepipeline"; then
        print_success "CodePipeline Service (8081): Running"
    else
        print_error "CodePipeline Service (8081): Not running"
    fi
    
    # Check PostgreSQL
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "finbotaiagent-postgres"; then
        print_success "PostgreSQL Database: Running"
    else
        print_error "PostgreSQL Database: Not running"
    fi
    
    echo ""
    print_info "Service URLs:"
    echo "  🌐 Main Application: http://localhost"
    echo "  🔧 GitHub Actions: http://localhost:8080"
    echo "  🚀 CodePipeline: http://localhost:8081"
    echo "  📊 Status Page: http://localhost/status"
    echo "  🏥 Health Check: http://localhost/health"
    echo "  📚 API Docs: http://localhost/swagger"
}

# Test all endpoints
test_endpoints() {
    print_info "Testing endpoints..."
    
    # Test main application
    if curl -s -f http://localhost/health > /dev/null; then
        print_success "Main application (load balanced): OK"
    else
        print_error "Main application (load balanced): FAILED"
    fi
    
    # Test GitHub Actions service
    if curl -s -f http://localhost:8080/weatherforecast > /dev/null; then
        print_success "GitHub Actions service (8080): OK"
    else
        print_error "GitHub Actions service (8080): FAILED"
    fi
    
    # Test CodePipeline service
    if curl -s -f http://localhost:8081/weatherforecast > /dev/null; then
        print_success "CodePipeline service (8081): OK"
    else
        print_error "CodePipeline service (8081): FAILED"
    fi
    
    # Test nginx status
    if curl -s -f http://localhost/status > /dev/null; then
        print_success "Nginx status page: OK"
    else
        print_error "Nginx status page: FAILED"
    fi
}

# Show logs
show_logs() {
    local service=${1:-"all"}
    
    case $service in
        "nginx")
            print_info "Showing nginx logs..."
            docker-compose -f "$COMPOSE_FILE" logs -f nginx
            ;;
        "github")
            print_info "Showing GitHub Actions service logs..."
            docker-compose -f "$COMPOSE_FILE" logs -f finbotaiagent-github
            ;;
        "codepipeline")
            print_info "Showing CodePipeline service logs..."
            docker-compose -f "$COMPOSE_FILE" logs -f finbotaiagent-codepipeline
            ;;
        "postgres")
            print_info "Showing PostgreSQL logs..."
            docker-compose -f "$COMPOSE_FILE" logs -f postgres
            ;;
        "all")
            print_info "Showing all service logs..."
            docker-compose -f "$COMPOSE_FILE" logs -f
            ;;
        *)
            print_error "Unknown service: $service"
            echo "Available services: nginx, github, codepipeline, postgres, all"
            exit 1
            ;;
    esac
}

# Update nginx configuration
update_nginx() {
    print_info "Updating nginx configuration..."
    validate_nginx_config
    docker-compose -f "$COMPOSE_FILE" restart nginx
    print_success "Nginx configuration updated"
}

# Monitor services
monitor_services() {
    print_info "Monitoring services (Press Ctrl+C to stop)..."
    while true; do
        clear
        print_header
        show_status
        echo ""
        print_info "Monitoring... (Press Ctrl+C to stop)"
        sleep 5
    done
}

# Show help
show_help() {
    print_header
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start       Start all services"
    echo "  stop        Stop all services"
    echo "  restart     Restart all services"
    echo "  status      Show status of all services"
    echo "  test        Test all endpoints"
    echo "  logs [service] Show logs (nginx|github|codepipeline|postgres|all)"
    echo "  update      Update nginx configuration"
    echo "  monitor     Monitor services in real-time"
    echo "  validate    Validate nginx configuration"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 logs nginx"
    echo "  $0 test"
    echo "  $0 monitor"
}

# Main script
main() {
    print_header
    
    case ${1:-"help"} in
        "start")
            check_docker
            setup_directories
            validate_nginx_config
            start_services
            show_status
            ;;
        "stop")
            check_docker
            stop_services
            ;;
        "restart")
            check_docker
            restart_services
            show_status
            ;;
        "status")
            show_status
            ;;
        "test")
            test_endpoints
            ;;
        "logs")
            check_docker
            show_logs "$2"
            ;;
        "update")
            check_docker
            update_nginx
            ;;
        "monitor")
            check_docker
            monitor_services
            ;;
        "validate")
            validate_nginx_config
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Run main function
main "$@"
