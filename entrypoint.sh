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

# Inject systemPrompt into openclaw.json (wait for file to exist after first boot)
OPENCLAW_CONFIG="/data/.openclaw/openclaw.json"
mkdir -p /data/.openclaw
if [ -f "$OPENCLAW_CONFIG" ]; then
  node -e "
    const fs = require('fs');
    const cfg = JSON.parse(fs.readFileSync('$OPENCLAW_CONFIG', 'utf8'));
    cfg.agents = cfg.agents || {};
    cfg.agents.defaults = cfg.agents.defaults || {};
    cfg.agents.defaults.systemPrompt = 'You are Alfred, a personal AI assistant for Pawel. You help with travel research (finding the best SYD->Wroclaw flights for August 2026) and weekly grocery planning. You communicate via Telegram. Be concise, direct, and proactive. When you come online, greet Pawel briefly and report any updates.';
    fs.writeFileSync('$OPENCLAW_CONFIG', JSON.stringify(cfg, null, 2));
  "
  chown openclaw:openclaw "$OPENCLAW_CONFIG"
else
  echo "[entrypoint] openclaw.json not found yet - systemPrompt will be injected on next restart"
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
