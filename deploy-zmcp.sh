#!/bin/bash

# Deployment script for Zhipu MCP Server on zmcp.qandu.me
# This script sets up the complete production environment

set -e

DOMAIN="zmcp.qandu.me"
echo "🚀 Deploying Zhipu MCP Server to $DOMAIN"

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

# Check if .env file exists
if [ ! -f ".env" ]; then
    print_warning "Creating .env file from template..."
    cp env.example .env
    print_error "Please edit .env file and add your Zhipu API key before continuing."
    print_error "Run: nano .env"
    exit 1
fi

# Check if ZHIPU_AUTH_KEY is set in .env
if ! grep -q "ZHIPU_AUTH_KEY=[^[:space:]]" .env || grep -q "your_zhipu_api_key_here" .env; then
    print_error "Please set your Zhipu API key in the .env file."
    print_error "Edit .env and replace 'your_zhipu_api_key_here' with your actual API key."
    exit 1
fi

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p nginx/ssl
mkdir -p nginx/logs

# Check for SSL certificates
if [ ! -f "nginx/ssl/cert.pem" ] || [ ! -f "nginx/ssl/key.pem" ]; then
    print_warning "SSL certificates not found in nginx/ssl/"
    print_status "You have two options:"
    echo "1. Use Let's Encrypt (recommended for production):"
    echo "   sudo certbot certonly --standalone -d $DOMAIN"
    echo "   sudo cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem nginx/ssl/cert.pem"
    echo "   sudo cp /etc/letsencrypt/live/$DOMAIN/privkey.pem nginx/ssl/key.pem"
    echo ""
    echo "2. Generate self-signed certificates (for testing only):"
    echo "   openssl req -x509 -nodes -days 365 -newkey rsa:2048 \\"
    echo "     -keyout nginx/ssl/key.pem \\"
    echo "     -out nginx/ssl/cert.pem \\"
    echo "     -subj '/CN=$DOMAIN'"
    echo ""
    read -p "Do you want to generate self-signed certificates? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Generating self-signed certificates..."
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout nginx/ssl/key.pem \
            -out nginx/ssl/cert.pem \
            -subj "/CN=$DOMAIN"
        print_warning "Self-signed certificates generated. Browser will show security warnings."
    else
        print_status "Please add SSL certificates to nginx/ssl/ directory and run this script again."
        exit 1
    fi
fi

# Stop existing containers if running
print_status "Stopping existing containers..."
docker-compose -f docker-compose.prod.yml down 2>/dev/null || true

# Build and start the services
print_status "Building and starting services..."
docker-compose -f docker-compose.prod.yml up -d --build

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 10

# Check if containers are running
if ! docker-compose -f docker-compose.prod.yml ps | grep -q "Up"; then
    print_error "Failed to start containers. Check logs with:"
    echo "docker-compose -f docker-compose.prod.yml logs"
    exit 1
fi

# Health check
print_status "Performing health check..."
sleep 20

# Check if the service is responding
if curl -k -s https://localhost/health > /dev/null; then
    print_status "✅ Service is healthy!"
else
    print_warning "Health check failed. Check logs:"
    echo "docker-compose -f docker-compose.prod.yml logs web-search-mcp"
fi

# Show status
print_status "Deployment status:"
docker-compose -f docker-compose.prod.yml ps

# Display next steps
echo ""
print_status "🎉 Deployment completed!"
echo ""
echo "Your Zhipu MCP Server is now running at: https://$DOMAIN"
echo ""
echo "Next steps:"
echo "1. Update your DNS to point $DOMAIN to this server's IP"
echo "2. Test the deployment:"
echo "   curl -k https://$DOMAIN/health"
echo ""
echo "3. Test the web search tool:"
echo "   # Use the test script:"
echo "   python test-deployment.py"
echo ""
echo "4. Configure your MCP client to connect to:"
echo "   https://$DOMAIN/sse"
echo ""
echo "To view logs:"
echo "   docker-compose -f docker-compose.prod.yml logs -f"
echo ""
echo "To stop the service:"
echo "   docker-compose -f docker-compose.prod.yml down"