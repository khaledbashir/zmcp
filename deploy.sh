#!/bin/bash

# Deployment script for Zhipu Web Search MCP Server
# Usage: ./deploy.sh [easypanel|coolify]

set -e

DEPLOYMENT_TARGET=$1

if [ -z "$DEPLOYMENT_TARGET" ]; then
    echo "Usage: $0 [easypanel|coolify]"
    exit 1
fi

echo "Preparing deployment for $DEPLOYMENT_TARGET..."

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "Creating .env file from template..."
    cp env.example .env
    echo "Please edit .env file and add your Zhipu API key before continuing."
    exit 1
fi

# Check if ZHIPU_AUTH_KEY is set in .env
if ! grep -q "ZHIPU_AUTH_KEY=[^[:space:]]" .env || grep -q "your_zhipu_api_key_here" .env; then
    echo "Please set your Zhipu API key in the .env file."
    exit 1
fi

# Create deployment-specific files
case $DEPLOYMENT_TARGET in
    "easypanel")
        echo "Creating EasyPanel deployment configuration..."
        cat > easypanel.json << EOF
{
  "name": "Zhipu Web Search MCP",
  "docker": {
    "image": "python:3.12-slim",
    "ports": ["8020:8020"],
    "environment": ["ZHIPU_AUTH_KEY"],
    "script": "pip install --no-cache-dir uv && uv venv && uv pip install --no-dev -r uv.lock && uv run main.py --host 0.0.0.0 --port 8020"
  },
  "domain": "zmcp.qandu.me"
}
EOF
        echo "EasyPanel configuration created: easypanel.json"
        ;;

    "coolify")
        echo "Creating Coolify deployment configuration..."
        cat > coolify-compose.yml << EOF
version: '3.8'

services:
  app:
    image: python:3.12-slim
    working_dir: /app
    ports:
      - "8020:8020"
    volumes:
      - .:/app
    environment:
      - ZHIPU_AUTH_KEY=\${ZHIPU_AUTH_KEY}
    command: >
      sh -c "pip install --no-cache-dir uv &&
             uv venv &&
             uv pip install --no-dev -r uv.lock &&
             uv run main.py --host 0.0.0.0 --port 8020"
    restart: unless-stopped
EOF
        echo "Coolify configuration created: coolify-compose.yml"
        ;;

    *)
        echo "Invalid deployment target. Use 'easypanel' or 'coolify'."
        exit 1
        ;;
esac

echo "Deployment preparation complete!"
echo ""
echo "Next steps:"
echo "1. Push your code to GitHub:"
echo "   git add ."
echo "   git commit -m \"Add deployment configuration\""
echo "   git push"
echo ""
echo "2. In your $DEPLOYMENT_TARGET dashboard, create a new application and connect to your GitHub repository."
echo "3. Use the configuration file that was generated."

if [ "$DEPLOYMENT_TARGET" = "easypanel" ]; then
    echo "4. Make sure to set the ZHIPU_AUTH_KEY environment variable in EasyPanel."
elif [ "$DEPLOYMENT_TARGET" = "coolify" ]; then
    echo "4. Make sure to set the ZHIPU_AUTH_KEY environment variable in Coolify."
fi

echo ""
echo "5. Deploy your application and configure your domain (zmcp.qandu.me) to point to it."
