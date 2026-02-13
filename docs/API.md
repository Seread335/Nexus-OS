# Cerberus API (Nexus OS)

Cerberus listens on **127.0.0.1 only** (no remote access). All `/api/*` requests are audited to `/var/log/cerberus/ai_audit.log`.

Base URL: `http://127.0.0.1:9380` (configurable via `config.yaml` → `agent.health_port`).

---

## Endpoints

### GET /health (and /healthz, /ready)

Health check for monitoring/readiness.

**Response:** `200 OK`

```json
{
  "status": "ok",
  "service": "cerberus",
  "onnx_loaded": false,
  "deep_access": true
}
```

- `onnx_loaded`: whether an ONNX model is loaded for anomaly inference.
- `deep_access`: from `ai_policy.yaml` → `deep_system_access`.

---

### GET /api/context

Returns a text snapshot of system context (processes, network, logs, allowed files) according to `ai_policy.yaml`. Requires `deep_system_access: true`.

**Response:** `200 OK`

```json
{
  "context": "<text snapshot>",
  "length": 12345
}
```

**Errors:**
- `403`: `deep_system_access` disabled in policy.
- `500`: context build failed (e.g. command execution error).

---

### POST /api/ask

Sends a prompt to the configured LLM (Ollama). Optionally prepends system context and a system prompt from config.

**Request body:**

```json
{
  "prompt": "Summarize open ports from the context.",
  "include_context": true
}
```

- `prompt` (string): user question or instruction.
- `include_context` (boolean, optional): if `true`, prepends a system-context snapshot (capped by policy limits) and the configured `ollama.system_prompt` when present.

**Response:** `200 OK`

```json
{
  "response": "Model output text..."
}
```

**Error responses** (JSON body with `error` and optional `code`):
- `400`: invalid request (e.g. bad JSON) — `code: "invalid_request"`.
- `403`: request from non-localhost.
- `503`: Ollama disabled (`code: "ollama_disabled"`) or unreachable (`code: "ollama_unreachable"`).
- `504`: timeout talking to Ollama — `code: "timeout"`.
- `500`: internal error — `code: "internal_error"`.

**Config:** `ollama.timeout` (seconds, default 120); retries: 2.

---

## Config and policy

- **Config:** `/etc/cerberus/config.yaml` — `agent.health_port`, `ollama.base_url`, `ollama.model`, `ollama.system_prompt`, etc.
- **Policy:** `/etc/cerberus/ai_policy.yaml` — `read_paths`, `read_exclude`, `allowed_commands`, `audit_log_path`, `deep_system_access`.

See `docs/ai_integration.md` and `src/cerberus/README.md` for details. OpenAPI snippet: **docs/openapi-cerberus.yaml**.
