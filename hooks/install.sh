#!/usr/bin/env bash
# Wire the AgentDock hook into ~/.claude/settings.json for all events.
# Idempotent: safe to run repeatedly. Backs up settings.json each run.
set -euo pipefail

HOOK_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/agentdock-hook.py"
INSTALL_DIR="$HOME/.agentdock"
HOOK_DEST="$INSTALL_DIR/agentdock-hook.py"
SETTINGS="$HOME/.claude/settings.json"

mkdir -p "$INSTALL_DIR" "$INSTALL_DIR/sessions"
cp "$HOOK_SRC" "$HOOK_DEST"
chmod +x "$HOOK_DEST"

mkdir -p "$(dirname "$SETTINGS")"
if [[ ! -f "$SETTINGS" ]]; then
  echo '{}' > "$SETTINGS"
fi

cp "$SETTINGS" "$SETTINGS.bak.$(date +%s)"

python3 - "$SETTINGS" "$HOOK_DEST" <<'PY'
import json, sys, pathlib
settings_path = pathlib.Path(sys.argv[1])
hook = sys.argv[2]
data = json.loads(settings_path.read_text() or "{}")
hooks = data.setdefault("hooks", {})

EVENTS = [
    "SessionStart", "UserPromptSubmit", "PreToolUse", "PostToolUse",
    "Notification", "Stop", "SessionEnd",
]

for event in EVENTS:
    bucket = hooks.setdefault(event, [])
    if not isinstance(bucket, list):
        bucket = []
        hooks[event] = bucket
    has_ours = False
    for entry in bucket:
        for h in entry.get("hooks", []) if isinstance(entry, dict) else []:
            if h.get("command", "").endswith("agentdock-hook.py"):
                h["command"] = hook
                has_ours = True
    if not has_ours:
        bucket.append({
            "matcher": "*",
            "hooks": [{"type": "command", "command": hook}],
        })

settings_path.write_text(json.dumps(data, indent=2))
print(f"Wired AgentDock hook into {settings_path}")
PY

echo "Installed hook at $HOOK_DEST"
echo "Sessions will appear in $INSTALL_DIR/sessions/"
