# AgentDock

A macOS **notch overlay** that shows your running AI coding agents at a glance. AgentDock lives in the MacBook notch (with a rounded-panel fallback on non-notched displays) and surfaces each agent session — its project, current activity, working/idle state, and whether it needs your attention — without taking up a window.

> Hero GIF coming soon — run it and hover the notch.

Native SwiftUI, zero dependencies, zero telemetry. Everything stays in `~/.agentdock`.

## Privacy

**AgentDock runs entirely on your machine and never sends data anywhere.** There are no servers, no analytics, no telemetry, no network calls of any kind — the app has no networking code at all. Everything works through local files: agent hooks write session JSON into `~/.agentdock/`, and the app reads it. Permission approve/deny, stats, and history all stay on disk under `~/.agentdock/` and are yours alone.

This repository is public, so you don't have to take our word for it — read the source (there's nothing reaching out to the internet) and check the hooks in `hooks/`.

## Features

- **Live session strip** in the notch — expands on hover to a full panel.
- **Approve / deny permission prompts from the notch** (Claude Code and Codex, opt-in).
- **Per-project time stats** — how long each project's agents have been working today, this week, or all time, plus session and attention-wait counts.
- **Multi-agent**: Claude Code, Codex CLI, Gemini CLI, OpenCode (experimental).
- **Per-session state**: working (animated), idle, and an attention flag when an agent is waiting on you.
- **Auto-expand on attention** so you notice when an agent needs input.
- **Quick reveal**: click a session to open a terminal at its working directory.
- **Sleep prevention**: keep your Mac awake while agents are active and/or need attention (Off / Active / Attn / Both).
- **Launch at login.**
- Single-instance, accessory app (no Dock icon, no menu bar item).

## Supported agents

| Agent | Status | Live state | In-notch approve/deny | Install |
|---|---|---|---|---|
| [Claude Code](https://claude.com/claude-code) | Stable | ✅ | ✅ (opt-in) | `hooks/install.sh` |
| [Codex CLI](https://developers.openai.com/codex) | Beta | ✅ | ✅ (opt-in) | `hooks/install-codex.sh` |
| [Gemini CLI](https://geminicli.com) | Beta | ✅ | — | `hooks/install-gemini.sh` |
| [OpenCode](https://opencode.ai) | Experimental | ✅ | — | `hooks/install-opencode.sh` |

## Install

### Download a release

Grab `AgentDock-<version>.zip` from [Releases](https://github.com/nejc-katlab/agentic-notch/releases), unzip, and move `AgentDock.app` to `/Applications`.

The app is **not notarized** (no paid developer certificate). On first launch either right-click → Open, or clear the quarantine flag:

```sh
xattr -dr com.apple.quarantine /Applications/AgentDock.app
```

### Homebrew

```sh
brew tap nejc-katlab/tap
brew install --cask agentdock
```

(Same quarantine caveat applies; the cask prints it.)

### Build from source

Requires macOS 13+ and a Swift 5.9+ toolchain.

```sh
swift run AgentDock     # debug build and launch
scripts/build-app.sh    # release AgentDock.app + zip in dist/
```

## Connecting agents

AgentDock reads session state that each agent writes via a hook. Install once per agent (idempotent; each installer backs up the config it touches):

```sh
./hooks/install.sh           # Claude Code → ~/.claude/settings.json
./hooks/install-codex.sh     # Codex CLI  → ~/.codex/hooks.json
./hooks/install-gemini.sh    # Gemini CLI → ~/.gemini/settings.json
./hooks/install-opencode.sh  # OpenCode   → ~/.config/opencode/plugins/
```

Session files land in `~/.agentdock/<source>/`, which AgentDock watches. Start (or restart) an agent session and it appears in the dock.

## Permission approve/deny

Toggle **Approve in notch** in the settings panel. While enabled:

- **Claude Code**: every tool call pauses briefly in the notch with Allow / Deny / "decide in terminal" buttons. If you don't respond within 45 s the normal terminal prompt takes over. Note: tool calls that your allowlist would auto-approve also pause — that's why this is opt-in.
- **Codex**: only real permission prompts are intercepted (Codex exposes a dedicated `PermissionRequest` hook), so there's no extra latency on auto-approved tools.

Decisions are exchanged through files in `~/.agentdock/permissions/` — local only, no network.

## Stats

Hover the notch and hit the chart icon. AgentDock records working/attention intervals to `~/.agentdock/history.jsonl` (append-only JSONL, yours to analyze) and aggregates active time, session counts, and attention waits per project for today / 7 days / all time. Recording happens in the app, so time only accrues while AgentDock is running.

## Project layout

```
Sources/AgentDock/
  App.swift              # entry point, single-instance guard, app delegate
  AgentSources/          # AgentSource protocol + generic file-watching source
  Model/                 # AgentStore, sessions, permission requests, panel state
  Services/              # geometry, sleep, persistence, history, stats, permissions
  Views/                 # SwiftUI: notch panel, rows, strip, settings, stats
  Window/                # borderless passthrough notch window
hooks/
  agentdock-hook.py        # Claude Code hook
  agentdock-codex-hook.py  # Codex CLI hook
  agentdock-gemini-hook.py # Gemini CLI hook
  opencode-plugin/         # OpenCode plugin (experimental)
  install*.sh              # per-agent installers
scripts/                   # release build (app bundle + zip)
packaging/                 # Homebrew cask template
```

## Adding an agent source

Any tool that can run a hook can feed AgentDock: write JSON files to `~/.agentdock/<your-tag>/{sessionId}.json` matching the schema in `Sources/AgentDock/Model/AgentSession.swift` and register a `FileWatchingSource` in `App.swift`. See `hooks/agentdock-gemini-hook.py` for a minimal adapter.

## Roadmap

- Theming and appearance options (accent color, panel sizing, fallback styles)
- Token/cost usage stats
- System notifications on completion
- Broader terminal/IDE jump-back (tmux panes, JetBrains, Zed)
- Cursor, Droid, and more agent sources

## License

[MIT](LICENSE)
