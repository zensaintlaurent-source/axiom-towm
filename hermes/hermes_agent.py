import os
import uvicorn
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional, List
import ollama
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

app = FastAPI(title="Hermes Agent", description="AI Agent for Axiom Town")

# Ollama client configuration
OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://localhost:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "qwen2.5:14b")  # default to 14B, can be overridden

# Initialize Ollama client
ollama_client = ollama.Client(host=OLLAMA_HOST)

class ChatRequest(BaseModel):
    message: str
    model: Optional[str] = None
    temperature: Optional[float] = 0.7
    max_tokens: Optional[int] = None

class ChatResponse(BaseModel):
    response: str
    model: str
    tokens_used: Optional[int] = None

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    try:
        # Check Ollama connection
        models = ollama_client.list()
        return {"status": "healthy", "ollama": "connected", "models_available": len(models.get('models', []))}
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Ollama connection failed: {str(e)}")

@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """Chat endpoint for interacting with the Ollama model"""
    try:
        model_to_use = request.model or OLLAMA_MODEL
        response = ollama_client.generate(
            model=model_to_use,
            prompt=request.message,
            options={
                "temperature": request.temperature,
                "num_predict": request.max_tokens
            } if request.max_tokens else {"temperature": request.temperature}
        )
        return ChatResponse(
            response=response['response'],
            model=model_to_use,
            tokens_used=response.get('eval_count')
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to generate response: {str(e)}")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)