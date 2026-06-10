#!/usr/bin/env python3
"""AgentDock hook for Gemini CLI.

Reads a hook event JSON from stdin and writes/updates
~/.agentdock/gemini/{session_id}.json with the current state.
Wire from ~/.gemini/settings.json — see hooks/install-gemini.sh.
"""
import os
import re
import sys
import json
import time
from pathlib import Path

ROOT = Path.home() / ".agentdock" / "gemini"
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


def _describe_tool(tool: str | None, tool_input: dict, *, prefix: str) -> str:
    if not tool:
        return prefix
    if tool in ("run_shell_command", "shell"):
        cmd = re.sub(r"\s+", " ", str(tool_input.get("command") or "").strip())[:60]
        return f"{prefix} `{cmd}`" if cmd else f"{prefix} shell"
    if tool in ("write_file", "replace", "read_file"):
        path = tool_input.get("file_path") or tool_input.get("path") or ""
        short = os.path.basename(str(path)) if path else ""
        return f"{prefix} {tool} {short}".strip()
    return f"{prefix} {tool}"


def map_event(event: str, payload: dict) -> tuple[str, str | None, bool] | None:
    tool = payload.get("tool_name")
    tool_input = payload.get("tool_input") or {}
    if event == "SessionStart":
        return "working", "Session started", False
    if event == "BeforeAgent":
        return "working", "Thinking…", False
    if event == "BeforeTool":
        return "working", _describe_tool(tool, tool_input, prefix="Running"), False
    if event == "AfterTool":
        return "working", _describe_tool(tool, tool_input, prefix="Finished"), False
    if event == "Notification":
        if payload.get("notification_type") == "ToolPermission":
            return "needs-permission", payload.get("message") or "Needs permission", True
        return "needs-input", payload.get("message") or "Waiting for your input", True
    if event == "AfterAgent":
        return "idle", "Turn ended", False
    if event == "SessionEnd":
        return "done", "Session ended", False
    return None


def main() -> int:
    try:
        raw = sys.stdin.read()
        payload = json.loads(raw) if raw.strip() else {}
    except json.JSONDecodeError:
        return 0

    event = payload.get("hook_event_name") or "Unknown"
    session_id = payload.get("session_id") or os.environ.get("GEMINI_SESSION_ID") or "unknown"
    cwd = payload.get("cwd") or os.environ.get("GEMINI_CWD") or os.getcwd()

    mapped = map_event(event, payload)
    if mapped is None:
        return 0
    state, activity, needs_attention = mapped

    record = {
        "tool": "gemini",
        "sessionId": session_id,
        "state": state,
        "project": derive_project(cwd),
        "cwd": cwd,
        "activity": activity,
        "needsAttention": needs_attention,
        "ts": time.time(),
        "termProgram": os.environ.get("TERM_PROGRAM"),
        "termSessionId": os.environ.get("TERM_SESSION_ID") or os.environ.get("ITERM_SESSION_ID"),
    }

    target = ROOT / f"{session_id}.json"
    tmp = target.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(record, indent=2))
    tmp.replace(target)

    if event == "SessionEnd":
        try:
            target.unlink(missing_ok=True)
        except OSError:
            pass

    return 0


if __name__ == "__main__":
    sys.exit(main())
