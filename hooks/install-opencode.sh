#!/usr/bin/env bash
# Install the AgentDock OpenCode plugin (experimental).
# Idempotent: safe to run repeatedly.
set -euo pipefail

PLUGIN_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/opencode-plugin/agentdock.js"
PLUGIN_DIR="$HOME/.config/opencode/plugins"
INSTALL_DIR="$HOME/.agentdock"

mkdir -p "$PLUGIN_DIR" "$INSTALL_DIR/opencode"
cp "$PLUGIN_SRC" "$PLUGIN_DIR/agentdock.js"

echo "Installed plugin at $PLUGIN_DIR/agentdock.js"
echo "OpenCode sessions will appear in $INSTALL_DIR/opencode/"
