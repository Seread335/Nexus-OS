"""Tests for Cerberus API (health endpoint)."""
from __future__ import annotations

import json
import socket
import sys
import threading
import urllib.request

import pytest

from cerberus.config import load_config
from cerberus.cerberus import CerberusHandler
from http.server import HTTPServer

# Health tests use localhost HTTP; can hang on some Windows setups
ON_WIN = sys.platform == "win32"


def _find_free_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


@pytest.mark.skipif(ON_WIN, reason="localhost HTTP server can hang on Windows")
def test_health_endpoint_returns_ok():
    port = _find_free_port()
    config = load_config()
    server = HTTPServer(("127.0.0.1", port), CerberusHandler)
    server.config = config
    server.onnx_loaded = False
    server.deep_access = True
    done = threading.Event()

    def run():
        server.handle_request()
        done.set()

    t = threading.Thread(target=run, daemon=True)
    t.start()
    try:
        req = urllib.request.Request(f"http://127.0.0.1:{port}/health", method="GET")
        with urllib.request.urlopen(req, timeout=5) as r:
            assert r.status == 200
            data = json.loads(r.read().decode())
            assert data.get("status") == "ok"
            assert data.get("service") == "cerberus"
            assert "onnx_loaded" in data
    finally:
        server.shutdown()
        done.wait(timeout=2)
        t.join(timeout=1)


@pytest.mark.skipif(ON_WIN, reason="localhost HTTP server can hang on Windows")
def test_healthz_alias():
    """Same handler serves /healthz and /ready; one request is enough to verify 200 + ok."""
    port = _find_free_port()
    config = load_config()
    server = HTTPServer(("127.0.0.1", port), CerberusHandler)
    server.config = config
    server.onnx_loaded = False
    server.deep_access = True
    t = threading.Thread(target=server.handle_request)
    t.start()
    try:
        req = urllib.request.Request(f"http://127.0.0.1:{port}/healthz", method="GET")
        with urllib.request.urlopen(req, timeout=2) as r:
            assert r.status == 200
            data = json.loads(r.read().decode())
            assert data.get("status") == "ok"
    finally:
        server.shutdown()
        t.join(timeout=1)
