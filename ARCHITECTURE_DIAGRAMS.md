# Component Interaction Diagram

## System Architecture (Mermaid)

```mermaid
graph TB
    User["👤 User"]
    
    subgraph "CLI Layer"
        NexusRecon["nexus-recon<br/>(Python CLI)"]
        NexusRecon_Scan["scan<br/>nmap/rustscan"]
        NexusRecon_Report["--ai-report<br/>AI summary"]
    end
    
    subgraph "Network Layer"
        Local["127.0.0.1:9380"]
        Ollama["127.0.0.1:11434<br/>(Ollama LLM)"]
    end
    
    subgraph "Security Layer"
        Cerberus["Cerberus Agent<br/>(root daemon)"]
        Policy["ai_policy.yaml<br/>whitelist"]
        AuditLog["audit.log<br/>(encrypted)"]
    end
    
    subgraph "System Layer"
        ContextBuilder["context_builder.py<br/>ps, ss, ip, journal"]
        SystemState["System State<br/>process, network<br/>logs, files"]
    end
    
    subgraph "ISO & Tooling"
        ISO["Arch ISO<br/>(169 packages)"]
        BlackArch["50 BlackArch Tools<br/>recon, scan, exploit"]
    end
    
    User -->|shell| NexusRecon
    NexusRecon --> NexusRecon_Scan
    NexusRecon --> NexusRecon_Report
    NexusRecon_Report -->|HTTP POST| Local
    
    Local --> Cerberus
    Cerberus -->|policy check| Policy
    Cerberus -->|gather| ContextBuilder
    ContextBuilder -->|query| SystemState
    Cerberus -->|audit| AuditLog
    
    Cerberus -->|send prompt+context| Ollama
    Ollama -->|response| Cerberus
    Cerberus -->|response| NexusRecon_Report
    NexusRecon_Report -->|print| User
    
    ISO -->|includes| BlackArch
    BlackArch -->|nmap, sqlmap, etc| NexusRecon_Scan
```

## Build Pipeline

```mermaid
graph LR
    A["PKGBUILD<br/>source files"] -->|Docker| B["Arch Container<br/>base-devel"]
    B -->|makepkg| C["Compiled Package<br/>.pkg.tar.zst"]
    C -->|archive| D["build_output/<br/>packages/"]
    D -->|mkarchiso| E["ArchISO"]
    E -->|customize_airootfs.sh| F["ISO with<br/>Cerberus<br/>service"]
    F -->|Write| G["nexus-os-*.iso"]
    
    style A fill:#e1f5ff
    style C fill:#c8e6c9
    style F fill:#fff3e0
    style G fill:#f3e5f5
```

## Cerberus API State Machine

```mermaid
stateDiagram-v2
    [*] --> Initialized
    
    Initialized --> HealthCheck: GET /health
    
    HealthCheck --> CheckLocal: Verify client == 127.0.0.1?
    CheckLocal -->|YES| HealthOK: Return {status: ok}
    CheckLocal -->|NO| Forbidden: Return 403
    
    Forbidden --> [*]
    HealthOK --> [*]
    
    Initialized --> GetContext: GET /api/context
    GetContext --> CheckLocal2: Verify client == 127.0.0.1?
    CheckLocal2 -->|NO| Forbidden
    CheckLocal2 -->|YES| LoadPolicy: Load ai_policy.yaml
    LoadPolicy --> GatherContext: context_builder.gather_system_context
    GatherContext --> LogAudit: Log to audit.log
    LogAudit --> ReturnContext: Return {context: "..."}
    ReturnContext --> [*]
    
    Initialized --> PostAsk: POST /api/ask
    PostAsk --> CheckLocal3: Verify client == 127.0.0.1?
    CheckLocal3 -->|NO| Forbidden
    CheckLocal3 -->|YES| LoadPolicy2: Load ai_policy.yaml
    LoadPolicy2 --> ParseBody: Parse JSON body
    ParseBody --> GetContext2: Get system context?
    GetContext2 --> CallOllama: Send to Ollama API
    CallOllama --> LogAudit2: Log to audit.log
    LogAudit2 --> ReturnResponse: Return {response: "..."}
    ReturnResponse --> [*]
```

## Data Flow: nexus-recon → Cerberus → Ollama

