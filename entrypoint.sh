#!/bin/bash
set -e

chown -R openclaw:openclaw /data
chmod 700 /data

if [ ! -d /data/.linuxbrew ]; then
  cp -a /home/linuxbrew/.linuxbrew /data/.linuxbrew
fi

rm -rf /home/linuxbrew/.linuxbrew
ln -sfn /data/.linuxbrew /home/linuxbrew/.linuxbrew

# Inject Gemini API key from environment variable into auth-profiles.json
if [ -n "$GEMINI_API_KEY" ]; then
  AUTH_PROFILES_DIR="/data/.openclaw/agents/main/agent"
  AUTH_PROFILES_FILE="$AUTH_PROFILES_DIR/auth-profiles.json"
  mkdir -p "$AUTH_PROFILES_DIR"
  chown -R openclaw:openclaw "$AUTH_PROFILES_DIR"
  gosu openclaw bash -c "cat > '$AUTH_PROFILES_FILE' << 'EOF'
{
  \"google:default\": {
    \"provider\": \"google\",
    \"mode\": \"api_key\",
    \"key\": \"$GEMINI_API_KEY\"
  }
}
EOF"
fi


# Copy workspace skills into the data volume so OpenClaw can find them
if [ -d /app/skills ]; then
  mkdir -p /data/workspace/skills
  cp -r /app/skills/. /data/workspace/skills/
  chown -R openclaw:openclaw /data/workspace/skills
fi

# Copy BOOTSTRAP.md to workspace for agent persona
if [ -f /app/BOOTSTRAP.md ]; then
  cp /app/BOOTSTRAP.md /data/workspace/BOOTSTRAP.md
  chown openclaw:openclaw /data/workspace/BOOTSTRAP.md
fi

exec gosu openclaw node src/server.js
