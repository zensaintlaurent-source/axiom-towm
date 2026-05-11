import os
import sys
import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock

# Add the project root to the path so we can import the hermes module
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from hermes.hermes_agent import app

# Create a test client
client = TestClient(app)

def test_health_endpoint():
    """Test the health check endpoint"""
    with patch('hermes.hermes_agent.ollama_client') as mock_ollama:
        # Mock the Ollama client list method
        mock_ollama.list.return_value = {'models': [{'name': 'qwen2.5:14b'}]}
        
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert data["ollama"] == "connected"
        assert data["models_available"] == 1

def test_health_endpoint_ollama_failure():
    """Test the health check endpoint when Ollama is unavailable"""
    with patch('hermes.hermes_agent.ollama_client') as mock_ollama:
        # Mock the Ollama client list method to raise an exception
        mock_ollama.list.side_effect = Exception("Connection failed")
        
        response = client.get("/health")
        assert response.status_code == 503
        data = response.json()
        assert "detail" in data
        assert "Ollama connection failed" in data["detail"]

def test_chat_endpoint():
    """Test the chat endpoint"""
    with patch('hermes.hermes_agent.ollama_client') as mock_ollama:
        # Mock the Ollama client generate method
        mock_ollama.generate.return_value = {
            'response': 'Hello, how can I help you?',
            'eval_count': 10
        }
        
        response = client.post("/chat", json={
            "message": "Hello",
            "model": "qwen2.5:14b",
            "temperature": 0.7,
            "max_tokens": 50
        })
        assert response.status_code == 200
        data = response.json()
        assert data["response"] == "Hello, how can I help you?"
        assert data["model"] == "qwen2.5:14b"
        assert data["tokens_used"] == 10

def test_chat_endpoint_defaults():
    """Test the chat endpoint with default parameters"""
    with patch('hermes.hermes_agent.ollama_client') as mock_ollama:
        # Mock the Ollama client generate method
        mock_ollama.generate.return_value = {
            'response': 'Hello, how can I help you?',
            'eval_count': 10
        }
        
        response = client.post("/chat", json={
            "message": "Hello"
        })
        assert response.status_code == 200
        data = response.json()
        assert data["response"] == "Hello, how can I help you?"
        assert data["model"] == "qwen2.5:14b"  # default from OLLAMA_MODEL
        assert data["tokens_used"] == 10

def test_chat_endpoint_ollama_failure():
    """Test the chat endpoint when Ollama fails"""
    with patch('hermes.hermes_agent.ollama_client') as mock_ollama:
        # Mock the Ollama client generate method to raise an exception
        mock_ollama.generate.side_effect = Exception("Generation failed")
        
        response = client.post("/chat", json={
            "message": "Hello"
        })
        assert response.status_code == 500
        data = response.json()
        assert "detail" in data
        assert "Failed to generate response" in data["detail"]