```mermaid
sequenceDiagram
    participant User
    participant nexus_recon as nexus-recon<br/>(CLI)
    participant Cerberus as Cerberus<br/>/api/ask
    participant Ollama as Ollama<br/>LLM
    
    User ->> nexus_recon: scan <target> --ai-report
    nexus_recon ->> nexus_recon: nmap scan
    nexus_recon ->> nexus_recon: parse output
    nexus_recon ->> Cerberus: POST {prompt: "summarize...", include_context: true}
    
    activate Cerberus
    Cerberus ->> Cerberus: Load policy
    Cerberus ->> Cerberus: Gather context (ps, ss, journal, etc)
    Cerberus ->> Cerberus: Apply whitelist (read_paths, exclude)
    Cerberus ->> Ollama: POST {model: "phi3:mini", prompt: "..."}
    
    activate Ollama
    Ollama ->> Ollama: Generate response
    Ollama -->> Cerberus: {response: "..."}
    deactivate Ollama
    
    Cerberus ->> Cerberus: Log audit
    Cerberus -->> nexus_recon: {response: "..."}
    deactivate Cerberus
    
    nexus_recon ->> nexus_recon: Format markdown
    nexus_recon -->> User: Print report
```

## Security Control Flow

```mermaid
graph TB
    Audit["Every /api/context<br/>or /api/ask call"]
    
    Audit --> Check1{"Is client<br/>127.0.0.1?"}
    Check1 -->|NO| Deny["❌ Deny (403)"]
    Check1 -->|YES| Check2{"Is endpoint<br/>whitelisted?"}
    
    Check2 -->|NO| Deny
    Check2 -->|YES| Check3{"Load<br/>ai_policy.yaml"}
    
    Check3 --> Check4{"deep_system<br/>_access=true?"}
    Check4 -->|NO| Deny
    Check4 -->|YES| Check5{"Gather<br/>context"}
    
    Check5 --> Filter["Apply filters:<br/>read_paths<br/>read_exclude<br/>max_context_bytes"]
    
    Filter --> Sanitize["Sanitize:<br/>mask IPs/PHI?<br/>remove secrets?"]
    
    Sanitize --> Send["✅ Send to LLM<br/>or return"]
    
    Send --> AuditLog["📝 Log to:<br/>ai_audit.log<br/>encrypted"]
    
    Deny --> DenyAudit["⚠️ Log denied<br/>attempt"]
    
    DenyAudit --> [*]
    AuditLog --> [*]
    
    style Deny fill:#ffcdd2
    style Send fill:#c8e6c9
    style AuditLog fill:#e1f5ff
```

## Package Build Dependency Graph

```mermaid
graph TD
    A["PKGBUILD<br/>source"]
    
    A --> B{Binary-first<br/>available?}
    
    B -->|YES<br/>faster| C["Download<br/>binary"]
    B -->|NO| D["Build from<br/>source"]
    
    C --> E["Extract"]
    D --> E
    
    E --> F["Copy to<br/>$pkgdir"]
    F --> G["makepkg<br/>creates<br/>.pkg.tar.zst"]
    
    G --> H["Checksum?"]
    H -->|TODO| I["❌ Add SHA256<br/>verification"]
    H -->|DONE| J["✅ Verify<br/>integrity"]
    
    J --> K["Sign?"]
    K -->|TODO| L["❌ Add GPG<br/>signature"]
    K -->|DONE| M["✅ Sign<br/>package"]
    
    M --> N["Archive to<br/>build_output/<br/>"]
    
    style A fill:#e3f2fd
    style I fill:#ffcdd2
    style J fill:#c8e6c9
    style L fill:#ffcdd2
    style M fill:#c8e6c9
    style N fill:#f3e5f5
```

## Configuration Management Flow

