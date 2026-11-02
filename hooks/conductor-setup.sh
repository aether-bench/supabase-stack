#!/bin/bash
# Conductor Cloud: repository setup script for supabase-stack. Runs on every new workspace.
set -euo pipefail
if ! sudo docker info >/dev/null 2>&1; then
  sudo nohup dockerd > /tmp/dockerd.log 2>&1 &
  for _ in $(seq 1 30); do sudo docker info >/dev/null 2>&1 && break; sleep 1; done
fi
sudo chmod 666 /var/run/docker.sock
npm ci
sh hooks/start.sh
