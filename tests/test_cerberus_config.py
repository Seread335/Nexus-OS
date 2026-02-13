"""Tests for Cerberus config loading."""
from __future__ import annotations

import tempfile
from pathlib import Path

import pytest

from cerberus.config import load_config, _default_config


def test_load_config_returns_dict():
    cfg = load_config()
    assert isinstance(cfg, dict)
    assert "agent" in cfg
    assert "ollama" in cfg


def test_default_config_structure():
    cfg = _default_config()
    assert cfg["agent"]["enabled"] is True
    assert cfg["agent"]["health_port"] == 9380
    assert cfg["ollama"]["base_url"] == "http://127.0.0.1:11434"
    assert "ml" in cfg


def test_load_config_from_nonexistent_path_returns_default():
    cfg = load_config("/nonexistent/path/config.yaml")
    assert cfg == _default_config()


def test_load_config_from_valid_yaml():
    with tempfile.NamedTemporaryFile(mode="w", suffix=".yaml", delete=False) as f:
        f.write("agent:\n  health_port: 9999\nollama:\n  model: llama2\n")
        path = f.name
    try:
        cfg = load_config(path)
        assert cfg["agent"]["health_port"] == 9999
        assert cfg["ollama"]["model"] == "llama2"
    finally:
        Path(path).unlink(missing_ok=True)
