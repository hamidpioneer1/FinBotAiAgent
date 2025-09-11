#!/bin/bash

# Database Configuration Script
# This script handles all database-related setup and configuration
# Separated from application deployment for better maintainability

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Database Configuration${NC}"
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
DB_USERNAME="${DB_USERNAME:-finbot_user}"
DB_PASSWORD="${DB_PASSWORD:-finbot_password}"
DB_NAME="${DB_NAME:-finbotaiagent}"
DB_HOST="${DB_HOST:-localhost}"

# Function to check if PostgreSQL is running
check_postgresql() {
    print_info "Checking PostgreSQL status..."
    if systemctl is-active --quiet postgresql; then
        print_info "✅ PostgreSQL is running"
        return 0
    else
        print_error "❌ PostgreSQL is not running"
        return 1
    fi
}

# Function to configure PostgreSQL for Docker access
configure_postgresql() {
    print_info "Configuring PostgreSQL for Docker access..."
    
    # Get PostgreSQL version
    PG_VERSION=$(psql --version | grep -oP '\d+\.\d+' | head -1)
    PG_CONFIG_DIR="/etc/postgresql/${PG_VERSION}/main"
    
    if [ ! -d "$PG_CONFIG_DIR" ]; then
        print_error "PostgreSQL configuration directory not found: $PG_CONFIG_DIR"
        return 1
    fi
    
    # Configure listen_addresses
    print_info "Updating listen_addresses configuration..."
    sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "${PG_CONFIG_DIR}/postgresql.conf"
    
    # Add Docker network ranges to pg_hba.conf
    print_info "Adding Docker network access to pg_hba.conf..."
    sudo tee -a "${PG_CONFIG_DIR}/pg_hba.conf" << 'EOF'

# Allow connections from Docker bridge networks
host    all             all             172.16.0.0/12           md5
host    all             all             192.168.0.0/16          md5
host    all             all             10.0.0.0/8              md5
EOF
    
    # Restart PostgreSQL
    print_info "Restarting PostgreSQL service..."
    sudo systemctl restart postgresql
    
    # Wait for PostgreSQL to start
    sleep 5
    
    if check_postgresql; then
        print_info "✅ PostgreSQL configured and restarted successfully"
        return 0
    else
        print_error "❌ Failed to restart PostgreSQL"
        return 1
    fi
}

# Function to create database user
create_database_user() {
    print_info "Creating database user: $DB_USERNAME"
    
    # Check if user already exists
    if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USERNAME';" | grep -q 1; then
        print_warning "User $DB_USERNAME already exists"
    else
        sudo -u postgres psql -c "CREATE USER $DB_USERNAME WITH PASSWORD '$DB_PASSWORD';"
        print_info "✅ Database user created: $DB_USERNAME"
    fi
}

# Function to create database
create_database() {
    print_info "Creating database: $DB_NAME"
    
    # Check if database already exists
    if sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME';" | grep -q 1; then
        print_warning "Database $DB_NAME already exists"
    else
        sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USERNAME;"
        print_info "✅ Database created: $DB_NAME"
    fi
    
    # Grant privileges
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USERNAME;"
    print_info "✅ Privileges granted to $DB_USERNAME"
}

# Function to create database schema
create_database_schema() {
    print_info "Creating database schema..."
    
    # Create expenses table
    sudo -u postgres psql -d "$DB_NAME" -c "
    CREATE TABLE IF NOT EXISTS expenses (
        id SERIAL PRIMARY KEY,
        employee_id VARCHAR(50) NOT NULL,
        amount DECIMAL(10,2) NOT NULL,
        category VARCHAR(100) NOT NULL,
        description TEXT,
        status VARCHAR(50) DEFAULT 'Pending',
        submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );" 2>/dev/null || print_warning "Table creation failed or table already exists"
    
    # Create indexes for better performance
    sudo -u postgres psql -d "$DB_NAME" -c "
    CREATE INDEX IF NOT EXISTS idx_expenses_employee_id ON expenses(employee_id);
    CREATE INDEX IF NOT EXISTS idx_expenses_status ON expenses(status);
    CREATE INDEX IF NOT EXISTS idx_expenses_submitted_at ON expenses(submitted_at);
    " 2>/dev/null || print_warning "Index creation failed or indexes already exist"
    
    print_info "✅ Database schema created"
}

# Function to test database connection
test_database_connection() {
    print_info "Testing database connection..."
    
    # Test connection from host
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USERNAME" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
        print_info "✅ Database connection successful from host"
    else
        print_error "❌ Database connection failed from host"
        return 1
    fi
    
    # Test connection from Docker (if Docker is available)
    if command -v docker >/dev/null 2>&1; then
        if docker run --rm --network host postgres:15 psql -h "$DB_HOST" -U "$DB_USERNAME" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
            print_info "✅ Database connection successful from Docker"
        else
            print_warning "⚠️ Database connection failed from Docker (this is expected if Docker is not configured yet)"
        fi
    fi
}

