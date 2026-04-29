#!/usr/bin/env python3
"""
Extracts named PNG attachments from an .xcresult bundle.

Used by take-screenshots.sh: each ScreenshotTests test attaches a screenshot
named "scene-<name>"; this script walks the result bundle, fetches each test's
detailed summary (where attachments live), and writes the PNGs out as
<name>.png in the destination directory.
"""
from __future__ import annotations
import json
import subprocess
import sys
from pathlib import Path


def xcresult_get(path: Path, ref: str | None = None) -> dict:
    cmd = [
        "xcrun", "xcresulttool", "get",
        "--legacy",
        "--format", "json",
        "--path", str(path),
    ]
    if ref:
        cmd += ["--id", ref]
    out = subprocess.check_output(cmd)
    return json.loads(out)


def xcresult_export(path: Path, ref: str, dest: Path) -> None:
    subprocess.check_call([
        "xcrun", "xcresulttool", "export",
        "--legacy",
        "--type", "file",
        "--path", str(path),
        "--id", ref,
        "--output-path", str(dest),
    ])


def find_refs_named(node, key: str) -> list[str]:
    """Find every Reference id where the parent dict key matches `key`."""
    found = []
    def walk(n, parent_key=""):
        if isinstance(n, dict):
            if parent_key == key and n.get("_type", {}).get("_name") == "Reference":
                ref_id = n.get("id", {}).get("_value")
                if ref_id:
                    found.append(ref_id)
            for k, v in n.items():
                walk(v, k)
        elif isinstance(n, list):
            for v in n:
                walk(v, parent_key)
    walk(node)
    return found


def find_attachments(node) -> list[tuple[str, str]]:
    """Recursively walk JSON looking for ActionTestAttachment nodes."""
    found = []
    if isinstance(node, dict):
        if node.get("_type", {}).get("_name") == "ActionTestAttachment":
            name = node.get("name", {}).get("_value", "")
            payload = node.get("payloadRef", {}).get("id", {}).get("_value", "")
            if name and payload:
                found.append((name, payload))
        for v in node.values():
            found.extend(find_attachments(v))
    elif isinstance(node, list):
        for v in node:
            found.extend(find_attachments(v))
    return found


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: extract_screenshots.py <xcresult-bundle> <out-dir>", file=sys.stderr)
        return 2
    bundle = Path(sys.argv[1])
    out_dir = Path(sys.argv[2])
    out_dir.mkdir(parents=True, exist_ok=True)

    # Top of the bundle.
    root = xcresult_get(bundle)

    # Each action result has a testsRef; the testsRef document in turn names per-
    # test summaryRef blobs that contain the actual attachments.
    tests_refs = []
    for action in root.get("actions", {}).get("_values", []):
        tests_ref = action.get("actionResult", {}).get("testsRef", {}).get("id", {}).get("_value")
        if tests_ref:
            tests_refs.append(tests_ref)

    summary_refs = set()
    for ref in tests_refs:
        plan = xcresult_get(bundle, ref)
        for sref in find_refs_named(plan, "summaryRef"):
            summary_refs.add(sref)

    attachments: list[tuple[str, str]] = []
    for sref in summary_refs:
        detail = xcresult_get(bundle, sref)
        attachments.extend(find_attachments(detail))

    # Deduplicate by name (multiple attempts could attach the same name; keep first).
    seen = set()
    written = 0
    for name, payload in attachments:
        if not name.startswith("scene-"):
            continue
        scene = name[len("scene-"):]
        if scene in seen:
            continue
        seen.add(scene)
        dest = out_dir / f"{scene}.png"
        xcresult_export(bundle, payload, dest)
        written += 1
    print(f"  extracted {written} screenshot(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
