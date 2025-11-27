   git clone <repository-url>
   cd zhipu-web-search-mcp
   ```

2. Set up your environment variables:
   ```bash
   cp env.example .env
   # Edit .env and add your actual Zhipu API key
   nano .env
   ```

3. Deploy the service:
   ```bash
   docker-compose up -d
   ```

4. Your service will be available at `http://zmcp.qandu.me:8020`

## Using Nginx Reverse Proxy

For production deployment, you should use Nginx as a reverse proxy to handle HTTPS and route requests properly.

1. Create an Nginx configuration file:
   ```bash
   nano nginx.conf
   ```

2. Add the following content to `nginx.conf`:
   ```nginx
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
   ```

3. Update your `docker-compose.yml` to include Nginx:
   ```yaml
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
   ```

4. Deploy with Docker Compose:
   ```bash
   docker-compose up -d
   ```

## Setting up HTTPS with Let's Encrypt

1. Install Certbot:
   ```bash
   sudo apt-get update
   sudo apt-get install certbot python3-certbot-nginx
   ```

2. Get a certificate:
   ```bash
   sudo certbot --nginx -d zmcp.qandu.me
   ```

3. Certbot will automatically update your Nginx configuration to use HTTPS.

## Alternative Deployment Options

### Direct Python Deployment

If you prefer not to use Docker:

1. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Run the server:
   ```bash
   uv run main.py --host 0.0.0.0 --port 8020
   ```

### Cloud Deployment

You can deploy this application on various cloud platforms:

- **AWS**: Use ECS or App Runner with a Docker container
- **Google Cloud**: Use Cloud Run with the Docker container
- **Azure**: Use Container Instances or App Service

## Testing Your Deployment

1. Verify the server is running:
   ```bash
   curl http://zmcp.qandu.me/sse
   ```

2. Test the web search tool:
   ```python
   from mcp import ClientSession, StdioServerParameters
   import asyncio

   async def test_web_search():
       async with ClientSession() as session:
           # Connect to your server
           # Use SSE transport for web deployment
           from mcp.client.sse import SseClientTransport
           transport = SseClientTransport("http://zmcp.qandu.me/sse")
           
           await session.connect(transport)
           
           # Test the web search tool
           result = await session.call_tool("web_search", {"query": "Python programming"})
           print(result.content[0].text)

   asyncio.run(test_web_search())
   ```

## Troubleshooting

1. If the service doesn't start, check the logs:
   ```bash
   docker-compose logs web-search-mcp
   ```

2. If you get API errors, verify your Zhipu API key in the `.env` file.

3. If the domain doesn't resolve, check your DNS configuration.

## Security Considerations

1. Always use HTTPS in production
2. Regularly update your dependencies
3. Monitor your API usage
4. Consider implementing rate limiting
5. Use environment variables for sensitive data