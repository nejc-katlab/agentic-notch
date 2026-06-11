#!/usr/bin/env python3
"""AgentDock hook for Claude Code.

Reads a hook event JSON from stdin and writes/updates
~/.agentdock/sessions/{session_id}.json with the current state.
Wire from ~/.claude/settings.json — see hooks/install.sh.
"""
import os
import re
import sys
import json
import time
import uuid
import tempfile
import subprocess
from pathlib import Path

ROOT = Path.home() / ".agentdock" / "sessions"
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


BLOCKING_TOOLS = {
    "ExitPlanMode": "Claude is waiting for plan approval",
    "AskUserQuestion": "Claude is asking you a question",
}


def map_event(event: str, payload: dict) -> tuple[str, str | None, bool] | None:
    """Return (state, activity, needs_attention), or None for informational events."""
    tool = payload.get("tool_name")
    tool_input = payload.get("tool_input") or {}
    if event == "SessionStart":
        return "working", "Session started", False
    if event == "UserPromptSubmit":
        return "working", "Thinking…", False
    if event == "PreToolUse":
        if tool in BLOCKING_TOOLS:
            return "needs-input", BLOCKING_TOOLS[tool], True
        return "working", _describe_tool(tool, tool_input, prefix="Running"), False
    if event == "PostToolUse":
        return "working", _describe_tool(tool, tool_input, prefix="Finished"), False
    if event == "Notification":
        msg = payload.get("message") or ""
        low = msg.lower()
        if any(k in low for k in ("logged in", "authenticated", "login success", "authentication success")):
            return None
        if "permission" in low or "approve" in low or "allow" in low:
            return "needs-permission", msg or "Needs permission", True
        return "needs-input", msg or "Waiting for your input", True
    if event == "Stop":
        return "idle", "Turn ended", False
    if event == "SessionEnd":
        return "done", "Session ended", False
    return "working", event, False


def debug_log(event: str, payload: dict) -> None:
    marker = Path.home() / ".agentdock" / "debug"
    if not marker.exists():
        return
    try:
        line = json.dumps({"t": time.time(), "event": event, "payload": payload}) + "\n"
        with open(marker.parent / "events.log", "a") as fh:
            fh.write(line)
    except Exception:
        pass


def app_running() -> bool:
    try:
        return subprocess.run(
            ["pgrep", "-x", "AgentDock"], capture_output=True, timeout=2
        ).returncode == 0
    except Exception:
        return False


def write_session(record: dict, target: Path) -> None:
    fd, tmp = tempfile.mkstemp(dir=str(target.parent), prefix=f"{target.stem}.", suffix=".tmp")
    try:
        with os.fdopen(fd, "w") as fh:
            json.dump(record, fh, indent=2)
        os.replace(tmp, target)
    except Exception:
        try:
            os.unlink(tmp)
        except OSError:
            pass


def intercept_permission(payload: dict, record: dict, target: Path) -> str | None:
    if payload.get("tool_name") in BLOCKING_TOOLS:
        return None
    if not (PERM_ROOT / "enabled").exists():
        return None
    if payload.get("permission_mode") not in ("default", "plan"):
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
    summary = _describe_tool(tool, tool_input, prefix="Wants to run")

    request = {
        "v": 1,
        "tool": record["tool"],
        "sessionId": record["sessionId"],
        "requestId": request_id,
        "toolName": tool,
        "summary": summary,
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

    write_session({
        **record,
        "state": "needs-permission",
        "activity": summary,
        "needsAttention": True,
        "ts": time.time(),
    }, target)

    try:
        enabled_marker = PERM_ROOT / "enabled"
        deadline = now + PERM_WAIT_SECONDS
        while time.time() < deadline:
            if resp_file.exists():
                try:
                    decision = json.loads(resp_file.read_text()).get("decision")
                except (OSError, json.JSONDecodeError):
                    return None
                return decision if decision in ("allow", "deny", "ask") else None
            if not enabled_marker.exists():
                return None
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

    debug_log(event, payload)

    mapped = map_event(event, payload)
    if mapped is None:
        return 0
    state, activity, needs_attention = mapped

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
    write_session(record, target)

    if event == "PreToolUse":
        decision = intercept_permission(payload, record, target)
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
            print(json.dumps({
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": decision,
                    "permissionDecisionReason": "Decided in AgentDock",
                }
            }))

    if event == "SessionEnd":
        try:
            time.sleep(0)
            target.unlink(missing_ok=True)
        except OSError:
            pass

    return 0


if __name__ == "__main__":
    sys.exit(main())