# Function to create database environment file
create_database_env() {
    print_info "Creating database environment file..."
    
    # Get EC2 internal IP for maximum reliability
    EC2_INTERNAL_IP=$(hostname -I | awk '{print $1}')
    
    cat > /home/ubuntu/finbotaiagent/.env.database << EOF
# Database Configuration - Using EC2 Internal IP for reliability
DB_HOST=$EC2_INTERNAL_IP
DB_USERNAME=$DB_USERNAME
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME
DB_PORT=5432
DB_SSL_MODE=Prefer
DB_CONNECTION_TIMEOUT=30
DB_COMMAND_TIMEOUT=30
EOF
    
    print_info "✅ Database environment file created: .env.database"
}

# Function to backup database
backup_database() {
    print_info "Creating database backup..."
    
    BACKUP_DIR="/home/ubuntu/finbotaiagent/backups"
    mkdir -p "$BACKUP_DIR"
    
    BACKUP_FILE="$BACKUP_DIR/finbotaiagent_$(date +%Y%m%d_%H%M%S).sql"
    
    if PGPASSWORD="$DB_PASSWORD" pg_dump -h "$DB_HOST" -U "$DB_USERNAME" -d "$DB_NAME" > "$BACKUP_FILE"; then
        print_info "✅ Database backup created: $BACKUP_FILE"
    else
        print_error "❌ Database backup failed"
        return 1
    fi
}

# Function to restore database
restore_database() {
    local backup_file="$1"
    
    if [ -z "$backup_file" ]; then
        print_error "Backup file not specified"
        return 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        print_error "Backup file not found: $backup_file"
        return 1
    fi
    
    print_info "Restoring database from: $backup_file"
    
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USERNAME" -d "$DB_NAME" < "$backup_file"; then
        print_info "✅ Database restored successfully"
    else
        print_error "❌ Database restore failed"
        return 1
    fi
}

# Function to show database status
show_database_status() {
    print_header
    
    print_info "Database Status:"
    echo "  Host: $DB_HOST"
    echo "  Database: $DB_NAME"
    echo "  User: $DB_USERNAME"
    echo "  Port: 5432"
    
    if check_postgresql; then
        print_info "✅ PostgreSQL is running"
    else
        print_error "❌ PostgreSQL is not running"
    fi
    
    if test_database_connection; then
        print_info "✅ Database connection is working"
    else
        print_error "❌ Database connection is not working"
    fi
}

# Main function
main() {
    local command="$1"
    
    case "$command" in
        "setup")
            print_header
            check_postgresql || exit 1
            configure_postgresql || exit 1
            create_database_user || exit 1
            create_database || exit 1
            create_database_schema || exit 1
            create_database_env || exit 1
            test_database_connection || exit 1
            print_info "✅ Database setup completed successfully!"
            ;;
        "configure")
            print_header
            configure_postgresql || exit 1
            print_info "✅ PostgreSQL configuration updated!"
            ;;
        "create-user")
            print_header
            create_database_user || exit 1
            print_info "✅ Database user created!"
            ;;
        "create-database")
            print_header
            create_database || exit 1
            print_info "✅ Database created!"
            ;;
        "create-schema")
            print_header
            create_database_schema || exit 1
            print_info "✅ Database schema created!"
            ;;
        "test")
            print_header
            test_database_connection || exit 1
            print_info "✅ Database connection test passed!"
            ;;
        "backup")
            print_header
            backup_database || exit 1
            print_info "✅ Database backup completed!"
            ;;
        "restore")
            print_header
            restore_database "$2" || exit 1
            print_info "✅ Database restore completed!"
            ;;
        "status")
            show_database_status
            ;;
        "help"|"--help"|"-h"|"")
            echo "Usage: $0 [COMMAND]"
            echo ""
            echo "Commands:"
            echo "  setup           Complete database setup"
            echo "  configure       Configure PostgreSQL for Docker access"
            echo "  create-user     Create database user"
            echo "  create-database Create database"
            echo "  create-schema   Create database schema"
            echo "  test            Test database connection"
            echo "  backup          Create database backup"
            echo "  restore FILE    Restore database from backup"
            echo "  status          Show database status"
            echo "  help            Show this help message"
            ;;
        *)
            print_error "Unknown command: $command"
            echo "Use '$0 help' for available commands"
            exit 1
            ;;
    esac
}

# Check if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
