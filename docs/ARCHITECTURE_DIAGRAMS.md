# Nexus OS — Sơ Đồ Kiến Trúc (Mermaid)

6 diagram minh họa kiến trúc hệ thống, pipeline build, Cerberus API, luồng dữ liệu, bảo mật và phạm vi test.

---

## 1. System architecture (Client → Cerberus → Ollama)

```mermaid
flowchart LR
  subgraph Client
    CLI[nexus-recon CLI]
    User[User / Script]
  end

  subgraph Cerberus["Cerberus (127.0.0.1:9380)"]
    API[HTTP API]
    Policy[ai_policy.yaml]
    Ctx[context_builder]
    Audit[audit log]
  end

  subgraph LLM
    Ollama[Ollama / Local LLM]
  end

  User --> CLI
  CLI -->|POST /api/ask include_context=true| API
  API --> Policy
  API --> Ctx
  API --> Audit
  API -->|prompt + context| Ollama
  Ollama -->|response| API
  API -->|JSON response| CLI
```

---

## 2. Build pipeline (PKGBUILD → Docker → ISO)

```mermaid
flowchart TB
  subgraph Sources
    PKG[packages.base, .pentest, .blackarch, ...]
    AUR[packaging/aur/*/PKGBUILD]
    SRC[src/ cerberus + cli]
  end

  subgraph Build
    GEN[generate_packages_list.sh]
    DOCKER[build_aur_local.sh / Docker]
    ISO[build_iso.sh]
    MK[mkarchiso]
  end

  subgraph Outputs
    REPO[nexus-core repo .db]
    ART[*.pkg.tar.zst]
    IMG[nexus-os-*.iso]
  end

  PKG --> GEN
  GEN --> packages.x86_64
  packages.x86_64 --> ISO
  SRC --> ISO
  ISO --> MK --> IMG

  AUR --> DOCKER --> ART
  ART --> create_repo.sh --> REPO
```

---

## 3. Cerberus state / API endpoints

```mermaid
stateDiagram-v2
  [*] --> Starting
  Starting --> Running: config loaded, server bind 127.0.0.1:9380

  Running --> Health: GET /health, /healthz, /ready
  Running --> Context: GET /api/context (if deep_system_access)
  Running --> Ask: POST /api/ask

  Health --> Running: 200 JSON
  Context --> Audit: log request
  Context --> Running: 200 JSON context
  Ask --> Audit: log request
  Ask --> Ollama: prompt + optional context
  Ollama --> Ask: response
  Ask --> Running: 200 JSON response

  Running --> [*]: shutdown
```

---

## 4. Data flow: nexus-recon → Cerberus → Ollama

```mermaid
sequenceDiagram
  participant U as User
  participant NR as nexus-recon
  participant C as Cerberus
  participant O as Ollama

  U->>NR: scan TARGET --ai-report --use-cerberus
  NR->>NR: nmap TARGET
  NR->>C: GET /health
  C-->>NR: 200 OK
  NR->>C: POST /api/ask {"prompt": "...", "include_context": true}
  C->>C: gather_system_context(policy)
  C->>C: audit log
  C->>O: POST /api/generate (prompt + system_prompt + context)
  O-->>C: response
  C-->>NR: 200 {"response": "..."}
  NR-->>U: print scan + AI summary
```

---

## 5. Security control flow (policy + audit)

```mermaid
flowchart TB
  subgraph Request
    R[HTTP Request]
  end

  subgraph Checks
    Local[Client == 127.0.0.1 / ::1?]
    Policy[load ai_policy.yaml]
    Deep[deep_system_access?]
  end

  subgraph Actions
    Allow[Allow]
    Deny[403 Forbidden]
    BuildCtx[gather_system_context]
    CallOllama[Call Ollama]
    Audit[Append to audit_log_path]
  end

  R --> Local
  Local -->|No| Deny
  Local -->|Yes| Policy
  Policy --> Deep
  Deep -->|/api/context No| Deny
  Deep -->|Yes or /api/ask| Allow
  Allow --> Audit
  Allow --> BuildCtx
  Allow --> CallOllama
```

---

## 6. Testing coverage map (mục tiêu)

```mermaid
flowchart LR
  subgraph Unit
    T1[Cerberus config load]
    T2[Policy load]
    T3[Context builder mock]
    T4[nexus_recon scan parse]
  end

  subgraph Integration
    T5[GET /health]
    T6[POST /api/ask mock Ollama]
    T7[nexus-recon --ai-report mock]
  end

  subgraph E2E
    T8[Build ISO]
    T9[QEMU boot ISO]
    T10[Cerberus + recon on live]
  end

  T1 --> T5
  T2 --> T5
  T3 --> T6
  T4 --> T7
  T5 --> T8
  T6 --> T8
  T8 --> T9 --> T10
```

---

*Các diagram dùng Mermaid; có thể render trong GitHub, GitLab hoặc VS Code (Markdown Preview Mermaid).*
