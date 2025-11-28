# Deploying Zhipu MCP Server on zmcp.qandu.me

This guide will help you deploy the Zhipu Web Search MCP server on the domain zmcp.qandu.me.

## Prerequisites

1. A Zhipu API key from https://open.bigmodel.cn/
2. Access to a hosting platform (EasyPanel, Coolify, or any Docker-compatible host)
3. Domain control over zmcp.qandu.me

## Quick Deployment Steps

### 1. Prepare Your Environment

```bash
# Clone the repository
git clone https://github.com/khaledbashir/zmcp.git
cd zmcp/zhipu-web-search-mcp

# Create and configure .env file
cp env.example .env
nano .env  # Add your Zhipu API key
```

### 2. Using the Deployment Script

The project includes a deployment script that creates platform-specific configurations:

```bash
# For EasyPanel deployment
./deploy.sh easypanel

# For Coolify deployment
./deploy.sh coolify
```

### 3. Manual Docker Deployment

If you prefer manual deployment with Docker Compose:

```bash
# Build and run the container
docker-compose up -d

# Check logs
docker-compose logs -f web-search-mcp
```

## Platform-Specific Instructions

### EasyPanel Deployment

1. **Prepare the deployment**:
   ```bash
   ./deploy.sh easypanel
   ```

2. **In EasyPanel Dashboard**:
   - Create a new application
   - Select "Docker" as deployment method
   - Connect your GitHub repository
   - Use the `easypanel.json` configuration
   - Set environment variable: `ZHIPU_AUTH_KEY=your_actual_api_key`
   - Configure domain: zmcp.qandu.me

3. **Network Settings**:
   - External Port: 80
   - Internal Port: 8020
   - Protocol: HTTP

### Coolify Deployment

1. **Prepare the deployment**:
   ```bash
   ./deploy.sh coolify
   ```

2. **In Coolify Dashboard**:
   - Create a new application
   - Select "Docker" as deployment method
   - Connect your GitHub repository
   - Use the `coolify-compose.yml` configuration
   - Set environment variable: `ZHIPU_AUTH_KEY`
   - Configure domain: zmcp.qandu.me

### Direct Server Deployment

If you have direct server access:

1. **Install Docker and Docker Compose**:
   ```bash
   curl -fsSL https://get.docker.com -o get-docker.sh
   sh get-docker.sh
   ```

2. **Deploy with Nginx Reverse Proxy**:
   ```bash
   # Create nginx configuration
   cat > nginx.conf << EOF
   events {
       worker_connections 1024;
   }

   http {
       upstream app {
           server web-search-mcp:8020;
       }

       server {
           listen 80;
           server_name zmcp.qandu.me;

           location / {
               proxy_pass http://app;
               proxy_set_header Host $host;
               proxy_set_header X-Real-IP $remote_addr;
               proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
               proxy_set_header X-Forwarded-Proto $scheme;
           }
       }
   }
   EOF

   # Create docker-compose with nginx
   cat > docker-compose.prod.yml << EOF
   version: '3.8'

   services:
     web-search-mcp:
       build: .
       expose:
         - "8020"
       env_file:
         - .env
       restart: unless-stopped
       networks:
         - mcp-network

     nginx:
       image: nginx:alpine
       ports:
         - "80:80"
       volumes:
         - ./nginx.conf:/etc/nginx/nginx.conf
       depends_on:
         - web-search-mcp
       restart: unless-stopped
       networks:
         - mcp-network

   networks:
     mcp-network:
       driver: bridge
   EOF

   # Deploy
   docker-compose -f docker-compose.prod.yml up -d
   ```

## Domain Configuration

### DNS Settings

Configure your DNS to point zmcp.qandu.me to your server's IP address:

```
Type: A
Name: zmcp
Value: YOUR_SERVER_IP
TTL: 300 (or default)
```

### SSL Certificate (Recommended)

For production, enable HTTPS:

1. **Install Certbot**:
   ```bash
   sudo apt-get update
   sudo apt-get install certbot python3-certbot-nginx
   ```

2. **Get Certificate**:
   ```bash
   sudo certbot --nginx -d zmcp.qandu.me
   ```

3. **Update Nginx Config** (Certbot will do this automatically)

## Testing Your Deployment

### 1. Verify Server is Running

```bash
# Test the SSE endpoint
curl http://zmcp.qandu.me/sse

# You should see a connection established (may hang waiting for events)
```

### 2. Test Web Search Functionality

```python
import asyncio
from mcp import ClientSession
from mcp.client.sse import sse_client
from contextlib import AsyncExitStack

async def test_deployment():
    async with AsyncExitStack() as stack:
        # Connect to your deployed server
        streams_context = sse_client(url="https://zmcp.qandu.me/sse")
        streams = await stack.enter_async_context(streams_context)
        session = await stack.enter_async_context(ClientSession(*streams))
        await session.initialize()
        
        # Test the web search tool
        result = await session.call_tool("web_search", {
            "query": "site:demandiq.com pricing"
        })
        
        print("✅ Deployment successful!")
        print("Search results:", result.content[0].text[:200] + "...")

asyncio.run(test_deployment())
```

## MCP Client Configuration

Once deployed, configure your MCP client to connect to:

```json
{
    "mcpServers": {
        "zhipu-web-search": {
            "url": "https://zmcp.qandu.me/sse"
        }
    }
}
```

## Troubleshooting

### Common Issues

1. **Port Already in Use**:
   ```bash
   sudo lsof -i :8020
   sudo kill -9 <PID>
   ```

2. **API Key Errors**:
   - Verify your ZHIPU_AUTH_KEY in .env file
   - Check the API key is valid and active

3. **Domain Not Resolving**:
   - Check DNS propagation: `dig zmcp.qandu.me`
   - Verify A record points to correct IP

4. **Connection Refused**:
   - Check firewall settings
   - Verify Docker containers are running: `docker ps`

### Logs

```bash
# Check application logs
docker-compose logs -f web-search-mcp

# Check nginx logs (if using)
docker-compose logs -f nginx
```

## Performance Optimization

### 1. Enable Caching

Add Redis for caching search results:

```yaml
# Add to docker-compose.yml
  redis:
    image: redis:alpine
    ports:
      - "6379:6379"
    networks:
      - mcp-network
```

### 2. Rate Limiting

Implement rate limiting in Nginx:

```nginx
http {
    limit_req_zone $binary_remote_addr zone=search_limit:10m rate=10r/m;

    server {
        location / {
            limit_req zone=search_limit burst=20 nodelay;
            proxy_pass http://app;
        }
    }
}
```

## Security Considerations

1. **Always use HTTPS in production**
2. **Regularly update dependencies**
3. **Monitor API usage**
4. **Implement proper logging**
5. **Use environment variables for sensitive data**
6. **Consider implementing authentication for the MCP endpoint**

## Monitoring

Set up monitoring for your deployment:

```bash
# Health check endpoint
curl http://zmcp.qandu.me/health

# Monitor container resources
docker stats
```

Your Zhipu MCP server should now be accessible at `https://zmcp.qandu.me/sse` and ready to serve web search requests!