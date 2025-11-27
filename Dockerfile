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
