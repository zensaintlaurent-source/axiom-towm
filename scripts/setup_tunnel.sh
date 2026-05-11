#!/bin/bash
# Cloudflare Tunnel Setup Script for Hermes Agent

# Exit on any error
set -e

echo "Setting up Cloudflare Tunnel for Hermes Agent..."

# Check if cloudflared is installed
if ! command -v cloudflared &> /dev/null; then
    echo "cloudflared not found. Installing..."
    # Install cloudflared based on OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
        sudo dpkg -i cloudflared-linux-amd64.deb
        rm cloudflared-linux-amd64.deb
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        brew install cloudflared
    else
        echo "Unsupported OS. Please install cloudflared manually from https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation"
        exit 1
    fi
fi

# Check if CLOUDFLARE_TOKEN is set
if [ -z "$CLOUDFLARE_TOKEN" ]; then
    echo "Error: CLOUDFLARE_TOKEN environment variable is not set."
    echo "Please set it in your .env file or export it before running this script."
    exit 1
fi

# Authenticate with Cloudflare
echo "Authenticating with Cloudflare..."
cloudflared tunnel login

# Create a tunnel for the Hermes agent
echo "Creating Cloudflare Tunnel..."
TUNNEL_NAME="hermes-agent"
cloudflared tunnel create $TUNNEL_NAME

# Get the tunnel ID
TUNNEL_ID=$(cloudflared tunnel list | grep $TUNNEL_NAME | awk '{print $1}')
echo "Tunnel created with ID: $TUNNEL_ID"

# Create a config file for the tunnel
mkdir -p ~/.cloudflared
cat > ~/.cloudflared/config.yml << EOF
tunnel: $TUNNEL_ID
credentials-file: /root/.cloudflared/${TUNNEL_ID}.json

ingress:
  - hostname: agent.\${HOSTNAME}.dev
    service: http://localhost:8000
  - service: http_status:404
EOF

# Set up DNS record (if using a domain)
echo "To complete the setup, you need to:"
echo "1. Add a DNS record for agent.<your-domain>.dev pointing to your Cloudflare Tunnel"
echo "2. Run: cloudflared tunnel route dns $TUNNEL_NAME agent.<your-domain>.dev"
echo "3. Start the tunnel: cloudflared tunnel run $TUNNEL_NAME"

echo "Setup complete! Remember to:"
echo "- Set HOSTNAME environment variable to your domain"
echo "- Start your Hermes agent: uvicorn hermes_agent:app --host 0.0.0.0 --port 8000"
echo "- Run the tunnel: cloudflared tunnel run $TUNNEL_NAME"