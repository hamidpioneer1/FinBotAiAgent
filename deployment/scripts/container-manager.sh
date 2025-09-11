#!/bin/bash

# Selective Container Management Script
# This script manages only the FinBot AI Agent containers, not all containers on the server
# Follows best practices for container lifecycle management

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Container Management${NC}"
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
PROJECT_NAME="finbotaiagent"
CONTAINER_NAME="finbotaiagent"
IMAGE_NAME="finbotaiagent:latest"
COMPOSE_FILE="docker-compose.yml"
BACKUP_DIR="/home/ubuntu/finbotaiagent/backups"
LOG_DIR="/home/ubuntu/finbotaiagent/logs"

# Function to check if container exists
container_exists() {
    docker ps -a --filter "name=$CONTAINER_NAME" --format "{{.Names}}" | grep -q "^$CONTAINER_NAME$"
}

# Function to check if container is running
container_running() {
    docker ps --filter "name=$CONTAINER_NAME" --format "{{.Names}}" | grep -q "^$CONTAINER_NAME$"
}

# Function to get container status
get_container_status() {
    if container_running; then
        echo "running"
    elif container_exists; then
        echo "stopped"
    else
        echo "not_found"
    fi
}

# Function to stop application containers only
stop_application() {
    print_info "Stopping FinBot AI Agent application..."
    
    if container_running; then
        print_info "Stopping container: $CONTAINER_NAME"
        docker stop "$CONTAINER_NAME"
        print_info "✅ Container stopped successfully"
    else
        print_warning "Container $CONTAINER_NAME is not running"
    fi
}

# Function to start application containers
start_application() {
    print_info "Starting FinBot AI Agent application..."
    
    if container_exists; then
        if container_running; then
            print_warning "Container $CONTAINER_NAME is already running"
        else
            print_info "Starting container: $CONTAINER_NAME"
            docker start "$CONTAINER_NAME"
            print_info "✅ Container started successfully"
        fi
    else
        print_error "Container $CONTAINER_NAME does not exist. Please deploy first."
        return 1
    fi
}

# Function to restart application containers
restart_application() {
    print_info "Restarting FinBot AI Agent application..."
    
    if container_exists; then
        print_info "Restarting container: $CONTAINER_NAME"
        docker restart "$CONTAINER_NAME"
        print_info "✅ Container restarted successfully"
    else
        print_error "Container $CONTAINER_NAME does not exist. Please deploy first."
        return 1
    fi
}

# Function to remove application containers only
remove_application() {
    print_info "Removing FinBot AI Agent application..."
    
    if container_exists; then
        if container_running; then
            print_info "Stopping container before removal..."
            docker stop "$CONTAINER_NAME"
        fi
        
        print_info "Removing container: $CONTAINER_NAME"
        docker rm "$CONTAINER_NAME"
        print_info "✅ Container removed successfully"
    else
        print_warning "Container $CONTAINER_NAME does not exist"
    fi
}

# Function to remove application image
remove_image() {
    print_info "Removing FinBot AI Agent image..."
    
    if docker images -q "$IMAGE_NAME" | grep -q .; then
        print_info "Removing image: $IMAGE_NAME"
        docker rmi "$IMAGE_NAME"
        print_info "✅ Image removed successfully"
    else
        print_warning "Image $IMAGE_NAME does not exist"
    fi
}

# Function to clean up application resources
cleanup_application() {
    print_info "Cleaning up FinBot AI Agent resources..."
    
    # Stop and remove containers
    remove_application
    
    # Remove image
    remove_image
    
    # Remove unused networks (only project-specific)
    print_info "Cleaning up unused networks..."
    docker network prune -f --filter "name=finbot"
    
    # Remove unused volumes (only project-specific)
    print_info "Cleaning up unused volumes..."
    docker volume prune -f --filter "name=finbot"
    
    print_info "✅ Application cleanup completed"
}

# Function to show application status
show_status() {
    print_header
    
    local status=$(get_container_status)
    
    print_info "FinBot AI Agent Status:"
    echo "  Container: $CONTAINER_NAME"
    echo "  Image: $IMAGE_NAME"
    echo "  Status: $status"
    
    if [ "$status" = "running" ]; then
        print_info "✅ Application is running"
        
        # Show container details
        print_info "Container Details:"
        docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.CreatedAt}}"
        
        # Show health status
        print_info "Health Check:"
        if docker inspect "$CONTAINER_NAME" --format='{{.State.Health.Status}}' 2>/dev/null; then
            local health_status=$(docker inspect "$CONTAINER_NAME" --format='{{.State.Health.Status}}' 2>/dev/null)
            if [ "$health_status" = "healthy" ]; then
                print_info "✅ Container is healthy"
            else
                print_warning "⚠️ Container health status: $health_status"
            fi
        else
            print_warning "⚠️ Health check not configured"
        fi
        
        # Show resource usage
        print_info "Resource Usage:"
        docker stats "$CONTAINER_NAME" --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
        
    elif [ "$status" = "stopped" ]; then
        print_warning "⚠️ Application is stopped"
    else
        print_error "❌ Application is not deployed"
    fi
}

