#!/usr/bin/env bash
# Wire the AgentDock hook into ~/.codex/hooks.json for all events.
# Idempotent: safe to run repeatedly. Backs up hooks.json each run.
set -euo pipefail

HOOK_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/agentdock-codex-hook.py"
INSTALL_DIR="$HOME/.agentdock"
HOOK_DEST="$INSTALL_DIR/agentdock-codex-hook.py"
HOOKS_FILE="$HOME/.codex/hooks.json"

mkdir -p "$INSTALL_DIR" "$INSTALL_DIR/codex" "$(dirname "$HOOKS_FILE")"
cp "$HOOK_SRC" "$HOOK_DEST"
chmod +x "$HOOK_DEST"

if [[ ! -f "$HOOKS_FILE" ]]; then
  echo '{}' > "$HOOKS_FILE"
fi

cp "$HOOKS_FILE" "$HOOKS_FILE.bak.$(date +%s)"

python3 - "$HOOKS_FILE" "$HOOK_DEST" <<'PY'
import json, sys, pathlib
hooks_path = pathlib.Path(sys.argv[1])
hook = sys.argv[2]
data = json.loads(hooks_path.read_text() or "{}")
hooks = data.setdefault("hooks", {})

EVENTS = [
    "SessionStart", "UserPromptSubmit", "PreToolUse", "PostToolUse",
    "PermissionRequest", "Stop",
]

for event in EVENTS:
    bucket = hooks.setdefault(event, [])
    if not isinstance(bucket, list):
        bucket = []
        hooks[event] = bucket
    has_ours = False
    for entry in bucket:
        for h in entry.get("hooks", []) if isinstance(entry, dict) else []:
            if h.get("command", "").endswith("agentdock-codex-hook.py"):
                h["command"] = f"python3 {hook}"
                if event == "PermissionRequest":
                    h["timeout"] = 60
                has_ours = True
    if not has_ours:
        ours = {"type": "command", "command": f"python3 {hook}"}
        if event == "PermissionRequest":
            ours["timeout"] = 60
        bucket.append({"hooks": [ours]})

hooks_path.write_text(json.dumps(data, indent=2))
print(f"Wired AgentDock hook into {hooks_path}")
PY

echo "Installed hook at $HOOK_DEST"
echo "Codex sessions will appear in $INSTALL_DIR/codex/"
