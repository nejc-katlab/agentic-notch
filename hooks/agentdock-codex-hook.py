#!/usr/bin/env python3
"""AgentDock hook for Codex CLI.

Reads a hook event JSON from stdin and writes/updates
~/.agentdock/codex/{session_id}.json with the current state.
Wire from ~/.codex/hooks.json — see hooks/install-codex.sh.
"""
import os
import re
import sys
import json
import time
import uuid
import subprocess
from pathlib import Path

ROOT = Path.home() / ".agentdock" / "codex"
ROOT.mkdir(parents=True, exist_ok=True)

PERM_ROOT = Path.home() / ".agentdock" / "permissions"
PERM_WAIT_SECONDS = 45


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


def app_running() -> bool:
    try:
        return subprocess.run(
            ["pgrep", "-x", "AgentDock"], capture_output=True, timeout=2
        ).returncode == 0
    except Exception:
        return False


def write_session(record: dict, target: Path) -> None:
    tmp = target.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(record, indent=2))
    tmp.replace(target)


def _describe_tool(tool: str | None, tool_input: dict, *, prefix: str) -> str:
    if not tool:
        return prefix
    if tool in ("Bash", "shell", "local_shell"):
        cmd = tool_input.get("command")
        if isinstance(cmd, list):
            cmd = " ".join(str(c) for c in cmd)
        lines = str(cmd or "").strip().splitlines()
        cmd = re.sub(r"\s+", " ", lines[0] if lines else "")[:60]
        return f"{prefix} `{cmd}`" if cmd else f"{prefix} shell"
    if tool == "apply_patch":
        return f"{prefix} edit"
    return f"{prefix} {tool}"


def map_event(event: str, payload: dict) -> tuple[str, str | None, bool] | None:
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
    if event == "PermissionRequest":
        return "needs-permission", _describe_tool(tool, tool_input, prefix="Wants to run"), True
    if event == "Stop":
        return "idle", "Turn ended", False
    return None


def intercept_permission(payload: dict, record: dict) -> str | None:
    if not (PERM_ROOT / "enabled").exists():
        return None
    if not app_running():
        return None

    requests_dir = PERM_ROOT / "requests"
    responses_dir = PERM_ROOT / "responses"
    requests_dir.mkdir(parents=True, exist_ok=True)
    responses_dir.mkdir(parents=True, exist_ok=True)

    tool = payload.get("tool_name") or "Tool"
    tool_input = payload.get("tool_input") or {}
    request_id = uuid.uuid4().hex
    now = time.time()

    request = {
        "v": 1,
        "tool": record["tool"],
        "sessionId": record["sessionId"],
        "requestId": request_id,
        "toolName": tool,
        "summary": record.get("activity"),
        "toolInputPreview": json.dumps(tool_input)[:500],
        "cwd": record.get("cwd"),
        "project": record.get("project"),
        "ts": now,
        "expiresAt": now + PERM_WAIT_SECONDS,
    }
    req_file = requests_dir / f"{record['sessionId']}.json"
    req_tmp = req_file.with_suffix(".json.tmp")
    req_tmp.write_text(json.dumps(request))
    req_tmp.replace(req_file)
    resp_file = responses_dir / f"{request_id}.json"

    try:
        deadline = now + PERM_WAIT_SECONDS
        while time.time() < deadline:
            if resp_file.exists():
                try:
                    decision = json.loads(resp_file.read_text()).get("decision")
                except (OSError, json.JSONDecodeError):
                    return None
                return decision if decision in ("allow", "deny", "ask") else None
            time.sleep(0.2)
        return None
    finally:
        try:
            current = json.loads(req_file.read_text())
            if current.get("requestId") == request_id:
                req_file.unlink()
        except (OSError, json.JSONDecodeError):
            pass
        resp_file.unlink(missing_ok=True)


def main() -> int:
    try:
        raw = sys.stdin.read()
        payload = json.loads(raw) if raw.strip() else {}
    except json.JSONDecodeError:
        return 0

    event = payload.get("hook_event_name") or "Unknown"
    session_id = payload.get("session_id") or payload.get("turn_id") or "unknown"
    cwd = payload.get("cwd") or os.getcwd()

    mapped = map_event(event, payload)
    if mapped is None:
        return 0
    state, activity, needs_attention = mapped

    record = {
        "tool": "codex",
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
    write_session(record, target)

    if event == "PermissionRequest":
        decision = intercept_permission(payload, record)
        if decision in ("allow", "deny"):
            tool = payload.get("tool_name")
            tool_input = payload.get("tool_input") or {}
            activity = (
                _describe_tool(tool, tool_input, prefix="Running")
                if decision == "allow"
                else f"Denied {tool or 'tool'}"
            )
            write_session({
                **record,
                "state": "working",
                "activity": activity,
                "needsAttention": False,
                "ts": time.time(),
            }, target)
            behavior = {"behavior": "allow"} if decision == "allow" else {
                "behavior": "deny",
                "message": "Denied in AgentDock",
            }
            print(json.dumps({
                "hookSpecificOutput": {
                    "hookEventName": "PermissionRequest",
                    "decision": behavior,
                }
            }))

    return 0


if __name__ == "__main__":
    sys.exit(main())
