#!/usr/bin/env python3
"""
Cerberus — AI Security Agent for Nexus OS.
Chạy với quyền cao (root), chỉ lắng nghe localhost.
Cung cấp: health, context toàn hệ thống (theo policy), và API hỏi LLM (Ollama).
Mọi truy cập /api/context và /api/ask đều được ghi audit.
"""

from __future__ import annotations

import json
import logging
import os
import sys
import threading
import urllib.error
import urllib.request
import socket
from http.server import HTTPServer, BaseHTTPRequestHandler
from pathlib import Path

from cerberus.config import load_config
from cerberus.ai_policy import load_ai_policy
from cerberus.context_builder import gather_system_context

# Optional ONNX for anomaly inference
try:
    import onnxruntime as ort
    HAS_ONNX = True
except ImportError:
    ort = None
    HAS_ONNX = False

LOG = logging.getLogger("cerberus")


def setup_logging(level: str = "INFO") -> None:
    logging.basicConfig(
        level=getattr(logging, level.upper(), logging.INFO),
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    )


def _audit(policy: dict, path: str, client: str, extra: str = "") -> None:
    audit_path = policy.get("audit_log_path") or "/var/log/cerberus/ai_audit.log"
    try:
        parent = Path(audit_path).parent
        parent.mkdir(parents=True, exist_ok=True)
        try:
            os.chmod(parent, 0o700)
        except Exception:
            pass
        # Atomic append with file mode enforcement where possible
        flags = os.O_WRONLY | os.O_CREAT | os.O_APPEND
        mode = 0o600
        fd = os.open(audit_path, flags, mode)
        try:
            with os.fdopen(fd, "a", encoding="utf-8") as f:
                f.write(f"{path} client={client} {extra}\n")
        except Exception:
            try:
                os.close(fd)
            except Exception:
                pass
        try:
            os.chmod(audit_path, mode)
        except Exception:
            pass
    except OSError as e:
        LOG.warning("Audit write failed: %s", e)


def _ollama_generate(
    base_url: str,
    model: str,
    prompt: str,
    timeout: int = 120,
    retries: int = 2,
) -> str:
    url = f"{base_url.rstrip('/')}/api/generate"
    data = json.dumps({"model": model, "prompt": prompt, "stream": False}).encode()
    req = urllib.request.Request(url, data=data, method="POST", headers={"Content-Type": "application/json"})
    last_err = None
    for attempt in range(max(1, retries + 1)):
        try:
            with urllib.request.urlopen(req, timeout=timeout) as r:
                out = json.loads(r.read().decode())
                return (out.get("response") or "").strip()
        except (urllib.error.URLError, urllib.error.HTTPError, OSError) as e:
            last_err = e
            if attempt < retries:
                import time
                time.sleep(1)
            continue
    raise last_err or RuntimeError("Ollama request failed")


