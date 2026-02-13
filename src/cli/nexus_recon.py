#!/usr/bin/env python3
"""
nexus-recon — Automated recon with optional AI report (Nexus OS).
Wraps nmap/rustscan, parses output, and can summarize with local LLM (Ollama).
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    yaml = None

try:
    import urllib.request
    import urllib.error
    URLLIB_AVAILABLE = True
except ImportError:
    URLLIB_AVAILABLE = False

OLLAMA_DEFAULT_URL = "http://127.0.0.1:11434"
OLLAMA_DEFAULT_MODEL = "phi3:mini"
CERBERUS_API = "http://127.0.0.1:9380"


def _cerberus_available(base: str = CERBERUS_API) -> bool:
    if not URLLIB_AVAILABLE:
        return False
    try:
        req = urllib.request.Request(f"{base.rstrip('/')}/health", method="GET")
        with urllib.request.urlopen(req, timeout=3) as r:
            return r.status == 200
    except Exception:
        return False


def _cerberus_ask(prompt: str, include_context: bool = True, base: str = CERBERUS_API) -> str:
    if not URLLIB_AVAILABLE:
        return "(Cerberus: urllib not available)"
    url = f"{base.rstrip('/')}/api/ask"
    data = json.dumps({"prompt": prompt, "include_context": include_context}).encode()
    req = urllib.request.Request(url, data=data, method="POST", headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=180) as r:
            out = json.loads(r.read().decode())
            return out.get("response", "").strip()
    except Exception as e:
        return f"(Cerberus error: {e})"


def _ollama_available(base_url: str = OLLAMA_DEFAULT_URL) -> bool:
    if not URLLIB_AVAILABLE:
        return False
    try:
        req = urllib.request.Request(f"{base_url.rstrip('/')}/api/tags", method="GET")
        with urllib.request.urlopen(req, timeout=5) as r:
            return r.status == 200
    except Exception:
        return False


def _ollama_generate(prompt: str, model: str = OLLAMA_DEFAULT_MODEL, base_url: str = OLLAMA_DEFAULT_URL) -> str:
    if not URLLIB_AVAILABLE:
        return "(Ollama not available: no urllib)"
    url = f"{base_url.rstrip('/')}/api/generate"
    data = json.dumps({"model": model, "prompt": prompt, "stream": False}).encode()
    req = urllib.request.Request(url, data=data, method="POST", headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            out = json.loads(r.read().decode())
            return out.get("response", "").strip()
    except Exception as e:
        return f"(Ollama error: {e})"


def run_scan(target: str, aggressive: bool = False) -> str:
    """Run a quick port scan (nmap if available, else placeholder)."""
    try:
        cmd = ["nmap", "-sV", "-sC", "-T4", "-oG", "-", target]
        if aggressive:
            cmd.insert(1, "-A")
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
        return result.stdout + result.stderr
    except FileNotFoundError:
        return f"(nmap not found; would scan {target})"
    except subprocess.TimeoutExpired:
        return f"(nmap timeout for {target})"


__version__ = "0.1.0"


def cmd_scan(args: argparse.Namespace) -> int:
    target = args.target
    aggressive = getattr(args, "aggressive", False)
    out_path = getattr(args, "output", None)
    raw = run_scan(target, aggressive=aggressive)
    if "(nmap not found" in raw or "(nmap timeout" in raw:
        print(raw, file=sys.stderr)
        return 1
    print(raw)
    summary = ""
    if args.ai_report and raw.strip():
        use_cerberus = getattr(args, "use_cerberus", False)
        cerberus_url = getattr(args, "cerberus_url", CERBERUS_API) or CERBERUS_API
        prompt = (
            "You are a security analyst. Summarize the following recon scan output in short bullet points: "
            "main open ports, services, and one-line risk or recommendation.\n\n---\n" + raw[:6000]
        )
        if use_cerberus and _cerberus_available(cerberus_url):
            summary = _cerberus_ask(prompt, include_context=True, base=cerberus_url)
            print("\n--- AI Summary (Cerberus + full system context) ---\n", summary)
        elif _ollama_available(getattr(args, "ollama_url", OLLAMA_DEFAULT_URL) or OLLAMA_DEFAULT_URL):
            base = getattr(args, "ollama_url", OLLAMA_DEFAULT_URL) or OLLAMA_DEFAULT_URL
            model = getattr(args, "ollama_model", OLLAMA_DEFAULT_MODEL) or OLLAMA_DEFAULT_MODEL
            summary = _ollama_generate(prompt, model=model, base_url=base)
            print("\n--- AI Summary ---\n", summary)
        else:
            msg = "(Start Cerberus for deep context, or: ollama serve)"
            print("\n--- AI Summary ---\n" + msg, file=sys.stderr)
            summary = msg
    if out_path:
        _write_report(out_path, target=target, aggressive=aggressive, raw=raw, summary=summary or None)
    return 0


def _write_report(path: str, target: str, aggressive: bool, raw: str, summary: str | None) -> None:
    """Write Markdown report to path."""
    from datetime import datetime, timezone
    p = Path(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    with open(p, "w", encoding="utf-8") as f:
        f.write(f"# Nexus Recon Report — {target}\n\n")
        f.write(f"**Date:** {datetime.now(timezone.utc).isoformat().replace('+00:00', 'Z')}  \n")
        f.write(f"**Target:** {target}  \n")
        f.write(f"**Aggressive:** {aggressive}\n\n")
        f.write("## Scan Output\n\n```\n")
        f.write(raw.replace("```", "` ` `"))
        f.write("\n```\n\n")
        if summary:
            f.write("## AI Summary\n\n")
            f.write(summary)
            f.write("\n")
    print(f"Report written to {p}", file=sys.stderr)


def main() -> int:
    parser = argparse.ArgumentParser(prog="nexus-recon", description="Nexus OS recon with optional AI report")
    parser.add_argument("--version", "-V", action="version", version=f"%(prog)s {__version__}")
    sub = parser.add_subparsers(dest="command", required=True)

    scan = sub.add_parser("scan", help="Scan target and optionally get AI summary")
    scan.add_argument("target", help="Target host or CIDR")
    scan.add_argument("--aggressive", "-A", action="store_true", help="Aggressive scan (nmap -A)")
    scan.add_argument("--ai-report", action="store_true", help="Summarize results with local LLM (Ollama or Cerberus)")
    scan.add_argument("--use-cerberus", action="store_true", help="Use Cerberus API (full system context) for AI report")
    scan.add_argument("--cerberus-url", default=CERBERUS_API, help="Cerberus API base URL")
    scan.add_argument("--ollama-url", default=OLLAMA_DEFAULT_URL, help="Ollama API base URL (when not using Cerberus)")
    scan.add_argument("--ollama-model", default=OLLAMA_DEFAULT_MODEL, help="Ollama model name")
    scan.add_argument("--output", "-o", metavar="FILE", help="Write Markdown report to FILE (scan output + AI summary if --ai-report)")
    scan.set_defaults(func=cmd_scan)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
