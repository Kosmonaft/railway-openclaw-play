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


# Clean up stale Chromium lock/singleton files from previous container runs
find /data -name "SingletonLock" -delete 2>/dev/null || true
find /data -name "SingletonCookie" -delete 2>/dev/null || true
find /data -name "SingletonSocket" -delete 2>/dev/null || true
find /tmp -name "SingletonLock" -delete 2>/dev/null || true

# Ensure Playwright browsers are accessible by openclaw user
if [ -d /ms-playwright ]; then
  chown -R openclaw:openclaw /ms-playwright
fi

# Set browser executable path for OpenClaw browser tool
CHROMIUM_PATH=$(find /ms-playwright -name "chromium" -o -name "chrome" -type f 2>/dev/null | grep -E "chrome$|chromium$" | head -1)
if [ -n "$CHROMIUM_PATH" ]; then
  echo "[entrypoint] Found Chromium at: $CHROMIUM_PATH"
else
  # Fallback: standard Playwright chromium location
  CHROMIUM_PATH=$(find /ms-playwright -path "*/chrome-linux/chrome" 2>/dev/null | head -1)
  if [ -z "$CHROMIUM_PATH" ]; then
    CHROMIUM_PATH=$(find /ms-playwright -path "*/chromium-*/chrome-linux/chrome" 2>/dev/null | head -1)
  fi
  echo "[entrypoint] Chromium fallback path: $CHROMIUM_PATH"
fi

if [ -n "$CHROMIUM_PATH" ]; then
  export CHROMIUM_EXECUTABLE_PATH="$CHROMIUM_PATH"
  echo "[entrypoint] Setting browser.executablePath to $CHROMIUM_PATH"
  # Inject into OpenClaw config
  OPENCLAW_CONFIG="/data/.openclaw/openclaw.json"
  if [ -f "$OPENCLAW_CONFIG" ]; then
    # Use node to safely merge the executablePath into existing config
    node -e "
      const fs = require('fs');
      const cfg = JSON.parse(fs.readFileSync('$OPENCLAW_CONFIG', 'utf8'));
      cfg.browser = cfg.browser || {};
      cfg.browser.executablePath = '$CHROMIUM_PATH';
      cfg.browser.enabled = true;
      cfg.browser.noSandbox = true;
      cfg.browser.headless = true;
      fs.writeFileSync('$OPENCLAW_CONFIG', JSON.stringify(cfg, null, 2));
    "
    echo "[entrypoint] Browser config injected into openclaw.json"
  fi
fi

# Copy workspace skills into the data volume so OpenClaw can find them (always overwrite)
echo "[entrypoint] Skills in /app/skills/: $(ls /app/skills/ 2>&1)"
if [ -d /app/skills ]; then
  mkdir -p /data/workspace/skills
  cp -rf /app/skills/. /data/workspace/skills/
  chown -R openclaw:openclaw /data/workspace/skills
  echo "[entrypoint] Skills copied to /data/workspace/skills/: $(ls /data/workspace/skills/ 2>&1)"
fi

# Copy instruction files to workspace (always overwrite — these are our rules)
for f in BOOTSTRAP.md AGENTS.md; do
  if [ -f "/app/$f" ]; then
    cp "/app/$f" "/data/workspace/$f"
    chown openclaw:openclaw "/data/workspace/$f"
  fi
done

# Copy IDENTITY.md and USER.md only if not already present
# (allows Alfred to update them over time without losing changes on redeploy)
if [ -f /app/SOUL.md ] && [ ! -f /data/workspace/SOUL.md ]; then
  cp /app/SOUL.md /data/workspace/SOUL.md
  chown openclaw:openclaw /data/workspace/SOUL.md
fi

if [ -f /app/IDENTITY.md ] && [ ! -f /data/workspace/IDENTITY.md ]; then
  cp /app/IDENTITY.md /data/workspace/IDENTITY.md
  chown openclaw:openclaw /data/workspace/IDENTITY.md
fi

if [ -f /app/USER.md ] && [ ! -f /data/workspace/USER.md ]; then
  cp /app/USER.md /data/workspace/USER.md
  chown openclaw:openclaw /data/workspace/USER.md
fi

exec gosu openclaw node src/server.js
