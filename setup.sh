#!/bin/bash

echo "🔧 Zhipu MCP Server Setup for zmcp.qandu.me"
echo "=========================================="

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "Creating .env file..."
    cp env.example .env
fi

# Check if API key is set
if grep -q "your_zhipu_api_key_here" .env; then
    echo ""
    echo "⚠️  You need to set your Zhipu API key!"
    echo ""
    echo "Get your API key from: https://open.bigmodel.cn/"
    echo ""
    read -p "Enter your Zhipu API key: " api_key
    
    if [ -n "$api_key" ]; then
        # Replace the placeholder with the actual key
        sed -i "s/your_zhipu_api_key_here/$api_key/" .env
        echo "✅ API key set successfully!"
    else
        echo "❌ No API key provided. Exiting."
        exit 1
    fi
fi

echo ""
echo "🚀 Starting deployment..."
./deploy-zmcp.sh