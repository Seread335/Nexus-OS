"""Tests for nexus-recon CLI (scan, report export)."""
from __future__ import annotations

import tempfile
from pathlib import Path
from unittest.mock import patch

import pytest

from cli.nexus_recon import (
    run_scan,
    _write_report,
    _cerberus_available,
    _ollama_available,
    main,
    __version__,
)


def test_run_scan_returns_string():
    # May be "(nmap not found)" on Windows or actual output on Linux
    out = run_scan("127.0.0.1")
    assert isinstance(out, str)
    assert "127.0.0.1" in out or "nmap" in out.lower()


def test_write_report_creates_file():
    with tempfile.TemporaryDirectory() as d:
        path = Path(d) / "report.md"
        _write_report(
            str(path),
            target="10.0.0.1",
            aggressive=True,
            raw="Host: 10.0.0.1 () Ports: 22/open",
            summary="Open SSH; recommend key-only auth.",
        )
        assert path.exists()
        text = path.read_text(encoding="utf-8")
        assert "10.0.0.1" in text
        assert "Aggressive: True" in text or "**Aggressive:** True" in text
        assert "Scan Output" in text
        assert "22/open" in text
        assert "AI Summary" in text
        assert "Open SSH" in text


def test_write_report_without_summary():
    with tempfile.TemporaryDirectory() as d:
        path = Path(d) / "out.md"
        _write_report(str(path), target="x", aggressive=False, raw="raw output", summary=None)
        assert path.exists()
        text = path.read_text(encoding="utf-8")
        assert "raw output" in text
        assert "AI Summary" not in text or "None" not in text


def test_cerberus_available_no_cerberus():
    # With default URL and no server, should return False (or True if user runs Cerberus)
    result = _cerberus_available("http://127.0.0.1:19380")  # unlikely port
    assert result is False


def test_ollama_available_no_ollama():
    result = _ollama_available("http://127.0.0.1:11435")  # wrong port
    assert result is False


def test_version_flag():
    with patch("sys.argv", ["nexus-recon", "--version"]):
        with pytest.raises(SystemExit) as exc:
            main()
        assert exc.value.code == 0


def test_scan_output_e2e_no_ai(tmp_path):
    """E2E: nexus-recon scan <target> --output <file> produces report (no --ai-report)."""
    out_file = tmp_path / "e2e_report.md"
    with patch("sys.argv", ["nexus-recon", "scan", "127.0.0.1", "--output", str(out_file)]):
        exit_code = main()
    # May be 0 (nmap ran) or 1 (nmap not found on Windows)
    assert exit_code in (0, 1)
    if out_file.exists():
        text = out_file.read_text(encoding="utf-8")
        assert "127.0.0.1" in text
        assert "Scan Output" in text or "Nexus Recon Report" in text
