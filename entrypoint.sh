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

exec gosu openclaw node src/server.js
