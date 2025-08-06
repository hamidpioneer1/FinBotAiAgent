#!/bin/bash

# FinBot AI Agent Deployment Script
# This script deploys the .NET 9 web API to EC2 Ubuntu instance

set -e  # Exit on any error

echo "🚀 Starting FinBot AI Agent deployment..."

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

# Stop and remove existing containers
print_status "Stopping existing containers..."
docker compose down --remove-orphans || true

# Remove old images to free up space
print_status "Cleaning up old images..."
docker image prune -f || true

# Build the new image
print_status "Building Docker image..."
docker compose build --no-cache

# Start the services
print_status "Starting services..."
docker compose up -d

# Wait for the application to start
print_status "Waiting for application to start..."
sleep 10

# Check if the application is running
if curl -f http://localhost:8080/weatherforecast > /dev/null 2>&1; then
    print_status "✅ Application is running successfully!"
    print_status "🌐 API is available at: http://localhost:8080"
    print_status "📊 Health check endpoint: http://localhost:8080/weatherforecast"
    print_status "📚 Swagger UI: http://localhost:8080/swagger"
else
    print_error "❌ Application failed to start properly"
    print_status "Checking container logs..."
    docker compose logs finbotaiagent
    exit 1
fi

# Show running containers
print_status "Current running containers:"
docker compose ps

print_status "🎉 Deployment completed successfully!" 