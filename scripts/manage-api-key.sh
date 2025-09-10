#!/bin/bash

# API Key Management Script
# This script provides various API key management operations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  API Key Management Script${NC}"
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

# Function to show current API key
show_current_key() {
    local container_id=$(docker ps -q -f name="$CONTAINER_NAME")
    
    if [ -z "$container_id" ]; then
        print_error "Container '$CONTAINER_NAME' is not running"
        return 1
    fi
    
    if docker exec "$container_id" test -f "$KEY_FILE_PATH"; then
        local current_key=$(docker exec "$container_id" cat "$KEY_FILE_PATH")
        print_info "Current API key: $current_key"
    else
        print_warning "No API key file found at $KEY_FILE_PATH"
    fi
}

# Function to set a specific API key
set_api_key() {
    local new_key="$1"
    local container_id=$(docker ps -q -f name="$CONTAINER_NAME")
    
    if [ -z "$container_id" ]; then
        print_error "Container '$CONTAINER_NAME' is not running"
        return 1
    fi
    
    if [ -z "$new_key" ]; then
        print_error "API key cannot be empty"
        return 1
    fi
    
    # Create secrets directory if it doesn't exist
    docker exec "$container_id" mkdir -p /app/secrets
    
    # Write new key to file
    echo "$new_key" | docker exec -i "$container_id" tee "$KEY_FILE_PATH" > /dev/null
    
    # Set proper permissions
    docker exec "$container_id" chmod 600 "$KEY_FILE_PATH"
    
    print_info "API key updated successfully"
}

# Function to test API key
test_api_key() {
    local api_key="$1"
    local container_id=$(docker ps -q -f name="$CONTAINER_NAME")
    
    if [ -z "$container_id" ]; then
        print_error "Container '$CONTAINER_NAME' is not running"
        return 1
    fi
    
    local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_id")
    
    if [ -z "$api_key" ]; then
        # Test with current key
        if docker exec "$container_id" test -f "$KEY_FILE_PATH"; then
            api_key=$(docker exec "$container_id" cat "$KEY_FILE_PATH")
        else
            print_error "No API key found to test"
            return 1
        fi
    fi
    
    print_info "Testing API key: ${api_key:0:8}...${api_key: -8}"
    
    # Test health endpoint
    if curl -f -s "http://$container_ip:8080/health" > /dev/null; then
        print_info "✅ Health check passed"
    else
        print_error "❌ Health check failed"
        return 1
    fi
    
    # Test API endpoint
    if curl -f -s -H "X-API-Key: $api_key" "http://$container_ip:8080/api/expenses" > /dev/null; then
        print_info "✅ API authentication test passed"
    else
        print_error "❌ API authentication test failed"
        return 1
    fi
}

# Function to show help
show_help() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  show                    Show current API key"
    echo "  set <key>              Set a specific API key"
    echo "  test [key]             Test API key (current or specified)"
    echo "  rotate                 Rotate to a new random API key"
    echo "  help                   Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 show"
    echo "  $0 set my-new-api-key-12345"
    echo "  $0 test"
    echo "  $0 test my-test-key"
    echo "  $0 rotate"
}

# Main function
main() {
    local command="$1"
    
    case "$command" in
        "show")
            show_current_key
            ;;
        "set")
            if [ -z "$2" ]; then
                print_error "API key is required for 'set' command"
                exit 1
            fi
            set_api_key "$2"
            ;;
        "test")
            test_api_key "$2"
            ;;
        "rotate")
            # Call the rotation script
            if [ -f "./scripts/rotate-api-key.sh" ]; then
                ./scripts/rotate-api-key.sh
            else
                print_error "Rotation script not found"
                exit 1
            fi
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