class CerberusHandler(BaseHTTPRequestHandler):
    """Localhost-only API: /health, /api/context, /api/ask."""

    def do_GET(self) -> None:
        client = self.client_address[0] if self.client_address else "?"
        if client != "127.0.0.1" and client != "::1":
            self.send_response(403)
            self.end_headers()
            self.wfile.write(b"Only localhost allowed")
            return
        if self.path in ("/health", "/healthz", "/ready"):
            self._send_json(200, {
                "status": "ok",
                "service": "cerberus",
                "onnx_loaded": getattr(self.server, "onnx_loaded", False),
                "deep_access": getattr(self.server, "deep_access", False),
            })
            return
        # Require auth for any non-health endpoint if configured
        cfg = getattr(self.server, "config", {}) or {}
        auth_cfg = cfg.get("auth", {})
        if auth_cfg.get("require_token") and self.path.startswith("/api"):
            token = auth_cfg.get("token") or os.environ.get(auth_cfg.get("token_env", "CERBERUS_AUTH_TOKEN"))
            header = self.headers.get("Authorization", "")
            if not header.startswith("Bearer "):
                self.send_response(401)
                self.end_headers()
                self.wfile.write(b"Missing Bearer token")
                return
            provided = header.split(" ", 1)[1].strip()
            if not token or provided != token:
                self.send_response(403)
                self.end_headers()
                self.wfile.write(b"Forbidden")
                return
        if self.path == "/api/context":
            policy = load_ai_policy()
            if not policy.get("deep_system_access", True):
                self._send_json(403, {"error": "deep_system_access disabled"})
                return
            _audit(policy, "GET /api/context", client)
            try:
                ctx = gather_system_context(policy)
                self._send_json(200, {"context": ctx, "length": len(ctx)})
            except Exception as e:
                LOG.exception("context build failed")
                self._send_json(500, {"error": str(e)})
            return
        self._send_json(404, {"error": "not found"})

    def do_POST(self) -> None:
        client = self.client_address[0] if self.client_address else "?"
        if client != "127.0.0.1" and client != "::1":
            self.send_response(403)
            self.end_headers()
            self.wfile.write(b"Only localhost allowed")
            return
        if self.path == "/api/ask":
            policy = load_ai_policy()
            _audit(policy, "POST /api/ask", client, extra="(see body length)")
            # Auth enforced above in do_GET path guard; re-check for POST
            cfg = getattr(self.server, "config", {}) or {}
            auth_cfg = cfg.get("auth", {})
            if auth_cfg.get("require_token"):
                token = auth_cfg.get("token") or os.environ.get(auth_cfg.get("token_env", "CERBERUS_AUTH_TOKEN"))
                header = self.headers.get("Authorization", "")
                if not header.startswith("Bearer "):
                    self._send_json(401, {"error": "missing token"})
                    return
                provided = header.split(" ", 1)[1].strip()
                if not token or provided != token:
                    self._send_json(403, {"error": "forbidden"})
                    return
            try:
                length = int(self.headers.get("Content-Length", 0))
                body = self.rfile.read(length) if length else b"{}"
                data = json.loads(body.decode())
                prompt = data.get("prompt", "")
                include_context = data.get("include_context", False)
                config = getattr(self.server, "config", {})
                ollama_cfg = config.get("ollama", {})
                if not ollama_cfg.get("enabled", True):
                    self._send_json(503, {"error": "Ollama disabled in config", "code": "ollama_disabled"})
                    return
                base_url = ollama_cfg.get("base_url", "http://127.0.0.1:11434")
                model = ollama_cfg.get("model", "phi3:mini")
                timeout = int(ollama_cfg.get("timeout", 120))
                system_prompt = (ollama_cfg.get("system_prompt") or "").strip()
                if include_context:
                    ctx = gather_system_context(policy)
                    prompt = f"System context (read-only snapshot):\n{ctx[:50000]}\n\nUser question: {prompt}"
                if system_prompt:
                    prompt = f"{system_prompt}\n\n---\n\n{prompt}"
                response = _ollama_generate(base_url, model, prompt, timeout=timeout)
                self._send_json(200, {"response": response})
            except urllib.error.URLError as e:
                self._send_json(503, {"error": f"Ollama unreachable: {e}", "code": "ollama_unreachable"})
            except urllib.error.HTTPError as e:
                self._send_json(503, {"error": f"Ollama error: {e}", "code": "ollama_http_error"})
            except (TimeoutError, OSError) as e:
                self._send_json(504, {"error": str(e), "code": "timeout"})
            except ValueError as e:
                self._send_json(400, {"error": str(e), "code": "invalid_request"})
            except Exception as e:
                LOG.exception("ask failed")
                self._send_json(500, {"error": str(e), "code": "internal_error"})
            return
        self._send_json(404, {"error": "not found"})

    def _send_json(self, code: int, payload: dict) -> None:
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(payload).encode())

    def log_message(self, format: str, *args: object) -> None:
        LOG.debug("%s", args[0] if args else format)


def run_api_server(host: str, port: int, config: dict, onnx_loaded: bool) -> None:
    """Chỉ bind 127.0.0.1 để chỉ user local mới gọi được."""
    agent_cfg = (config or {}).get("agent", {}) or {}
    socket_path = agent_cfg.get("socket_path") or ""
    if socket_path:
        # Bind to a Unix domain socket instead of TCP. This is safer for
        # local-only APIs because it relies on filesystem permissions.
        try:
            # remove stale socket if present
            try:
                os.unlink(socket_path)
            except FileNotFoundError:
                pass
            class _UnixHTTPServer(HTTPServer):
                address_family = socket.AF_UNIX

            server = _UnixHTTPServer(socket_path, CerberusHandler)
            server.config = config
            server.onnx_loaded = onnx_loaded
            server.deep_access = load_ai_policy().get("deep_system_access", True)
            # try to restrict socket perms
            try:
                os.chmod(socket_path, 0o660)
            except Exception:
                pass
            LOG.info("Cerberus API listening on unix socket %s", socket_path)
            server.serve_forever()
        finally:
            try:
                os.unlink(socket_path)
            except Exception:
                pass
    else:
        server = HTTPServer((host, port), CerberusHandler)
        server.config = config
        server.onnx_loaded = onnx_loaded
        server.deep_access = load_ai_policy().get("deep_system_access", True)
        LOG.info("Cerberus API listening on %s:%s (localhost only)", host, port)
        server.serve_forever()


