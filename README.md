# Zhipu Web Search MCP Server

A Model Context Protocol (MCP) server that provides web search functionality using the Zhipu AI API.

## Features

- Web search tool for MCP clients
- SSE (Server-Sent Events) transport for web deployment
- Docker containerization support
- Ready for deployment on EasyPanel/Coolify

## Quick Start

### Local Development

1. Clone the repository:
```bash
git clone https://github.com/khaledbashir/zmcp.git
cd zmcp/zhipu-web-search-mcp
```

2. Create a virtual environment and install dependencies:
```bash
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

3. Set up your environment variables:
```bash
cp env.example .env
# Edit .env and add your actual Zhipu API key
```

4. Run the server:
```bash
uv run main.py --host 0.0.0.0 --port 8020
```

### Using stdio Protocol

To run with stdio protocol:
```bash
mcp dev web_search.py
```

Configure your client:
```json
{
    "mcpServers": {
        "mcp-server": {
            "command": "uv",
            "args": [
                "--directory",
                "<your-project-path>",
                "run",
                "main.py"
            ]
        }
    }
}
```

## Deployment with EasyPanel/Coolify

### 1. Push to GitHub

First, push your code to GitHub:
```bash
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/khaledbashir/zmcp.git
git push -u origin main
```

### 2. Deploy on EasyPanel

1. Log in to your EasyPanel dashboard
2. Create a new application
3. Select "Docker" as the deployment method
4. Connect your GitHub repository
5. Use the following settings:
   - Docker Image: `python:3.12-slim`
   - Port: 8020
   - Environment Variables:
     - `ZHIPU_AUTH_KEY`: Your Zhipu API key
   - Start Command: `uv run main.py --host 0.0.0.0 --port 8020`

### 3. Deploy on Coolify

1. Log in to your Coolify dashboard
2. Create a new application
3. Select "Docker" as the deployment method
4. Connect your GitHub repository
5. Use the following Dockerfile:
```dockerfile
FROM python:3.12-slim

WORKDIR /app

# Install uv for dependency management
RUN pip install --no-cache-dir uv

# Copy dependency files first for better caching
COPY pyproject.toml uv.lock ./

# Install dependencies
RUN uv venv && uv pip install --no-dev -r uv.lock

# Copy application code
COPY . .

# Expose the port
EXPOSE 8020

# Command to run the SSE server
CMD ["uv", "run", "main.py", "--host", "0.0.0.0", "--port", "8020"]
```

6. Set up environment variables:
   - `ZHIPU_AUTH_KEY`: Your Zhipu API key

### 4. Configure Domain

After deployment, configure your domain (zmcp.qandu.me) to point to your application.

## API Usage

### Web Search Tool

The server provides a `web_search` tool that can be used to search the internet:

```python
# Example usage with MCP client
result = await session.call_tool("web_search", {"query": "Python programming"})
print(result.content[0].text)
```

## Configuration

The application requires the following environment variable:

- `ZHIPU_AUTH_KEY`: Your Zhipu AI API key (get it from https://open.bigmodel.cn/)

## Health Check

You can check if the service is running by accessing:
- `/sse` endpoint for SSE transport

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License.