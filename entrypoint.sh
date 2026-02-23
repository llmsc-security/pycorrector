#!/usr/bin/env bash
set -euo pipefail

# Run the FastAPI server for MacBERT Chinese spelling correction
# The service listens on port 11000 (mapped port) inside the container

cd /app

# Create log directory if not exists
mkdir -p /var/log

# Start the FastAPI server
# Using 0.0.0.0 to bind to all interfaces for container accessibility
echo "Starting Chinese Spelling Correction service on port 11000..."
exec python server.py
