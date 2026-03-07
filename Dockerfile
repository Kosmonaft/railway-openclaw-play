FROM node:20-slim

# Install OpenClaw globally
RUN npm install -g openclaw

# Create app directory
WORKDIR /app

# Create non-root user
RUN groupadd --gid 1001 openclaw && \
    useradd --uid 1001 --gid openclaw --shell /bin/bash --create-home openclaw

# Copy project files
COPY --chown=openclaw:openclaw openclaw.json ./
COPY --chown=openclaw:openclaw skills/ ./skills/
COPY --chown=openclaw:openclaw scripts/ ./scripts/

# Ensure data directory exists and is writable
RUN mkdir -p /app/data && chown openclaw:openclaw /app/data

RUN chmod +x /app/scripts/healthcheck.sh

USER openclaw

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD /app/scripts/healthcheck.sh

CMD ["openclaw", "start", "--headless"]
