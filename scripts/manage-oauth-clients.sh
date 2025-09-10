#!/bin/bash

# OAuth Client Management Script
# This script manages OAuth client credentials

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  OAuth Client Management${NC}"
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
API_BASE_URL="http://localhost:8080"

# Function to generate client credentials
generate_client_credentials() {
    local client_id="$1"
    local description="$2"
    local scopes="$3"
    
    # Generate secure client secret
    local client_secret=$(openssl rand -hex 32)
    
    print_info "Generated client credentials:"
    echo "Client ID: $client_id"
    echo "Client Secret: $client_secret"
    echo "Description: $description"
    echo "Scopes: $scopes"
    echo ""
    
    # Save to file
    local credentials_file="oauth-clients.txt"
    echo "# OAuth Client Credentials - Generated $(date)" >> "$credentials_file"
    echo "Client ID: $client_id" >> "$credentials_file"
    echo "Client Secret: $client_secret" >> "$credentials_file"
    echo "Description: $description" >> "$credentials_file"
    echo "Scopes: $scopes" >> "$credentials_file"
    echo "---" >> "$credentials_file"
    echo ""
    
    print_info "Credentials saved to $credentials_file"
    print_warning "Keep these credentials secure and don't commit them to version control!"
}

# Function to test OAuth token generation
test_oauth_token() {
    local client_id="$1"
    local client_secret="$2"
    local scopes="$3"
    
    print_info "Testing OAuth token generation..."
    
    # Test token endpoint
    local response=$(curl -s -X POST "$API_BASE_URL/oauth/token" \
        -H "Content-Type: application/json" \
        -d "{
            \"grant_type\": \"client_credentials\",
            \"client_id\": \"$client_id\",
            \"client_secret\": \"$client_secret\",
            \"scope\": \"$scopes\"
        }")
    
    if echo "$response" | grep -q "access_token"; then
        print_info "✅ OAuth token generation successful"
        echo "Response: $response" | jq '.' 2>/dev/null || echo "$response"
        
        # Extract access token
        local access_token=$(echo "$response" | jq -r '.access_token' 2>/dev/null)
        if [ "$access_token" != "null" ] && [ -n "$access_token" ]; then
            print_info "Testing API access with JWT token..."
            test_api_with_jwt "$access_token"
        fi
    else
        print_error "❌ OAuth token generation failed"
        echo "Response: $response"
        return 1
    fi
}

# Function to test API access with JWT token
test_api_with_jwt() {
    local access_token="$1"
    
    print_info "Testing API access with JWT token..."
    
    # Test API endpoint with JWT
    local response=$(curl -s -H "Authorization: Bearer $access_token" "$API_BASE_URL/api/expenses")
    
    if echo "$response" | grep -q "\[" || echo "$response" | grep -q "error"; then
        print_info "✅ API access with JWT successful"
        echo "Response: $response" | jq '.' 2>/dev/null || echo "$response"
    else
        print_error "❌ API access with JWT failed"
        echo "Response: $response"
        return 1
    fi
}

# Function to show help
show_help() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  generate <client_id> <description> <scopes>  Generate new client credentials"
    echo "  test <client_id> <client_secret> <scopes>    Test OAuth token generation"
    echo "  test-jwt <access_token>                       Test API access with JWT token"
    echo "  help                                          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 generate copilot-studio-client \"Copilot Studio Integration\" \"api.read api.write\""
    echo "  $0 test copilot-studio-client secret123 \"api.read api.write\""
    echo "  $0 test-jwt eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    echo ""
    echo "Default scopes: api.read, api.write"
}

# Function to create default clients
create_default_clients() {
    print_info "Creating default OAuth clients..."
    
    # Copilot Studio client
    generate_client_credentials "copilot-studio-client" "Copilot Studio Integration" "api.read api.write"
    
    # Test client
    generate_client_credentials "test-client" "Test Client for Development" "api.read"
    
    print_info "Default clients created successfully"
}

# Main function
main() {
    local command="$1"
    
    case "$command" in
        "generate")
            if [ -z "$2" ] || [ -z "$3" ]; then
                print_error "Client ID and description are required for 'generate' command"
                show_help
                exit 1
            fi
            local client_id="$2"
            local description="$3"
            local scopes="${4:-api.read api.write}"
            generate_client_credentials "$client_id" "$description" "$scopes"
            ;;
        "test")
            if [ -z "$2" ] || [ -z "$3" ]; then
                print_error "Client ID and secret are required for 'test' command"
                show_help
                exit 1
            fi
            local client_id="$2"
            local client_secret="$3"
            local scopes="${4:-api.read api.write}"
            test_oauth_token "$client_id" "$client_secret" "$scopes"
            ;;
        "test-jwt")
            if [ -z "$2" ]; then
                print_error "Access token is required for 'test-jwt' command"
                show_help
                exit 1
            fi
            test_api_with_jwt "$2"
            ;;
        "create-defaults")
            create_default_clients
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
