"""
Build system context for AI: process list, network state, logs, and allowed files.
Designed to run with elevated privileges (root) so AI has full read-only visibility.
"""

from __future__ import annotations

import fnmatch
import os
import subprocess
from pathlib import Path
from typing import Any

from cerberus.ai_policy import load_ai_policy

LOG = __import__("logging").getLogger("cerberus.context_builder")


def _run(cmd: list[str], max_bytes: int = 256 * 1024, timeout: int = 30) -> str:
    try:
        out = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        return (out.stdout or "") + (out.stderr or "")[:max_bytes]
    except (FileNotFoundError, subprocess.TimeoutExpired) as e:
        return f"(error: {e})"


def _safe_read(path: Path, max_bytes: int, max_lines: int) -> str:
    try:
        if not path.is_file():
            return ""
        with open(path, errors="replace") as f:
            lines = f.readlines()
        if len(lines) > max_lines:
            lines = lines[-max_lines:]
        text = "".join(lines)
        if len(text) > max_bytes:
            text = text[-max_bytes:]
        return text
    except (OSError, PermissionError):
        return f"(unreadable: {path})"


def _should_exclude(file_path: str, exclude_patterns: list[str]) -> bool:
    name = os.path.basename(file_path)
    for pat in exclude_patterns:
        if fnmatch.fnmatch(name, pat) or fnmatch.fnmatch(file_path, pat):
            return True
        if pat in file_path:
            return True
    return False


def gather_system_context(policy: dict[str, Any] | None = None) -> str:
    """Gather a read-only snapshot of the system for AI context."""
    policy = policy or load_ai_policy()
    max_total = int(policy.get("max_context_bytes", 524288))
    max_file = int(policy.get("max_file_bytes", 65536))
    max_lines = int(policy.get("max_file_lines", 500))
    read_paths = policy.get("read_paths", [])
    read_exclude = policy.get("read_exclude", [])

    parts: list[str] = []
    used = 0

    # --- Process list (full) ---
    parts.append("=== PROCESSES (ps aux) ===\n")
    out = _run(["ps", "aux"], max_bytes=200 * 1024)
    parts.append(out[:min(len(out), max_total - used)])
    used += len(parts[-1])

    # --- Network ---
    parts.append("\n=== NETWORK (ss -tuln; ip -br a) ===\n")
    out = _run(["ss", "-tuln"], max_bytes=50 * 1024) + "\n" + _run(["ip", "-br", "a"], max_bytes=20 * 1024)
    parts.append(out[:min(len(out), max_total - used)])
    used += len(parts[-1])

    # --- Journal (recent) ---
    parts.append("\n=== JOURNAL (last 200 lines) ===\n")
    out = _run(["journalctl", "-n", "200", "--no-pager"], max_bytes=150 * 1024, timeout=15)
    parts.append(out[:min(len(out), max_total - used)])
    used += len(parts[-1])

    # --- Allowed paths (safe read) ---
    for base in read_paths:
        if used >= max_total:
            break
        base_path = Path(base)
        if not base_path.exists():
            continue
        parts.append(f"\n=== FILES under {base} ===\n")
        try:
            if base_path.is_file():
                if not _should_exclude(str(base_path), read_exclude):
                    parts.append(_safe_read(base_path, max_file, max_lines))
                    used += len(parts[-1])
            else:
                for f in base_path.rglob("*"):
                    if used >= max_total:
                        break
                    if not f.is_file():
                        continue
                    if _should_exclude(str(f), read_exclude):
                        continue
                    try:
                        snip = _safe_read(f, max_file, max_lines)
                        if snip and "(unreadable" not in snip:
                            parts.append(f"--- {f}\n{snip}\n")
                            used += len(parts[-1])
                    except Exception:
                        pass
        except (OSError, PermissionError):
            parts.append(f"(list error: {base})\n")

    return "".join(parts)[:max_total]
