"""Load AI policy (read_paths, allowed_commands, limits)."""
from __future__ import annotations

import os
from pathlib import Path
from typing import Any

try:
    import yaml
except ImportError:
    yaml = None

DEFAULT_POLICY_PATHS = [
    "/etc/cerberus/ai_policy.yaml",
    Path(__file__).resolve().parent.parent.parent
    / "externals/archiso/configs/nexus/airootfs/etc/cerberus/ai_policy.yaml",
]


def load_ai_policy(path: str | Path | None = None) -> dict[str, Any]:
    if yaml is None:
        return _default_policy()
    for p in ([path] if path else []) or DEFAULT_POLICY_PATHS:
        p = Path(p)
        if p.exists():
            with open(p, encoding="utf-8") as f:
                return yaml.safe_load(f) or _default_policy()
    return _default_policy()


def _default_policy() -> dict[str, Any]:
    return {
        # Require explicit opt-in for deep system access; safer defaults
        "deep_system_access": False,
        "read_paths": ["/etc/cerberus", "/var/log", "/proc/net"],
        # Exclude common secret patterns and runtime secret stores
        "read_exclude": ["*.key", "*.pem", "*.env", "*secret*", "/etc/shadow", "/run/secrets"],
        "max_context_bytes": 524288,
        "max_file_bytes": 65536,
        "max_file_lines": 500,
        "allowed_commands": ["nmap", "ss", "ip", "journalctl", "systemctl", "ps", "nexus-recon"],
        "audit_log_path": "/var/log/cerberus/ai_audit.log",
    }
