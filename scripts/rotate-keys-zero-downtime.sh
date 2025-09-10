#!/bin/bash

# Zero-Downtime Key Rotation Script
# This script rotates API keys without requiring re-deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Zero-Downtime Key Rotation${NC}"
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
SECRETS_DIR="/app/secrets"
API_KEY_FILE="$SECRETS_DIR/api-key.txt"
JWT_SECRET_FILE="$SECRETS_DIR/jwt-secret.txt"
BACKUP_DIR="/app/secrets/backups"
API_BASE_URL="http://localhost:8080"

# Function to generate secure keys
generate_api_key() {
    openssl rand -hex 32
}

generate_jwt_secret() {
    openssl rand -hex 64
}

# Function to backup current keys
backup_current_keys() {
    print_info "Creating backup of current keys..."
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    
    # Create timestamp
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    
    # Backup API key
    if [ -f "$API_KEY_FILE" ]; then
        cp "$API_KEY_FILE" "$BACKUP_DIR/api-key_$TIMESTAMP.txt"
        print_info "API key backed up to $BACKUP_DIR/api-key_$TIMESTAMP.txt"
    fi
    
    # Backup JWT secret
    if [ -f "$JWT_SECRET_FILE" ]; then
        cp "$JWT_SECRET_FILE" "$BACKUP_DIR/jwt-secret_$TIMESTAMP.txt"
        print_info "JWT secret backed up to $BACKUP_DIR/jwt-secret_$TIMESTAMP.txt"
    fi
}

# Function to update API key
update_api_key() {
    local new_api_key="$1"
    
    print_info "Updating API key..."
    
    # Write new API key to file
    echo "$new_api_key" > "$API_KEY_FILE"
    chmod 600 "$API_KEY_FILE"
    
    print_info "API key updated successfully"
}

# Function to update JWT secret
update_jwt_secret() {
    local new_jwt_secret="$1"
    
    print_info "Updating JWT secret..."
    
    # Write new JWT secret to file
    echo "$new_jwt_secret" > "$JWT_SECRET_FILE"
    chmod 600 "$JWT_SECRET_FILE"
    
    print_info "JWT secret updated successfully"
}

# Function to test new keys
test_new_keys() {
    local api_key="$1"
    local jwt_secret="$2"
    
    print_info "Testing new keys..."
    
    # Test API key authentication
    print_info "Testing API key authentication..."
    if curl -s -H "X-API-Key: $api_key" "$API_BASE_URL/health" > /dev/null; then
        print_info "✅ API key authentication working"
    else
        print_error "❌ API key authentication failed"
        return 1
    fi
    
    # Test OAuth token generation (if JWT secret changed)
    if [ -n "$jwt_secret" ]; then
        print_info "Testing OAuth token generation..."
        if curl -s -X POST "$API_BASE_URL/oauth/token" \
            -H "Content-Type: application/json" \
            -d '{"grant_type":"client_credentials","client_id":"copilot-studio-client","client_secret":"copilot-studio-secret-12345","scope":"api.read api.write"}' \
            | grep -q "access_token"; then
            print_info "✅ OAuth token generation working"
        else
            print_warning "⚠️ OAuth token generation failed (may need container restart)"
        fi
    fi
}

# Function to rollback keys
rollback_keys() {
    print_warning "Rolling back to previous keys..."
    
    # Find latest backup
    LATEST_API_BACKUP=$(ls -t "$BACKUP_DIR"/api-key_*.txt 2>/dev/null | head -1)
    LATEST_JWT_BACKUP=$(ls -t "$BACKUP_DIR"/jwt-secret_*.txt 2>/dev/null | head -1)
    
    if [ -n "$LATEST_API_BACKUP" ]; then
        cp "$LATEST_API_BACKUP" "$API_KEY_FILE"
        print_info "API key rolled back"
    fi
    
    if [ -n "$LATEST_JWT_BACKUP" ]; then
        cp "$LATEST_JWT_BACKUP" "$JWT_SECRET_FILE"
        print_info "JWT secret rolled back"
    fi
}

# Function to restart application (if needed)
restart_application() {
    print_info "Restarting application to apply JWT secret changes..."
    
    # Restart container
    docker restart "$CONTAINER_NAME"
    
    # Wait for application to start
    print_info "Waiting for application to start..."
    sleep 10
    
    # Check if application is healthy
    local retries=0
    while [ $retries -lt 30 ]; do
        if curl -s "$API_BASE_URL/health" > /dev/null; then
            print_info "✅ Application restarted successfully"
            return 0
        fi
        sleep 2
        retries=$((retries + 1))
    done
    
    print_error "❌ Application failed to start after restart"
    return 1
}

# Function to update external systems
update_external_systems() {
    local new_api_key="$1"
    local new_jwt_secret="$2"
    
    print_info "Updating external systems..."
    
    # Update GitHub Secrets (if configured)
    if command -v gh >/dev/null 2>&1; then
        print_info "Updating GitHub Secrets..."
        echo "$new_api_key" | gh secret set API_KEY
        if [ -n "$new_jwt_secret" ]; then
            echo "$new_jwt_secret" | gh secret set JWT_SECRET_KEY
        fi
        print_info "✅ GitHub Secrets updated"
    else
        print_warning "GitHub CLI not available, update secrets manually:"
        print_warning "API_KEY=$new_api_key"
        if [ -n "$new_jwt_secret" ]; then
            print_warning "JWT_SECRET_KEY=$new_jwt_secret"
        fi
    fi
    
    # Update monitoring systems (if configured)
    if [ -f "/app/scripts/update-monitoring.sh" ]; then
        print_info "Updating monitoring systems..."
        /app/scripts/update-monitoring.sh "$new_api_key" "$new_jwt_secret"
    fi
}

