#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
FastAPI server for Chinese Spelling Correction service.
Provides a simple HTTP API for text correction.
"""

from fastapi import FastAPI
from pydantic import BaseModel
from typing import Optional
import sys
import os

# Add parent directory to path for pycorrector import
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from pycorrector import MacBertCorrector

# Initialize the corrector
print("Loading MacBertCorrector model...")
model = MacBertCorrector()
print("Model loaded successfully!")

app = FastAPI(
    title="Chinese Spelling Correction API",
    description="A service for correcting Chinese text errors using MacBERT model",
    version="1.0.0"
)

class CorrectionRequest(BaseModel):
    text: str
    model_name: Optional[str] = None

class CorrectionResponse(BaseModel):
    source: str
    target: str
    errors: list

class BatchCorrectionRequest(BaseModel):
    texts: list[str]

class BatchCorrectionResponse(BaseModel):
    results: list[CorrectionResponse]

@app.get("/")
async def root():
    """Root endpoint with service info."""
    return {
        "service": "Chinese Spelling Correction",
        "version": "1.0.0",
        "status": "running",
        "endpoint": "/correct"
    }

@app.get("/health")
async def health():
    """Health check endpoint."""
    return {"status": "healthy"}

@app.post("/correct")
async def correct_text(request: CorrectionRequest):
    """Correct Chinese text errors."""
    result = model.correct(request.text)
    return CorrectionResponse(
        source=result["source"],
        target=result["target"],
        errors=result.get("errors", [])
    )

@app.post("/batch_correct")
async def batch_correct(request: BatchCorrectionRequest):
    """Batch correct multiple texts."""
    results = []
    for text in request.texts:
        result = model.correct(text)
        results.append(CorrectionResponse(
            source=result["source"],
            target=result["target"],
            errors=result.get("errors", [])
        ))
    return BatchCorrectionResponse(results=results)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "server:app",
        host="0.0.0.0",
        port=5001,
        reload=False
    )
