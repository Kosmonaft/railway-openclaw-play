#!/bin/bash
# Healthcheck: verify OpenClaw daemon is running
if pgrep -x "node" > /dev/null; then
  exit 0
else
  exit 1
fi
