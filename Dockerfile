# syntax=docker/dockerfile:1.4

# ---------- Build-time arguments ---------------------------------------
ARG PYTHON_VERSION=3.10
ARG TORCH_INDEX_URL=https://download.pytorch.org/whl/cpu
ARG PIP_MIRROR=https://pypi.tuna.tsinghua.edu.cn/simple

# ---------- Builder stage ---------------------------------------------
FROM python:${PYTHON_VERSION}-slim AS builder
ARG PYTHON_VERSION=3.10
ARG TORCH_INDEX_URL=https://download.pytorch.org/whl/cpu
ARG PIP_MIRROR=https://pypi.tuna.tsinghua.edu.cn/simple
LABEL maintainer="XuMing <xuming624@qq.com>"

# Re-declare ARGs for the builder stage
ARG PYTHON_VERSION
ARG TORCH_INDEX_URL
ARG PIP_MIRROR

# Install packages required to compile wheels (gcc, libffi, etc.)
RUN apt-get update && apt-get install -y --no-install-recommends \
        gcc libffi-dev libssl-dev make && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user with a proper home directory (will be recreated in the final stage)
RUN addgroup --system appgroup && \
    adduser --system --ingroup appgroup --home /home/appuser appuser

# Environment variables to silence pip warnings and speed up installs
ENV PIP_ROOT_USER_ACTION=ignore \
    PYTHONUNBUFFERED=1 \
    PIP_DEFAULT_TIMEOUT=1200

WORKDIR /tmp
# Copy only what is needed for dependency resolution
COPY requirements.txt entrypoint.sh ./

# Ensure the entrypoint script has a proper shebang and Unix line endings
RUN sed -i '1s|^|#!/usr/bin/env bash\n|' entrypoint.sh && \
    chmod +x entrypoint.sh

# Install heavy Python wheels (torch, pycorrector, plus project deps)
RUN pip install --no-cache-dir torch --index-url ${TORCH_INDEX_URL} && \
    pip install --no-cache-dir -r requirements.txt -i ${PIP_MIRROR} && \
    pip install --no-cache-dir pycorrector -i ${PIP_MIRROR}

# ---------- Runtime stage ----------------------------------------------
FROM python:${PYTHON_VERSION}-slim
LABEL maintainer="XuMing <xuming624@qq.com>"

# Re-declare ARGs for the runtime stage
ARG PYTHON_VERSION
ARG TORCH_INDEX_URL
ARG PIP_MIRROR

ENV PIP_ROOT_USER_ACTION=ignore \
    PYTHONUNBUFFERED=1 \
    HOME=/home/appuser

# Re-create the same non-root user with a proper home directory
RUN addgroup --system appgroup && \
    adduser --system --ingroup appgroup --home /home/appuser appuser

# Application directory and log file
WORKDIR /app
RUN mkdir -p /var/log /home/appuser && \
    touch /var/log/app.log && \
    chown -R appuser:appgroup /app /var/log /home/appuser

# Copy installed packages from the builder stage
COPY --from=builder /usr/local/lib/python${PYTHON_VERSION}/site-packages /usr/local/lib/python${PYTHON_VERSION}/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy source code and the prepared entrypoint script
COPY . /app
COPY --from=builder /tmp/entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh && chown appuser:appgroup /app/entrypoint.sh

# Switch to non-root user for runtime
USER appuser

# Set the working directory where the example code lives
WORKDIR /app/examples

EXPOSE 5001

# Single, absolute entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]
