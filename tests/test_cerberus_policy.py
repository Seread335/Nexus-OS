"""Tests for Cerberus AI policy loading."""
from __future__ import annotations

import tempfile
from pathlib import Path

import pytest

from cerberus.ai_policy import load_ai_policy, _default_policy


def test_load_ai_policy_returns_dict():
    policy = load_ai_policy()
    assert isinstance(policy, dict)


def test_default_policy_structure():
    p = _default_policy()
    assert "read_paths" in p
    assert "allowed_commands" in p
    assert "audit_log_path" in p
    assert "deep_system_access" in p
    assert "nmap" in p["allowed_commands"] or "nexus-recon" in p["allowed_commands"]


def test_load_ai_policy_from_nonexistent_returns_default():
    policy = load_ai_policy("/nonexistent/ai_policy.yaml")
    assert policy == _default_policy()


def test_load_ai_policy_from_valid_yaml():
    with tempfile.NamedTemporaryFile(mode="w", suffix=".yaml", delete=False) as f:
        f.write("deep_system_access: false\nmax_context_bytes: 1024\n")
        path = f.name
    try:
        policy = load_ai_policy(path)
        assert policy["deep_system_access"] is False
        assert policy["max_context_bytes"] == 1024
    finally:
        Path(path).unlink(missing_ok=True)
