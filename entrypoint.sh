#!/bin/bash
set -e

chown -R openclaw:openclaw /data
chmod 700 /data

if [ ! -d /data/.linuxbrew ]; then
  cp -a /home/linuxbrew/.linuxbrew /data/.linuxbrew
fi

rm -rf /home/linuxbrew/.linuxbrew
ln -sfn /data/.linuxbrew /home/linuxbrew/.linuxbrew

# Inject Gemini API key from environment variable if set
if [ -n "$GEMINI_API_KEY" ]; then
  gosu openclaw node "$OPENCLAW_ENTRY" config set auth.profiles.google:default.apiKey "$GEMINI_API_KEY" || true
fi

exec gosu openclaw node src/server.js
