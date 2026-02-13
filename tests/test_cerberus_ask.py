"""E2E-style tests for Cerberus /api/ask (Ollama call). Uses mock to avoid real Ollama."""
from __future__ import annotations

import json
import socket
import sys
import threading
import urllib.request
from unittest.mock import patch, MagicMock

import pytest

from cerberus.config import load_config
from cerberus.cerberus import CerberusHandler
from http.server import HTTPServer

ON_WIN = sys.platform == "win32"


def _find_free_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


@pytest.mark.skipif(ON_WIN, reason="localhost HTTP server can hang on Windows")
def test_api_ask_returns_ollama_response_mock():
    """POST /api/ask with mocked Ollama: verify 200 and response body."""
    port = _find_free_port()
    config = load_config()
    config["ollama"] = config.get("ollama", {}) | {"enabled": True, "base_url": "http://127.0.0.1:11434", "model": "phi3:mini"}
    server = HTTPServer(("127.0.0.1", port), CerberusHandler)
    server.config = config
    server.onnx_loaded = False
    server.deep_access = True

    mock_body = json.dumps({"response": "Mock LLM reply for tests."}).encode()

    def fake_urlopen(req, timeout=None):
        m = MagicMock()
        m.read.return_value = mock_body
        m.__enter__ = lambda self: self
        m.__exit__ = lambda *a: None
        return m

    def run():
        with patch("cerberus.cerberus.urllib.request.urlopen", side_effect=fake_urlopen):
            server.handle_request()

    t = threading.Thread(target=run, daemon=True)
    t.start()
    try:
        req = urllib.request.Request(
            f"http://127.0.0.1:{port}/api/ask",
            data=json.dumps({"prompt": "Hello", "include_context": False}).encode(),
            method="POST",
            headers={"Content-Type": "application/json"},
        )
        with urllib.request.urlopen(req, timeout=10) as r:
            assert r.status == 200
            data = json.loads(r.read().decode())
            assert data.get("response") == "Mock LLM reply for tests."
    finally:
        server.shutdown()
        t.join(timeout=2)


@pytest.mark.skipif(ON_WIN, reason="localhost HTTP server can hang on Windows")
def test_api_ask_ollama_disabled_returns_503():
    """When ollama.enabled is false, POST /api/ask returns 503 with code."""
    port = _find_free_port()
    config = load_config()
    config["ollama"] = config.get("ollama", {}) | {"enabled": False}
    server = HTTPServer(("127.0.0.1", port), CerberusHandler)
    server.config = config
    server.onnx_loaded = False
    server.deep_access = True
    t = threading.Thread(target=server.handle_request, daemon=True)
    t.start()
    try:
        req = urllib.request.Request(
            f"http://127.0.0.1:{port}/api/ask",
            data=json.dumps({"prompt": "Hi"}).encode(),
            method="POST",
            headers={"Content-Type": "application/json"},
        )
        with pytest.raises(urllib.error.HTTPError) as exc_info:
            urllib.request.urlopen(req, timeout=5)
        assert exc_info.value.code == 503
        body = exc_info.value.read().decode()
        data = json.loads(body)
        assert data.get("code") == "ollama_disabled"
    finally:
        server.shutdown()
        t.join(timeout=1)
