#!/usr/bin/env python3
"""
Test script for Zhipu MCP Server deployment on zmcp.qandu.me
This script verifies that the deployment is working correctly.
"""

import asyncio
import sys
import json
from mcp import ClientSession
from mcp.client.sse import sse_client
from contextlib import AsyncExitStack
import argparse

async def test_deployment(domain: str, use_https: bool = True):
    """
    Test the deployed MCP server
    
    Args:
        domain: The domain name (e.g., zmcp.qandu.me)
        use_https: Whether to use HTTPS (default: True)
    """
    protocol = "https" if use_https else "http"
    url = f"{protocol}://{domain}/sse"
    
    print(f"🔍 Testing deployment at: {url}")
    
    try:
        async with AsyncExitStack() as stack:
            # Connect to the MCP server
            print("📡 Connecting to MCP server...")
            streams_context = sse_client(url=url)
            streams = await stack.enter_async_context(streams_context)
            session = await stack.enter_async_context(ClientSession(*streams))
            
            # Initialize the session
            print("🔧 Initializing session...")
            await session.initialize()
            
            # List available tools
            print("🔨 Listing available tools...")
            response = await session.list_tools()
            tools = response.tools
            print(f"✅ Found {len(tools)} tools:")
            for tool in tools:
                print(f"   - {tool.name}: {tool.description}")
            
            # Test web search tool
            if any(tool.name == "web_search" for tool in tools):
                print("\n🔍 Testing web search tool...")
                test_query = "site:demandiq.com pricing"
                
                result = await session.call_tool("web_search", {
                    "query": test_query
                })
                
                print(f"✅ Web search successful!")
                print(f"📝 Query: {test_query}")
                print(f"📄 Results preview:")
                print(result.content[0].text[:300] + "..." if len(result.content[0].text) > 300 else result.content[0].text)
                
                return True
            else:
                print("❌ web_search tool not found!")
                return False
                
    except Exception as e:
        print(f"❌ Error during testing: {str(e)}")
        return False

async def test_health_check(domain: str, use_https: bool = True):
    """
    Test the health check endpoint
    
    Args:
        domain: The domain name
        use_https: Whether to use HTTPS
    """
    import httpx
    
    protocol = "https" if use_https else "http"
    url = f"{protocol}://{domain}/health"
    
    print(f"🏥 Testing health check at: {url}")
    
    try:
        async with httpx.AsyncClient(verify=not use_https) as client:
            response = await client.get(url)
            if response.status_code == 200:
                print("✅ Health check passed!")
                print(f"📄 Response: {response.text}")
                return True
            else:
                print(f"❌ Health check failed with status: {response.status_code}")
                return False
    except Exception as e:
        print(f"❌ Health check error: {str(e)}")
        return False

async def main():
    parser = argparse.ArgumentParser(description="Test Zhipu MCP Server deployment")
    parser.add_argument("--domain", default="zmcp.qandu.me", 
                       help="Domain to test (default: zmcp.qandu.me)")
    parser.add_argument("--no-https", action="store_true", 
                       help="Use HTTP instead of HTTPS")
    parser.add_argument("--skip-health", action="store_true", 
                       help="Skip health check")
    
    args = parser.parse_args()
    
    print("🚀 Starting deployment test...")
    print("=" * 50)
    
    use_https = not args.no_https
    
    # Test health check
    if not args.skip_health:
        health_ok = await test_health_check(args.domain, use_https)
        if not health_ok:
            print("\n❌ Health check failed. Please check your deployment.")
            sys.exit(1)
        print()
    
    # Test MCP functionality
    mcp_ok = await test_deployment(args.domain, use_https)
    
    print("\n" + "=" * 50)
    if mcp_ok:
        print("🎉 All tests passed! Your deployment is working correctly.")
        print(f"\n📋 MCP Client Configuration:")
        print(f"{{")
        print(f'    "mcpServers": {{')
        print(f'        "zhipu-web-search": {{')
        print(f'            "url": "{('https' if use_https else 'http')}://{args.domain}/sse"')
        print(f'        }}')
        print(f'    }}')
        print(f"}}")
    else:
        print("❌ Some tests failed. Please check your deployment.")
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main())