#!/usr/bin/env python3
"""
Nexus OS — Model Manager
Download, list, switch, and cleanup local AI models (Ollama + GGUF/ONNX).
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

# Default paths (relative to repo root or $NEXUS_MODELS)
REPO_ROOT = Path(__file__).resolve().parent.parent
MODELS_DIR = Path(os.environ.get("NEXUS_MODELS", str(REPO_ROOT / "models")))
ACTIVE_DIR = MODELS_DIR / "active"
ARCHIVES_DIR = MODELS_DIR / "archives"


def _ensure_dirs() -> None:
    ACTIVE_DIR.mkdir(parents=True, exist_ok=True)
    ARCHIVES_DIR.mkdir(parents=True, exist_ok=True)


def cmd_list_ollama() -> int:
    """List models available via Ollama (ollama list)."""
    try:
        out = subprocess.run(
            ["ollama", "list"],
            capture_output=True,
            text=True,
            timeout=30,
        )
        if out.returncode != 0:
            print("Ollama not running or not installed. Start with: ollama serve", file=sys.stderr)
            return 1
        print(out.stdout or "(no models pulled)")
        return 0
    except FileNotFoundError:
        print("Ollama not found. Install from https://ollama.ai or AUR.", file=sys.stderr)
        return 1


def cmd_pull_ollama(model: str) -> int:
    """Pull a model via Ollama (ollama pull <model>)."""
    try:
        return subprocess.run(["ollama", "pull", model], timeout=3600).returncode
    except FileNotFoundError:
        print("Ollama not found.", file=sys.stderr)
        return 1


def cmd_list_local() -> int:
    """List models in models/active and models/archives."""
    _ensure_dirs()
    print("Active:", ACTIVE_DIR)
    for f in sorted(ACTIVE_DIR.iterdir()):
        if f.name.startswith("."):
            continue
        print(f"  {f.name}")
    print("Archives:", ARCHIVES_DIR)
    for f in sorted(ARCHIVES_DIR.iterdir()):
        if f.name.startswith("."):
            continue
        print(f"  {f.name}")
    return 0


def cmd_switch(name: str) -> int:
    """Set active model (for GGUF/ONNX: symlink from archives to active)."""
    _ensure_dirs()
    src = ARCHIVES_DIR / name
    if not src.exists():
        print(f"Model not found in archives: {name}", file=sys.stderr)
        return 1
    # Clear active and link
    for f in ACTIVE_DIR.iterdir():
        if f.name != ".gitkeep":
            f.unlink()
    (ACTIVE_DIR / name).symlink_to(os.path.relpath(src, ACTIVE_DIR))
    print(f"Active model set to: {name}")
    return 0


def cmd_cleanup(keep: int) -> int:
    """Keep only the N most recent in archives, remove older."""
    _ensure_dirs()
    entries = [
        (f, f.stat().st_mtime)
        for f in ARCHIVES_DIR.iterdir()
        if not f.name.startswith(".")
    ]
    entries.sort(key=lambda x: -x[1])
    to_remove = entries[keep:]
    for f, _ in to_remove:
        if f.is_dir():
            shutil.rmtree(f)
        else:
            f.unlink()
        print(f"Removed: {f.name}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Nexus OS Model Manager")
    sub = parser.add_subparsers(dest="command", required=True)

    # ollama list
    sub.add_parser("ollama-list", help="List Ollama models")

    # ollama pull <model>
    p_pull = sub.add_parser("ollama-pull", help="Pull an Ollama model")
    p_pull.add_argument("model", help="Model name (e.g. llama3.2, phi3:mini)")

    # local list / switch / cleanup
    sub.add_parser("local-list", help="List models in models/active and archives")

    p_switch = sub.add_parser("switch", help="Set active model from archives (by name)")
    p_switch.add_argument("name", help="Model dir name in models/archives")

    p_clean = sub.add_parser("cleanup", help="Remove older archived models, keep N")
    p_clean.add_argument("-n", "--keep", type=int, default=3, help="Number to keep (default 3)")

    args = parser.parse_args()

    if args.command == "ollama-list":
        return cmd_list_ollama()
    if args.command == "ollama-pull":
        return cmd_pull_ollama(args.model)
    if args.command == "local-list":
        return cmd_list_local()
    if args.command == "switch":
        return cmd_switch(args.name)
    if args.command == "cleanup":
        return cmd_cleanup(args.keep)
    return 0


if __name__ == "__main__":
    sys.exit(main())
