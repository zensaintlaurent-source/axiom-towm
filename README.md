# Hermes Agent Infrastructure

This repository contains the infrastructure for the Hermes Agent, an AI agent deployed in Axiom Town as part of the Gastown rig.

## Directory Structure

- `hermes/` - Contains the main Hermes agent code
- `configs/` - Configuration files
- `scripts/` - Utility scripts
- `tests/` - Unit tests
- `.env.example` - Example environment variables

## Components

### Hermes Agent (`hermes/hermes_agent.py`)

A FastAPI-based agent that:
- Provides a `/health` endpoint for health checks
- Provides a `/chat` endpoint for interacting with Ollama models (Qwen 2.5 14B/32B)
- Uses environment-based configuration

### Configuration

- `.env.example` - Example environment variables:
  - `OLLAMA_HOST`: Ollama server URL
  - `OLLAMA_MODEL`: Default Ollama model to use
  - `CLOUDFLARE_TOKEN`: Cloudflare API token for Tunnel
  - `POSTGRES_USER`: PostgreSQL username (default: hermes)
  - `POSTGRES_PASSWORD`: PostgreSQL password (default: hermes_pass)
  - `POSTGRES_DB`: PostgreSQL database name (default: hermes_db)
  - `CLOUDFLARE_SUBDOMAIN`: Subdomain for Cloudflare Tunnel (default: hermes-agent)

- `configs/models.yaml` - Model routing rules and preferences

### Scripts

- `scripts/setup_tunnel.sh` - Automates Cloudflare Tunnel setup

### Tests

- `tests/test_hermes_agent.py` - Unit tests for the FastAPI endpoints

### Containerization

- `Dockerfile` - Builds the Hermes agent image
- `docker-compose.yml` - Defines services for Ollama, Postgres, and Hermes agent

## Usage

### Local Development

1. Copy `.env.example` to `.env` and fill in the values
2. Install dependencies: `pip install -r requirements.txt`
3. Start Ollama (ensure it's running on the host specified in `.env`)
4. Run tests: `pytest tests/`
5. Start the agent: `uvicorn hermes.hermes_agent:app --reload`

### Using Docker Compose

1. Copy `.env.example` to `.env` and fill in the values (especially `CLOUDFLARE_TOKEN`)
2. Start all services: `docker-compose up -d`
3. The Hermes agent will be available at `http://localhost:8000`

### Cloudflare Tunnel Setup

The agent is designed to be reachable via Cloudflare Tunnel at `agent.<your-subdomain>.dev`.

1. Ensure you have a domain and Cloudflare account
2. Set `CLOUDFLARE_TOKEN` and optionally `CLOUDFLARE_SUBDOMAIN` in your `.env`
3. Run the setup script: `bash scripts/setup_tunnel.sh`
4. Follow the script's output to complete the DNS setup and start the tunnel

## API Endpoints

### GET `/health`
Returns the health status of the agent and its connection to Ollama.

### POST `/chat`
Chat with the Hermes agent.

**Request Body:**
```json
{
  "message": "Your message here",
  "model": "qwen2.5:14b", // optional, defaults to OLLAMA_HOST
  "temperature": 0.7,     // optional
  "max_tokens": 100       // optional
}
```

**Response:**
```json
{
  "response": "The agent's response",
  "model": "qwen2.5:14b",
  "tokens_used": 50
}
```

## Environment Variables

- `OLLAMA_HOST` (default: `http://localhost:11434`)
- `OLLAMA_MODEL` (default: `qwen2.5:14b`)
- `POSTGRES_USER` (default: `hermes`)
- `POSTGRES_PASSWORD` (default: `hermes_pass`)
- `POSTGRES_DB` (default: `hermes_db`)
- `CLOUDFLARE_TOKEN` (required for tunnel setup)
- `CLOUDFLARE_SUBDOMAIN` (optional, defaults to `hermes-agent`)

## Model Configuration

See `configs/models.yaml` for model routing rules. The system supports:
- Qwen 2.5 14B (default, balanced performance)
- Qwen 2.5 32B (for complex reasoning tasks)

## Notes

- The agent requires Ollama to be running and accessible at the specified host.
- For production use, ensure proper security measures are in place (firewall, secrets management, etc.).
- The Cloudflare Tunnel setup script provides guidance for installation without assuming root access.
- Database credentials are configurable via environment variables for security.