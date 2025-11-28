# EasyPanel Deployment Guide for Zhipu MCP Server

This guide is specifically for deploying the Zhipu MCP Server on EasyPanel at zmcp.qandu.me.

## Quick Setup

### 1. Push to GitHub

First, push your code to GitHub:

```bash
git add .
git commit -m "Ready for EasyPanel deployment"
git push origin main
```

### 2. EasyPanel Configuration

In your EasyPanel dashboard:

1. **Create New Application**
   - Click "Add Application"
   - Select "Docker" as deployment method
   - Connect your GitHub repository

2. **Application Settings**
   - **Name**: Zhipu MCP Server
   - **Domain**: zmcp.qandu.me
   - **Docker Compose File**: `docker-compose.easypanel.yml`

3. **Environment Variables**
   - Add: `ZHIPU_AUTH_KEY` (with your API key)

4. **Port Configuration**
   - **External Port**: 80
   - **Internal Port**: 8020
   - **Protocol**: HTTP (EasyPanel will handle SSL)

5. **Health Check**
   - **Path**: `/sse`
   - **Interval**: 30 seconds

### 3. SSL Configuration

EasyPanel will automatically handle SSL certificates for your domain. No additional SSL setup needed.

## Application Endpoints

Once deployed:

- **MCP SSE Endpoint**: `https://zmcp.qandu.me/sse`
- **Health Check**: `https://zmcp.qandu.me/sse`

## MCP Client Configuration

Configure your MCP client to connect to:

```json
{
    "mcpServers": {
        "zhipu-web-search": {
            "url": "https://zmcp.qandu.me/sse"
        }
    }
}
```

## Web Search Tool Usage

```python
import asyncio
from mcp import ClientSession
from mcp.client.sse import sse_client
from contextlib import AsyncExitStack

async def test_search():
    async with AsyncExitStack() as stack:
        streams_context = sse_client(url="https://zmcp.qandu.me/sse")
        streams = await stack.enter_async_context(streams_context)
        session = await stack.enter_async_context(ClientSession(*streams))
        await session.initialize()
        
        result = await session.call_tool("web_search", {
            "query": "site:demandiq.com pricing"
        })
        
        print("Search results:", result.content[0].text)

asyncio.run(test_search())
```

## Testing Your Deployment

After deployment, test with:

```bash
# Test locally first
python3 test-deployment.py --domain zmcp.qandu.me

# Or test the endpoint directly
curl https://zmcp.qandu.me/sse
```

## Troubleshooting

### Common Issues

1. **Port Conflicts**: EasyPanel handles port mapping automatically
2. **SSL Issues**: EasyPanel manages SSL certificates
3. **API Key Errors**: Check environment variables in EasyPanel

### Logs

Check logs in EasyPanel dashboard:
- Go to your application
- Click "Logs" tab
- Monitor both `web-search-mcp` and `redis` containers

### Health Check

If health check fails:
1. Verify the container is running
2. Check if port 8020 is accessible
3. Review application logs

## Environment Variables

Required:
- `ZHIPU_AUTH_KEY`: Your Zhipu API key from https://open.bigmodel.cn/

Optional (for Redis caching):
- Redis is automatically available at `redis:6379`

## Performance Notes

- EasyPanel handles load balancing
- Redis caching is available if needed
- Health checks ensure high availability

## Security

- EasyPanel manages SSL/TLS
- API key is stored securely in environment variables
- No additional firewall rules needed

Your Zhipu MCP Server will be accessible at `https://zmcp.qandu.me/sse` once deployed!