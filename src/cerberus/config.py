"""Load Cerberus YAML config."""
from __future__ import annotations

import os
from pathlib import Path
from typing import Any

try:
    import yaml
except ImportError:
    yaml = None  # type: ignore[assignment]

DEFAULT_CONFIG_PATHS = [
    "/etc/cerberus/config.yaml",
    os.path.join(os.path.dirname(__file__), "..", "..", "externals", "archiso", "configs", "nexus", "airootfs", "etc", "cerberus", "config.yaml"),
    "config.yaml",
]


def load_config(path: str | Path | None = None) -> dict[str, Any]:
    if yaml is None:
        return _default_config()
    for p in ([path] if path else []) or DEFAULT_CONFIG_PATHS:
        p = Path(p)
        if p.exists():
            with open(p, encoding="utf-8") as f:
                return yaml.safe_load(f) or _default_config()
    return _default_config()


def _default_config() -> dict[str, Any]:
    return {
        # Agent enabled by default for backwards compatibility; startup will
        # enforce auth when "auth.require_token" is True (prevents running
        # without an operator-provided token).
        "agent": {
            "enabled": True,
            "log_level": "INFO",
            "rules_path": "/etc/cerberus/rules.d/",
            "health_port": 9380,
            # Optional: path to a Unix domain socket to bind the HTTP API.
            # Example: "/run/cerberus/cerberus.sock". If set, Cerberus will
            # bind the API to the socket and will not open a TCP port.
            "socket_path": "",
        },
        # API auth: require operator to provide a token via config or env var
        "auth": {"require_token": True, "token": None, "token_env": "CERBERUS_AUTH_TOKEN"},
        "falco": {"enabled": False},
        "ml": {"onnx_model": ""},
        "ollama": {"enabled": False, "base_url": "http://127.0.0.1:11434", "model": "phi3:mini"},
    }
