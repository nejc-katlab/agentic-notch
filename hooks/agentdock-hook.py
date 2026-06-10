#!/usr/bin/env python3
"""AgentDock hook for Claude Code.

Reads a hook event JSON from stdin and writes/updates
~/.agentdock/sessions/{session_id}.json with the current state.
Wire from ~/.claude/settings.json — see hooks/install.sh.
"""
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path.home() / ".agentdock" / "sessions"
ROOT.mkdir(parents=True, exist_ok=True)


def find_git_root(start: str) -> str | None:
    p = Path(start).resolve()
    for parent in [p, *p.parents]:
        if (parent / ".git").exists():
            return str(parent)
    return None


def derive_project(cwd: str | None) -> str | None:
    if not cwd:
        return None
    root = find_git_root(cwd) or cwd
    return Path(root).name


def derive_tty() -> str | None:
    """Walk up the parent chain looking for the controlling TTY of the Claude
    Code process. The hook's own PPID is Claude Code, but we walk further in
    case there's a wrapper. Returns the device path like '/dev/ttys001'."""
    try:
        pid = os.getppid()
        for _ in range(8):
            if pid <= 1:
                break
            out = subprocess.run(
                ["ps", "-o", "tty=,ppid=", "-p", str(pid)],
                capture_output=True, text=True, timeout=1,
            ).stdout.strip()
            if not out:
                break
            parts = out.split()
            tty = parts[0] if parts else "?"
            ppid = int(parts[1]) if len(parts) > 1 else 1
            if tty and tty != "?" and tty != "??":
                return f"/dev/{tty}" if not tty.startswith("/dev/") else tty
            pid = ppid
    except Exception:
        return None
    return None


def map_event(event: str, payload: dict) -> tuple[str, str | None, bool]:
    """Return (state, activity, needs_attention)."""
    tool = payload.get("tool_name")
    tool_input = payload.get("tool_input") or {}
    if event == "SessionStart":
        return "working", "Session started", False
    if event == "UserPromptSubmit":
        return "working", "Thinking…", False
    if event == "PreToolUse":
        return "working", _describe_tool(tool, tool_input, prefix="Running"), False
    if event == "PostToolUse":
        return "working", _describe_tool(tool, tool_input, prefix="Finished"), False
    if event == "Notification":
        msg = (payload.get("message") or "").lower()
        if "permission" in msg or "approve" in msg:
            return "needs-permission", payload.get("message"), True
        if "waiting" in msg or "idle" in msg or not msg:
            return "idle", payload.get("message") or "Waiting for your input", False
        return "needs-input", payload.get("message"), True
    if event == "Stop":
        return "idle", "Turn ended", False
    if event == "SessionEnd":
        return "done", "Session ended", False
    return "working", event, False


def _describe_tool(tool: str | None, tool_input: dict, *, prefix: str) -> str:
    if not tool:
        return prefix
    if tool in ("Edit", "Write", "Read"):
        path = tool_input.get("file_path") or tool_input.get("path") or ""
        short = os.path.basename(path) if path else ""
        return f"{prefix} {tool} {short}".strip()
    if tool == "Bash":
        cmd = (tool_input.get("command") or "").strip().splitlines()[0] if tool_input.get("command") else ""
        cmd = re.sub(r"\s+", " ", cmd)[:60]
        return f"{prefix} `{cmd}`" if cmd else f"{prefix} bash"
    return f"{prefix} {tool}"


def main() -> int:
    try:
        raw = sys.stdin.read()
        payload = json.loads(raw) if raw.strip() else {}
    except json.JSONDecodeError:
        return 0

    event = payload.get("hook_event_name") or os.environ.get("AGENTDOCK_EVENT") or "Unknown"
    session_id = payload.get("session_id") or os.environ.get("CLAUDE_SESSION_ID") or "unknown"
    cwd = payload.get("cwd") or os.getcwd()

    state, activity, needs_attention = map_event(event, payload)

    record = {
        "tool": "claude-code",
        "sessionId": session_id,
        "state": state,
        "project": derive_project(cwd),
        "cwd": cwd,
        "activity": activity,
        "needsAttention": needs_attention,
        "ts": time.time(),
        "tty": derive_tty(),
        "pid": os.getppid(),
        "termProgram": os.environ.get("TERM_PROGRAM"),
        "warpFocusUrl": os.environ.get("WARP_FOCUS_URL"),
        "termSessionId": os.environ.get("TERM_SESSION_ID") or os.environ.get("ITERM_SESSION_ID"),
    }

    target = ROOT / f"{session_id}.json"
    tmp = target.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(record, indent=2))
    tmp.replace(target)

    if event == "SessionEnd":
        try:
            time.sleep(0)
            target.unlink(missing_ok=True)
        except OSError:
            pass

    return 0


if __name__ == "__main__":
    sys.exit(main())
