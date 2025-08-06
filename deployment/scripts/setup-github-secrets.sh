#!/bin/bash

# GitHub Secrets Setup Helper Script
# This script helps you prepare the values for GitHub Secrets

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  GitHub Secrets Setup Helper${NC}"
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

print_secret_info() {
    echo -e "${BLUE}Secret: $1${NC}"
    echo "Value: $2"
    echo ""
}

# Function to get user input
get_input() {
    local prompt="$1"
    local default="$2"
    local secret_name="$3"
    
    if [ -n "$default" ]; then
        echo -n "$prompt (default: $default): "
    else
        echo -n "$prompt: "
    fi
    
    read -r input
    
    if [ -z "$input" ] && [ -n "$default" ]; then
        input="$default"
    fi
    
    if [ -z "$input" ]; then
        print_error "This field is required!"
        get_input "$prompt" "$default" "$secret_name"
    else
        echo "$input"
    fi
}

# Function to generate SSH key if needed
generate_ssh_key() {
    local key_path="$1"
    
    if [ ! -f "$key_path" ]; then
        print_info "SSH key not found at $key_path"
        echo -n "Would you like to generate a new SSH key? (y/n): "
        read -r generate_key
        
        if [[ $generate_key =~ ^[Yy]$ ]]; then
            print_info "Generating new SSH key..."
            ssh-keygen -t rsa -b 4096 -f "$key_path" -N ""
            print_info "SSH key generated at $key_path"
            print_warning "Don't forget to add the public key to your EC2 instance!"
            print_info "Public key location: ${key_path}.pub"
        else
            print_error "Please provide a valid SSH key path"
            exit 1
        fi
    fi
}

main() {
    print_header
    
    print_info "This script will help you prepare the values for GitHub Secrets."
    print_info "Make sure you have your EC2 instance and database information ready."
    echo ""
    
    # Get EC2 information
    print_info "=== EC2 Connection Information ==="
    EC2_HOST=$(get_input "Enter your EC2 public IP address" "" "EC2_HOST")
    EC2_USERNAME=$(get_input "Enter SSH username" "ubuntu" "EC2_USERNAME")
    EC2_PORT=$(get_input "Enter SSH port" "22" "EC2_PORT")
    
    # Get SSH key information
    print_info "=== SSH Key Information ==="
    SSH_KEY_PATH=$(get_input "Enter path to your SSH private key" "~/.ssh/id_rsa" "SSH_KEY_PATH")
    SSH_KEY_PATH=$(eval echo "$SSH_KEY_PATH")
    
    # Check if SSH key exists
    generate_ssh_key "$SSH_KEY_PATH"
    
    # Read SSH key content
    if [ -f "$SSH_KEY_PATH" ]; then
        SSH_KEY_CONTENT=$(cat "$SSH_KEY_PATH")
        print_info "SSH key found and loaded"
    else
        print_error "SSH key not found at $SSH_KEY_PATH"
        exit 1
    fi
    
    # Get database information
    print_info "=== Database Information ==="
    DB_HOST=$(get_input "Enter database host address" "" "DB_HOST")
    DB_USERNAME=$(get_input "Enter database username" "postgres" "DB_USERNAME")
    DB_PASSWORD=$(get_input "Enter database password" "" "DB_PASSWORD")
    DB_NAME=$(get_input "Enter database name" "finbotdb" "DB_NAME")
    
    # Display summary
    echo ""
    print_info "=== GitHub Secrets Summary ==="
    echo "Copy these values to your GitHub repository secrets:"
    echo ""
    
    print_secret_info "EC2_HOST" "$EC2_HOST"
    print_secret_info "EC2_USERNAME" "$EC2_USERNAME"
    print_secret_info "EC2_PORT" "$EC2_PORT"
    print_secret_info "EC2_SSH_KEY" "$SSH_KEY_CONTENT"
    print_secret_info "DB_HOST" "$DB_HOST"
    print_secret_info "DB_USERNAME" "$DB_USERNAME"
    print_secret_info "DB_PASSWORD" "$DB_PASSWORD"
    print_secret_info "DB_NAME" "$DB_NAME"
    
    echo ""
    print_info "=== Next Steps ==="
    echo "1. Go to your GitHub repository"
    echo "2. Click Settings → Secrets and variables → Actions"
    echo "3. Click 'New repository secret' for each secret above"
    echo "4. Copy the values from the summary above"
    echo "5. Push to main branch to trigger deployment"
    echo ""
    
    # Save to file option
    echo -n "Would you like to save these secrets to a file? (y/n): "
    read -r save_to_file
    
    if [[ $save_to_file =~ ^[Yy]$ ]]; then
        local secrets_file="github-secrets.txt"
        cat > "$secrets_file" << EOF
# GitHub Secrets for FinBotAiAgent
# Copy these values to your GitHub repository secrets

EC2_HOST=$EC2_HOST
EC2_USERNAME=$EC2_USERNAME
EC2_PORT=$EC2_PORT
EC2_SSH_KEY=$SSH_KEY_CONTENT
DB_HOST=$DB_HOST
DB_USERNAME=$DB_USERNAME
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME
EOF
        print_info "Secrets saved to $secrets_file"
        print_warning "Keep this file secure and delete it after setting up GitHub Secrets!"
    fi
    
    echo ""
    print_info "Setup complete! Follow the next steps above to configure GitHub Secrets."
}

# Check if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 