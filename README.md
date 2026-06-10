# AgentDock

A macOS menu-bar-less **notch overlay** that shows your running AI coding agents at a glance. AgentDock lives in the MacBook notch (with a rounded-panel fallback on non-notched displays) and surfaces each agent session — its project, current activity, working/idle state, and whether it needs your attention — without taking up a window.

Built for [Claude Code](https://claude.com/claude-code), with a pluggable source model for other agents.

## Features

- **Live session strip** in the notch — expands on hover to a full panel.
- **Per-session state**: working (animated), idle, and an attention flag when an agent is waiting on you.
- **Auto-expand on attention** so you notice when an agent needs input.
- **Quick reveal**: click a session to open a terminal at its working directory.
- **Sleep prevention**: keep your Mac awake while agents are active and/or need attention (Off / Active / Attn / Both).
- **Launch at login**.
- Single-instance, accessory app (no Dock icon, no menu bar item).

## Requirements

- macOS 13 (Ventura) or later
- Swift 5.9+ toolchain (Xcode or the Swift command-line tools)

## Build & run

```sh
swift build            # debug build
swift run AgentDock     # build and launch
```

The app runs as an accessory (no Dock icon). It auto-detects the notch geometry; on displays without a notch it falls back to a rounded panel under the menu bar.

## Connecting Claude Code

AgentDock reads session state that Claude Code writes via a hook. Install the hook once:

```sh
./hooks/install.sh
```

This copies `agentdock-hook.py` to `~/.agentdock/` and wires it into `~/.claude/settings.json` for all Claude Code events (idempotent; backs up your settings each run). Session files are written to `~/.agentdock/sessions/`, which AgentDock watches. Start (or restart) a Claude Code session and it will appear in the dock.

## Project layout

```
Sources/AgentDock/
  App.swift              # entry point, single-instance guard, app delegate
  AgentSources/          # pluggable agent sources (ClaudeCodeSource, AgentSource protocol)
  Model/                 # AgentStore, sessions, panel state, sleep modes
  Services/              # screen geometry, launch-at-login, sleep manager, persistence
  Views/                 # SwiftUI: notch panel, rows, strip, settings
  Window/                # borderless passthrough notch window
hooks/
  agentdock-hook.py      # Claude Code hook that emits session state
  install.sh             # wires the hook into ~/.claude/settings.json
```
