# -------- Stage 1: Builder --------
FROM python:3.10-slim AS builder

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git build-essential \
        libsndfile1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy requirements
COPY requirements.txt .

# Install dependencies
RUN pip install --upgrade pip && \
    pip install --no-cache-dir \
        torch torchaudio \
        --index-url https://download.pytorch.org/whl/cpu && \
    pip install --no-cache-dir -r requirements.txt


# -------- Stage 2: Runtime --------
FROM python:3.10-slim

# Runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ffmpeg \
        libsndfile1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy app + venv
COPY ./parakeet_service ./parakeet_service
COPY .env.example .env
COPY --from=builder /opt/venv /opt/venv

# Env variables
ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app \
    HF_HOME=/app/models

# Create models dir
RUN mkdir -p /app/models

EXPOSE 8000

CMD ["uvicorn", "parakeet_service.main:app", "--host", "0.0.0.0", "--port", "8000"]
