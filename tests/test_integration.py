"""Integration tests: Cerberus API flow (health → context → ask) in one session."""
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
def test_cerberus_full_flow_health_context_ask():
    """Integration: GET /health, GET /api/context, POST /api/ask (mock Ollama) in one server session."""
    port = _find_free_port()
    config = load_config()
    config["ollama"] = config.get("ollama", {}) | {"enabled": True, "base_url": "http://127.0.0.1:11434", "model": "phi3:mini"}
    server = HTTPServer(("127.0.0.1", port), CerberusHandler)
    server.config = config
    server.onnx_loaded = False
    server.deep_access = True
    base = f"http://127.0.0.1:{port}"
    results = []

    def run_server():
        for _ in range(3):
            server.handle_request()

    t = threading.Thread(target=run_server, daemon=True)
    t.start()
    try:
        # 1. Health
        r = urllib.request.urlopen(urllib.request.Request(f"{base}/health", method="GET"), timeout=5)
        data = json.loads(r.read().decode())
        assert data.get("status") == "ok"
        results.append("health_ok")

        # 2. Context (may 200 or 500 if paths missing)
        try:
            r = urllib.request.urlopen(urllib.request.Request(f"{base}/api/context", method="GET"), timeout=15)
            data = json.loads(r.read().decode())
            assert "context" in data or "length" in data
            results.append("context_ok")
        except urllib.error.HTTPError as e:
            if e.code in (403, 500):
                results.append("context_skip")
            else:
                raise

        # 3. Ask (mock Ollama)
        mock_body = json.dumps({"response": "Integration test reply."}).encode()
        def fake_urlopen(req, timeout=None):
            m = MagicMock()
            m.read.return_value = mock_body
            m.__enter__ = lambda self: self
            m.__exit__ = lambda *a: None
            return m

        with patch("cerberus.cerberus.urllib.request.urlopen", side_effect=fake_urlopen):
            req = urllib.request.Request(
                f"{base}/api/ask",
                data=json.dumps({"prompt": "Hi", "include_context": False}).encode(),
                method="POST",
                headers={"Content-Type": "application/json"},
            )
            r = urllib.request.urlopen(req, timeout=10)
            data = json.loads(r.read().decode())
            assert data.get("response") == "Integration test reply."
        results.append("ask_ok")
    finally:
        server.shutdown()
        t.join(timeout=3)
    assert "health_ok" in results and "ask_ok" in results
    assert "context_ok" in results or "context_skip" in results