def load_onnx_model(path: str | None) -> object | None:
    if not path or not path.strip() or not HAS_ONNX:
        return None
    p = Path(path)
    if not p.exists():
        LOG.warning("ONNX model not found: %s", path)
        return None
    try:
        return ort.InferenceSession(str(p), providers=["CPUExecutionProvider"])
    except Exception as e:
        LOG.warning("Failed to load ONNX model %s: %s", path, e)
        return None


def main() -> int:
    config = load_config()
    agent = config.get("agent", {})
    if not agent.get("enabled", True):
        LOG.info("Cerberus disabled by config")
        return 0
    # Enforce auth token presence when configured to require one.
    auth_cfg = config.get("auth", {}) or {}
    if auth_cfg.get("require_token"):
        token = auth_cfg.get("token") or os.environ.get(auth_cfg.get("token_env", "CERBERUS_AUTH_TOKEN"))
        if not token:
            # If on Unix-like system, auto-generate an ephemeral token and
            # write it to `/run/cerberus/token` with restrictive perms so
            # operators can consume it (e.g. systemd unit EnvironmentFile).
            if os.name != "nt":
                try:
                    import secrets

                    token = secrets.token_hex(32)
                    run_dir = Path("/run/cerberus")
                    run_dir.mkdir(parents=True, exist_ok=True)
                    try:
                        os.chmod(str(run_dir), 0o700)
                    except Exception:
                        pass
                    token_path = run_dir / "token"
                    flags = os.O_WRONLY | os.O_CREAT | os.O_TRUNC
                    # write with mode 0o600
                    fd = os.open(str(token_path), flags, 0o600)
                    try:
                        with os.fdopen(fd, "w", encoding="utf-8") as f:
                            f.write(token)
                    except Exception:
                        try:
                            os.close(fd)
                        except Exception:
                            pass
                    try:
                        os.chmod(str(token_path), 0o600)
                    except Exception:
                        pass
                    LOG.info("Generated ephemeral auth token and saved to %s", token_path)
                except Exception as e:
                    LOG.error("Failed to auto-generate auth token: %s", e)
                    return 2
            else:
                LOG.error(
                    "Cerberus configured to require an auth token but none provided; on Windows provide %s env or set token in config",
                    auth_cfg.get("token_env", "CERBERUS_AUTH_TOKEN"),
                )
                return 2
    setup_logging(agent.get("log_level", "INFO"))

    ml = config.get("ml", {})
    onnx_path = ml.get("onnx_model") or ""
    session = load_onnx_model(onnx_path)
    onnx_loaded = session is not None

    port = int(agent.get("health_port", 9380))
    # Chỉ lắng nghe localhost — AI có quyền cao nhưng chỉ user local mới truy cập
    host = "127.0.0.1"
    # If running on Unix-like system and no explicit socket_path configured,
    # prefer a Unix domain socket for stronger local-only enforcement.
    try:
        is_windows = os.name == "nt"
    except Exception:
        is_windows = False
    socket_path = agent.get("socket_path") or ""
    if not is_windows and not socket_path:
        socket_path = "/run/cerberus/cerberus.sock"
        # update agent config so run_api_server will pick it up
        agent["socket_path"] = socket_path
    server_thread = threading.Thread(
        target=run_api_server,
        args=(host, port, config, onnx_loaded),
        daemon=True,
    )
    server_thread.start()

    LOG.info("Cerberus agent started (ONNX=%s, API %s:%s, deep_system_access=policy)", onnx_loaded, host, port)
    try:
        while True:
            import time
            time.sleep(60)
    except KeyboardInterrupt:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
