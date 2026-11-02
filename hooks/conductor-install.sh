#!/bin/bash
# Conductor Cloud: organization install script (Settings → Cloud computer). Runs once per build with sudo.
# The microVM has no Docker and no systemd; the daemon is installed here and started by the setup script.
set -euo pipefail
sudo dnf install -y docker
sudo usermod -aG docker "$(id -un)"
cd supabase-stack && npm ci && npx supabase --version
