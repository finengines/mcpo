FROM python:3.12-slim-bookworm

# Install uv (from official binary), nodejs, npm, and git
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    gettext-base \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js and npm via NodeSource 
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Confirm npm and node versions (optional debugging info)
RUN node -v && npm -v

# Copy your mcpo source code (assuming in src/mcpo)
COPY . /app
WORKDIR /app

# Create virtual environment explicitly in known location
ENV VIRTUAL_ENV=/app/.venv
RUN uv venv "$VIRTUAL_ENV"
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Install mcpo (assuming pyproject.toml is properly configured)
RUN uv pip install . && rm -rf ~/.cache

# Verify mcpo installed correctly
RUN which mcpo

# Expose port (optional but common default)
EXPOSE 8000

# Create a startup script that handles environment variable substitution
RUN echo '#!/bin/bash' > /app/start.sh && \
    echo 'set -e' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Substitute environment variables in config.json' >> /app/start.sh && \
    echo 'envsubst < /app/config.json > /app/config.runtime.json' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start mcpo with the processed config and API key' >> /app/start.sh && \
    echo 'exec mcpo --config /app/config.runtime.json --api-key "${MCPO_API_KEY}"' >> /app/start.sh && \
    chmod +x /app/start.sh

# Use the startup script as entrypoint
ENTRYPOINT ["/app/start.sh"]