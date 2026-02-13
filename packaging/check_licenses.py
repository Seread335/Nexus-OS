#!/usr/bin/env python3
"""Scan packaging/aur for PKGBUILDs and extract license fields.

Outputs CSV of package, license, path for manual review.
"""
from pathlib import Path
import re
import csv

ROOT = Path(__file__).resolve().parent
PKGDIR = ROOT / "aur"

def parse_license(pkgbuild: str) -> str:
    # naive parse: look for license=( ... ) or license= '...' or "..."
    m = re.search(r"^\s*license\s*=\s*(\(.+?\)|\S+)", pkgbuild, re.M)
    if not m:
        return "(unknown)"
    val = m.group(1).strip()
    return val

def main():
    rows = []
    for d in sorted(PKGDIR.iterdir()):
        if not d.is_dir():
            continue
        pb = d / "PKGBUILD"
        if not pb.exists():
            continue
        txt = pb.read_text(encoding="utf-8", errors="ignore")
        lic = parse_license(txt)
        rows.append((d.name, lic, str(pb)))

    out = ROOT.parent / "build_output" / "license_report.csv"
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["package", "license", "path"])
        for r in rows:
            w.writerow(r)

    print("Wrote:", out)

if __name__ == '__main__':
    main()
