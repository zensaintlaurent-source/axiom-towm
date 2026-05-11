#!/bin/bash
# Cloudflare Tunnel Setup Script for Hermes Agent

# Exit on any error
set -e

echo "Setting up Cloudflare Tunnel for Hermes Agent..."

# Check if cloudflared is installed
if ! command -v cloudflared &> /dev/null; then
    echo "cloudflared not found. Installing..."
    # Install cloudflared based on OS (without assuming root/sudo)
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux - try to install without sudo, user may need to handle permissions
        echo "For Linux, please install cloudflared manually:"
        echo "  wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb"
        echo "  sudo dpkg -i cloudflared-linux-amd64.deb"
        echo "Or follow instructions at: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation"
        exit 1
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install cloudflared
        else
            echo "Homebrew not found. Please install Homebrew first, then run: brew install cloudflared"
            echo "Or follow instructions at: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation"
            exit 1
        fi
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
  - hostname: agent.\${CLOUDFLARE_SUBDOMAIN:-hermes-agent}.dev
    service: http://localhost:8000
  - service: http_status:404
EOF

# Set up DNS record (if using a domain)
echo "To complete the setup, you need to:"
echo "1. Choose a subdomain for your agent (e.g., hermes-agent)"
echo "2. Set the CLOUDFLARE_SUBDOMAIN environment variable to your chosen subdomain"
echo "3. Add a DNS record: Create a CNAME record for agent.<your-subdomain>.<your-domain>.dev pointing to your Cloudflare Tunnel"
echo "4. Run: cloudflared tunnel route dns $TUNNEL_NAME agent.\${CLOUDFLARE_SUBDOMAIN:-hermes-agent}.dev"
echo "5. Start the tunnel: cloudflared tunnel run $TUNNEL_NAME"

echo "Setup complete! Remember to:"
echo "- Set CLOUDFLARE_SUBDOMAIN environment variable (default: hermes-agent)"
echo "- Start your Hermes agent: uvicorn hermes.hermes_agent:app --host 0.0.0.0 --port 8000"
echo "- Run the tunnel: cloudflared tunnel run $TUNNEL_NAME"
echo ""
echo "Example usage:"
echo "  export CLOUDFLARE_SUBDOMAIN=myhermes"
echo "  export CLOUDFLARE_TOKEN=your_token_here"
echo "  ./scripts/setup_tunnel.sh"