```mermaid
graph TB
    A["Cerberus<br/>initialization"]
    
    A --> B["load_config()"]
    B --> C{"Check paths:"}
    
    C -->|1| D["/etc/cerberus/config.yaml"]
    C -->|2| E["externals/archiso/.../config.yaml"]
    C -->|3| F["./config.yaml"]
    C -->|4| G["DEFAULT_CONFIG"]
    
    D --> |found| H["Load YAML"]
    E --> |found| H
    F --> |found| H
    G --> |fallback| H
    
    H --> I["Parse as dict"]
    I --> J{"Structure ok?"}
    
    J -->|YES| K["Return config"]
    J -->|NO| L["Return defaults<br/>with warnings"]
    
    K --> M["Cerberus API uses<br/>config for:<br/>- log_level<br/>- health_port<br/>- ollama_url<br/>- onnx_model_path"]
    
    L --> M
    
    A -.-> B2["load_ai_policy()"]
    B2 -.-> C2{"Check paths:"}
    
    C2 -.->|1| D2["/etc/cerberus/ai_policy.yaml"]
    C2 -.->|2| E2["externals/...ai_policy.yaml"]
    C2 -.->|4| G2["DEFAULT_POLICY"]
    
    D2 -.-> |found| H2["Load YAML"]
    E2 -.-> |found| H2
    G2 -.-> |fallback| H2
    
    H2 -.-> N["Policy applied to:<br/>- read_paths<br/>- read_exclude<br/>- max_context_bytes<br/>- allowed_commands<br/>- audit_log_path"]
    
    style D fill:#fff3e0
    style E fill:#fff3e0
    style F fill:#fff3e0
    style G fill:#ffecb3
    style K fill:#c8e6c9
    style L fill:#ffcdd2
    style M fill:#e1f5ff
    style N fill:#e1f5ff
```

## Milestone Completion Status

```mermaid
pie title Nexus OS Milestone Completion (Feb 12, 2026)
    "M0: Repo Setup ✅" : 100
    "M1: ISO Profile ✅" : 100
    "M2: Core Tools 🔧" : 40
    "M3: AI Strategy 🔧" : 30
    "M4: Pacman Repo ⏳" : 0
    "M5: Secure Boot ⏳" : 0
    "M6: Testing & QA ⏳" : 0
    "M7: Release ⏳" : 0
```

## Risk Priority Heat Map

```mermaid
graph TB
    subgraph "Critical Issues (C-level)"
        C1["C1: Cerberus /api/ask"]
        C2["C2: nexus-recon CLI"]
        C3["C3: Unit tests"]
        C4["C4: ISO testing"]
        C5["C5: Package signatures"]
    end
    
    subgraph "High Issues (H-level)"
        H1["H1: Metasploit PKGBUILD"]
        H2["H2: Model manager"]
        H3["H3: AI policy harden"]
        H4["H4: Context encryption"]
        H5["H5: API docs"]
    end
    
    subgraph "Nice-to-have (N-level)"
        N1["N1: Performance profiling"]
        N2["N2: Build optimization"]
        N3["N3: ARM64 support"]
        N4["N4: Atomic updates"]
    end
    
    C1 -->|BLOCKS| C2
    C2 -->|BLOCKS| C3
    C3 -->|BLOCKS| C4
    
    H1 -->|DEPENDS| H5
    H3 -->|DEPENDS| H4
    H2 -->|NICE-TO-HAVE| N2
    
    style C1 fill:#ff5252
    style C2 fill:#ff5252
    style C3 fill:#ff5252
    style C4 fill:#ff5252
    style C5 fill:#ff5252
    
    style H1 fill:#ffb300
    style H2 fill:#ffb300
    style H3 fill:#ffb300
    style H4 fill:#ffb300
    style H5 fill:#ffb300
    
    style N1 fill:#4caf50
    style N2 fill:#4caf50
    style N3 fill:#4caf50
    style N4 fill:#4caf50
```

---

## Testing Coverage Map

```mermaid
graph TB
    A["Unit Tests<br/>(0% Current)"]
    B["Integration Tests<br/>(0% Current)"]
    C["E2E Tests<br/>(0% Current)"]
    D["Security Tests<br/>(0% Current)"]
    
    A -->|target 50%| A1["✓ Config loading<br/>✓ Context builder<br/>✓ AI policy validation<br/>✓ Scan wrapper<br/>✓ Ollama integration"]
    
    B -->|target 70%| B1["✓ Cerberus /health<br/>✓ Cerberus /api/context<br/>✓ Cerberus /api/ask<br/>✓ nexus-recon scan+report<br/>✓ model_manager switching"]
    
    C -->|target 80%| C1["✓ ISO boot in QEMU<br/>✓ ISO boot on real HW<br/>✓ Cerberus service startup<br/>✓ Package installation<br/>✓ Full scan 🎯 report workflow"]
    
    D -->|target 60%| D1["✓ Path traversal attempts<br/>✓ Command injection prevention<br/>✓ Context sanitization<br/>✓ Audit log integrity<br/>✓ Privilege escalation attempts"]
    
    style A1 fill:#c8e6c9
    style B1 fill:#c8e6c9
    style C1 fill:#c8e6c9
    style D1 fill:#c8e6c9
```

