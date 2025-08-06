#!/bin/bash

# Deployment script for FinBot AI Agent
set -e

echo "🚀 Starting deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

# Stop existing container if running
print_status "Stopping existing containers..."
docker-compose down --remove-orphans || true

# Build new image
print_status "Building Docker image..."
docker-compose build --no-cache

# Start services
print_status "Starting services..."
docker-compose up -d

# Wait for health check
print_status "Waiting for application to be ready..."
sleep 30

# Check if application is responding
if curl -f http://localhost:8080/weatherforecast > /dev/null 2>&1; then
    print_status "✅ Application is running successfully!"
    print_status "🌐 Access your API at: http://localhost:8080"
    print_status "📊 Swagger UI at: http://localhost:8080/swagger"
else
    print_error "❌ Application failed to start properly"
    print_status "Checking container logs..."
    docker-compose logs finbotaiagent
    exit 1
fi

# Show container status
print_status "Container status:"
docker-compose ps

print_status "🎉 Deployment completed successfully!" 