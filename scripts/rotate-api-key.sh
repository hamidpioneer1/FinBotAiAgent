#!/bin/bash

# API Key Rotation Script
# This script rotates the API key without requiring a deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  API Key Rotation Script${NC}"
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
CONTAINER_NAME="finbotaiagent"
KEY_FILE_PATH="/app/secrets/api-key.txt"
BACKUP_DIR="/app/secrets/backups"
MAX_BACKUPS=5

# Function to generate new API key
generate_new_key() {
    openssl rand -hex 32
}

# Function to backup current key
backup_current_key() {
    if [ -f "$KEY_FILE_PATH" ]; then
        local backup_file="${BACKUP_DIR}/api-key-backup-$(date +%Y%m%d-%H%M%S).txt"
        mkdir -p "$BACKUP_DIR"
        cp "$KEY_FILE_PATH" "$backup_file"
        echo "$backup_file"
    else
        echo ""
    fi
}

# Function to clean old backups
cleanup_backups() {
    if [ -d "$BACKUP_DIR" ]; then
        local backup_count=$(ls -1 "$BACKUP_DIR" | wc -l)
        if [ "$backup_count" -gt "$MAX_BACKUPS" ]; then
            local files_to_remove=$((backup_count - MAX_BACKUPS))
            ls -1t "$BACKUP_DIR" | tail -n "$files_to_remove" | xargs -I {} rm -f "$BACKUP_DIR/{}"
            print_info "Cleaned up $files_to_remove old backup(s)"
        fi
    fi
}

# Function to update API key in container
update_api_key() {
    local new_key="$1"
    local container_id="$2"
    
    # Create secrets directory if it doesn't exist
    docker exec "$container_id" mkdir -p /app/secrets
    
    # Write new key to file
    echo "$new_key" | docker exec -i "$container_id" tee "$KEY_FILE_PATH" > /dev/null
    
    # Set proper permissions
    docker exec "$container_id" chmod 600 "$KEY_FILE_PATH"
    
    print_info "API key updated in container"
}

# Function to test new API key
test_api_key() {
    local new_key="$1"
    local container_ip="$2"
    
    print_info "Testing new API key..."
    
    # Test health endpoint (no auth required)
    if curl -f -s "http://$container_ip:8080/health" > /dev/null; then
        print_info "✅ Health check passed"
    else
        print_error "❌ Health check failed"
        return 1
    fi
    
    # Test API endpoint with new key
    if curl -f -s -H "X-API-Key: $new_key" "http://$container_ip:8080/api/expenses" > /dev/null; then
        print_info "✅ API authentication test passed"
        return 0
    else
        print_error "❌ API authentication test failed"
        return 1
    fi
}

# Function to rollback to previous key
rollback_key() {
    local backup_file="$1"
    local container_id="$2"
    
    if [ -n "$backup_file" ] && [ -f "$backup_file" ]; then
        print_warning "Rolling back to previous API key..."
        cat "$backup_file" | docker exec -i "$container_id" tee "$KEY_FILE_PATH" > /dev/null
        docker exec "$container_id" chmod 600 "$KEY_FILE_PATH"
        print_info "Rollback completed"
    else
        print_error "No backup available for rollback"
    fi
}

# Main function
main() {
    print_header
    
    # Check if container is running
    if ! docker ps | grep -q "$CONTAINER_NAME"; then
        print_error "Container '$CONTAINER_NAME' is not running"
        exit 1
    fi
    
    local container_id=$(docker ps -q -f name="$CONTAINER_NAME")
    local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_id")
    
    print_info "Container ID: $container_id"
    print_info "Container IP: $container_ip"
    
    # Generate new API key
    print_info "Generating new API key..."
    local new_key=$(generate_new_key)
    print_info "New API key: ${new_key:0:8}...${new_key: -8}"
    
    # Backup current key
    print_info "Backing up current API key..."
    local backup_file=$(backup_current_key)
    if [ -n "$backup_file" ]; then
        print_info "Backup created: $backup_file"
    else
        print_warning "No existing key to backup"
    fi
    
    # Update API key
    print_info "Updating API key in container..."
    update_api_key "$new_key" "$container_id"
    
    # Test new key
    if test_api_key "$new_key" "$container_ip"; then
        print_info "✅ API key rotation successful!"
        print_info "New API key: $new_key"
        print_warning "Update your Copilot Studio connector with the new key"
        
        # Cleanup old backups
        cleanup_backups
        
        # Save new key to file for reference
        echo "$new_key" > "current-api-key.txt"
        print_info "New API key saved to current-api-key.txt"
        
    else
        print_error "❌ API key rotation failed!"
        
        # Rollback to previous key
        rollback_key "$backup_file" "$container_id"
        
        # Test rollback
        if [ -n "$backup_file" ] && [ -f "$backup_file" ]; then
            local old_key=$(cat "$backup_file")
            if test_api_key "$old_key" "$container_ip"; then
                print_info "✅ Rollback successful"
            else
                print_error "❌ Rollback failed - manual intervention required"
                exit 1
            fi
        fi
        
        exit 1
    fi
}

# Check if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
