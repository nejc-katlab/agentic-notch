# Contributing to AgentDock

## Build

```sh
swift build             # debug
swift run AgentDock     # build and launch
scripts/build-app.sh    # release .app + zip in dist/
```

No dependencies beyond the Swift toolchain (macOS 13+, Swift 5.9+).

## Testing changes

There is no UI test suite; verify by running the app. You can simulate agent sessions without running any agent by writing JSON files:

```sh
python3 - <<'PY'
import json, time, pathlib
p = pathlib.Path.home() / ".agentdock/sessions/demo.json"
p.write_text(json.dumps({
    "tool": "claude-code", "sessionId": "demo", "state": "working",
    "project": "demo-project", "cwd": "/tmp", "activity": "Doing things",
    "needsAttention": False, "ts": time.time(),
}))
PY
```

States: `working`, `idle`, `needs-permission`, `needs-input`, `done`. Sessions older than 600 s are culled; running sessions older than 120 s are shown as idle.

Hook behavior can be tested by piping a crafted event into a hook script:

```sh
echo '{"hook_event_name":"PreToolUse","session_id":"demo","cwd":"/tmp","permission_mode":"default","tool_name":"Bash","tool_input":{"command":"ls"}}' \
  | python3 hooks/agentdock-hook.py
```

## Code style

- No code comments. Identifier names carry the meaning.
- Sort imports by line length, shortest first.
- Match the existing SwiftUI patterns (plain `ObservableObject` stores, small private subviews).

## Adding an agent source

1. Write an adapter (hook/plugin in the agent's own extension mechanism) that writes `~/.agentdock/<tag>/{sessionId}.json` in the `AgentSession` schema (`Sources/AgentDock/Model/AgentSession.swift`).
2. Register `FileWatchingSource(tag: "<tag>", directory: AgentDockPaths.sourceDir("<tag>"))` in `App.swift`.
3. Add an installer script `hooks/install-<tag>.sh` (idempotent, backs up any config it edits).
4. Add an icon entry in `ToolIcon.swift` (SVG path data, 24×24 viewBox) and a row to the README's supported-agents table. Unknown tools fall back to a two-letter glyph.

## Releases (maintainers)

Tag `vX.Y.Z` and push; GitHub Actions builds the universal app bundle and attaches the zip + sha256 to the release. Update `packaging/agentdock.rb` (version + sha256) and copy it into the tap repo.
