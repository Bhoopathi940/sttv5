# Stage 1: Builder
FROM python:3.10-slim AS builder

# Install build tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:${PATH}"

# Install CPU-specific dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    # Specifically install CPU versions of torch
    pip install torch torchaudio --index-url https://pytorch.org --no-cache-dir && \
    pip install --no-cache-dir -r requirements.txt

# Stage 2: Runtime
FROM python:3.10-slim

# Install ffmpeg (required for speech processing)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ffmpeg \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy application files based on your folder structure
COPY ./parakeet_service ./parakeet_service
COPY .env.example .env
COPY --from=builder /opt/venv /opt/venv

# Set environment variables
ENV PATH="/opt/venv/bin:${PATH}" \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app \
    HF_HOME=/app/models

# Create models directory for the volume
RUN mkdir -p /app/models

EXPOSE 8000

CMD ["uvicorn", "parakeet_service.main:app", "--host", "0.0.0.0", "--port", "8000"]