# Function to show application logs
show_logs() {
    local lines="${1:-50}"
    
    print_info "Showing last $lines lines of application logs..."
    
    if container_exists; then
        docker logs --tail "$lines" "$CONTAINER_NAME"
    else
        print_error "Container $CONTAINER_NAME does not exist"
        return 1
    fi
}

# Function to follow application logs
follow_logs() {
    print_info "Following application logs (Ctrl+C to stop)..."
    
    if container_exists; then
        docker logs -f "$CONTAINER_NAME"
    else
        print_error "Container $CONTAINER_NAME does not exist"
        return 1
    fi
}

# Function to backup application data
backup_application() {
    print_info "Creating application backup..."
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    
    # Create backup timestamp
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILE="$BACKUP_DIR/finbotaiagent_backup_$TIMESTAMP.tar.gz"
    
    # Backup application files
    print_info "Backing up application files..."
    tar -czf "$BACKUP_FILE" \
        --exclude="node_modules" \
        --exclude=".git" \
        --exclude="bin" \
        --exclude="obj" \
        --exclude="logs" \
        --exclude="backups" \
        /home/ubuntu/finbotaiagent/
    
    print_info "✅ Application backup created: $BACKUP_FILE"
}

# Function to restore application data
restore_application() {
    local backup_file="$1"
    
    if [ -z "$backup_file" ]; then
        print_error "Backup file not specified"
        return 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        print_error "Backup file not found: $backup_file"
        return 1
    fi
    
    print_info "Restoring application from: $backup_file"
    
    # Stop application if running
    if container_running; then
        stop_application
    fi
    
    # Extract backup
    print_info "Extracting backup..."
    tar -xzf "$backup_file" -C /home/ubuntu/
    
    print_info "✅ Application restored successfully"
}

# Function to update application
update_application() {
    print_info "Updating FinBot AI Agent application..."
    
    # Stop application
    if container_running; then
        stop_application
    fi
    
    # Remove old container and image
    remove_application
    remove_image
    
    # Build new image
    print_info "Building new application image..."
    cd /home/ubuntu/finbotaiagent
    docker build -t "$IMAGE_NAME" .
    
    # Start application
    print_info "Starting updated application..."
    docker-compose up -d
    
    print_info "✅ Application updated successfully"
}

# Function to scale application
scale_application() {
    local replicas="$1"
    
    if [ -z "$replicas" ]; then
        print_error "Number of replicas not specified"
        return 1
    fi
    
    print_info "Scaling application to $replicas replicas..."
    
    # Update docker-compose.yml for scaling
    sed -i "s/replicas: [0-9]*/replicas: $replicas/" "$COMPOSE_FILE"
    
    # Deploy with new scale
    docker-compose up -d --scale finbotaiagent="$replicas"
    
    print_info "✅ Application scaled to $replicas replicas"
}

# Function to show help
show_help() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  start                    Start the application"
    echo "  stop                     Stop the application"
    echo "  restart                  Restart the application"
    echo "  remove                   Remove the application"
    echo "  cleanup                  Clean up all application resources"
    echo "  status                   Show application status"
    echo "  logs [LINES]             Show application logs (default: 50 lines)"
    echo "  follow-logs              Follow application logs"
    echo "  backup                   Create application backup"
    echo "  restore FILE             Restore application from backup"
    echo "  update                   Update the application"
    echo "  scale REPLICAS           Scale the application"
    echo "  help                     Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start                 # Start the application"
    echo "  $0 stop                  # Stop the application"
    echo "  $0 logs 100              # Show last 100 lines of logs"
    echo "  $0 scale 3               # Scale to 3 replicas"
    echo "  $0 backup                # Create application backup"
}

# Main function
main() {
    local command="$1"
    local arg="$2"
    
    case "$command" in
        "start")
            print_header
            start_application
            ;;
        "stop")
            print_header
            stop_application
            ;;
        "restart")
            print_header
            restart_application
            ;;
        "remove")
            print_header
            remove_application
            ;;
        "cleanup")
            print_header
            cleanup_application
            ;;
        "status")
            show_status
            ;;
        "logs")
            print_header
            show_logs "$arg"
            ;;
        "follow-logs")
            print_header
            follow_logs
            ;;
        "backup")
            print_header
            backup_application
            ;;
        "restore")
            print_header
            restore_application "$arg"
            ;;
        "update")
            print_header
            update_application
            ;;
        "scale")
            print_header
            scale_application "$arg"
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