# Main rotation function
rotate_keys() {
    local rotate_api_key="$1"
    local rotate_jwt_secret="$2"
    local force_restart="$3"
    
    print_header
    
    # Generate new keys
    local new_api_key=""
    local new_jwt_secret=""
    
    if [ "$rotate_api_key" = "true" ]; then
        new_api_key=$(generate_api_key)
        print_info "Generated new API key: ${new_api_key:0:8}..."
    fi
    
    if [ "$rotate_jwt_secret" = "true" ]; then
        new_jwt_secret=$(generate_jwt_secret)
        print_info "Generated new JWT secret: ${new_jwt_secret:0:8}..."
    fi
    
    # Backup current keys
    backup_current_keys
    
    # Update keys
    if [ "$rotate_api_key" = "true" ]; then
        update_api_key "$new_api_key"
    fi
    
    if [ "$rotate_jwt_secret" = "true" ]; then
        update_jwt_secret "$new_jwt_secret"
    fi
    
    # Test new keys
    if ! test_new_keys "$new_api_key" "$new_jwt_secret"; then
        print_error "Key testing failed, rolling back..."
        rollback_keys
        exit 1
    fi
    
    # Restart application if JWT secret changed or forced
    if [ "$rotate_jwt_secret" = "true" ] || [ "$force_restart" = "true" ]; then
        if ! restart_application; then
            print_error "Application restart failed, rolling back..."
            rollback_keys
            exit 1
        fi
    fi
    
    # Update external systems
    update_external_systems "$new_api_key" "$new_jwt_secret"
    
    print_info "✅ Key rotation completed successfully!"
    print_info "New API key: ${new_api_key:0:8}..."
    if [ -n "$new_jwt_secret" ]; then
        print_info "New JWT secret: ${new_jwt_secret:0:8}..."
    fi
}

# Function to show current keys
show_current_keys() {
    print_header
    
    if [ -f "$API_KEY_FILE" ]; then
        local api_key=$(cat "$API_KEY_FILE")
        print_info "Current API key: ${api_key:0:8}..."
    else
        print_warning "API key file not found: $API_KEY_FILE"
    fi
    
    if [ -f "$JWT_SECRET_FILE" ]; then
        local jwt_secret=$(cat "$JWT_SECRET_FILE")
        print_info "Current JWT secret: ${jwt_secret:0:8}..."
    else
        print_warning "JWT secret file not found: $JWT_SECRET_FILE"
    fi
}

# Function to show help
show_help() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  rotate-api-key                    Rotate API key only"
    echo "  rotate-jwt-secret                 Rotate JWT secret only"
    echo "  rotate-all                        Rotate both API key and JWT secret"
    echo "  show                              Show current keys"
    echo "  rollback                          Rollback to previous keys"
    echo "  test                              Test current keys"
    echo "  help                              Show this help message"
    echo ""
    echo "Options:"
    echo "  --force-restart                   Force application restart"
    echo "  --backup-only                     Only create backup, don't rotate"
    echo ""
    echo "Examples:"
    echo "  $0 rotate-api-key                 # Rotate API key only"
    echo "  $0 rotate-all --force-restart     # Rotate all keys and restart"
    echo "  $0 show                           # Show current keys"
    echo "  $0 test                           # Test current keys"
}

# Function to test current keys
test_current_keys() {
    print_header
    
    if [ -f "$API_KEY_FILE" ]; then
        local api_key=$(cat "$API_KEY_FILE")
        print_info "Testing current API key..."
        if curl -s -H "X-API-Key: $api_key" "$API_BASE_URL/health" > /dev/null; then
            print_info "✅ API key authentication working"
        else
            print_error "❌ API key authentication failed"
        fi
    else
        print_error "API key file not found: $API_KEY_FILE"
    fi
    
    print_info "Testing OAuth token generation..."
    if curl -s -X POST "$API_BASE_URL/oauth/token" \
        -H "Content-Type: application/json" \
        -d '{"grant_type":"client_credentials","client_id":"copilot-studio-client","client_secret":"copilot-studio-secret-12345","scope":"api.read api.write"}' \
        | grep -q "access_token"; then
        print_info "✅ OAuth token generation working"
    else
        print_error "❌ OAuth token generation failed"
    fi
}

# Main function
main() {
    local command="$1"
    local force_restart="false"
    local backup_only="false"
    
    # Parse options
    shift
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force-restart)
                force_restart="true"
                shift
                ;;
            --backup-only)
                backup_only="true"
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
    
    case "$command" in
        "rotate-api-key")
            if [ "$backup_only" = "true" ]; then
                backup_current_keys
            else
                rotate_keys "true" "false" "$force_restart"
            fi
            ;;
        "rotate-jwt-secret")
            if [ "$backup_only" = "true" ]; then
                backup_current_keys
            else
                rotate_keys "false" "true" "$force_restart"
            fi
            ;;
        "rotate-all")
            if [ "$backup_only" = "true" ]; then
                backup_current_keys
            else
                rotate_keys "true" "true" "$force_restart"
            fi
            ;;
        "show")
            show_current_keys
            ;;
        "rollback")
            rollback_keys
            ;;
        "test")
            test_current_keys
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
