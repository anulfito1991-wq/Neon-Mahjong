#!/usr/bin/env python3
"""
Uploads marketing screenshots to App Store Connect for the Neon Mahjong v1.0
listing. Handles the three-step ASC upload (create resource → PUT chunks →
commit) and logs each step.

Uploads from:
  Screenshots/iPhone-6.9/  → display type APP_IPHONE_69
  Screenshots/iPad-13/     → display type APP_IPAD_PRO_3GEN_129

Each folder must contain: menu.png, game.png, layouts.png, stats.png, win.png
(in that display order).
"""
from __future__ import annotations
import hashlib
import json
import os
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path

API = "https://api.appstoreconnect.apple.com/v1"
PROJECT = Path("/Users/anulfito/Desktop/Mahjong project")
VERSION_LOC_ID = "9eac0aed-9f92-4e73-b3dc-d5711d4e4984"

# Display order matches the order Apple shows screenshots.
SCENE_ORDER = ["menu", "game", "layouts", "stats", "win"]

DEVICE_SETS = [
    {
        "label": "iPhone 6.7\" (resized from 6.9\" captures)",
        "folder": PROJECT / "Screenshots/uploaded/iphone-67",
        "displayType": "APP_IPHONE_67",
    },
    {
        "label": "iPad Pro 12.9\" (resized from 13\" M5 captures)",
        "folder": PROJECT / "Screenshots/uploaded/ipad-129",
        "displayType": "APP_IPAD_PRO_3GEN_129",
    },
]


def jwt() -> str:
    return subprocess.check_output(
        ["python3", "/Users/anulfito/Desktop/NeonBlocks/NeonBlocks/tools/asc_jwt.py"]
    ).decode().strip()


def api_request(method: str, path_or_url: str, token: str,
                body: dict | None = None) -> tuple[int, dict | str]:
    url = path_or_url if path_or_url.startswith("http") else f"{API}{path_or_url}"
    data = json.dumps(body).encode() if body else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Authorization", f"Bearer {token}")
    if body:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as resp:
            raw = resp.read()
            return resp.status, (json.loads(raw) if raw else {})
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()


def find_or_create_screenshot_set(token: str, display_type: str) -> str:
    """Returns the appScreenshotSet ID for the given display type, creating it
    if it doesn't exist yet."""
    status, data = api_request(
        "GET",
        f"/appStoreVersionLocalizations/{VERSION_LOC_ID}/appScreenshotSets",
        token,
    )
    if status == 200 and isinstance(data, dict):
        for s in data.get("data", []):
            if s["attributes"]["screenshotDisplayType"] == display_type:
                print(f"    set already exists: {s['id']}")
                return s["id"]

    body = {
        "data": {
            "type": "appScreenshotSets",
            "attributes": {"screenshotDisplayType": display_type},
            "relationships": {
                "appStoreVersionLocalization": {
                    "data": {
                        "type": "appStoreVersionLocalizations",
                        "id": VERSION_LOC_ID,
                    }
                }
            }
        }
    }
    status, payload = api_request("POST", "/appScreenshotSets", token, body)
    if status not in (200, 201):
        raise RuntimeError(f"Could not create screenshot set: HTTP {status}\n{payload}")
    set_id = payload["data"]["id"]
    print(f"    created set: {set_id}")
    return set_id


def upload_screenshot(token: str, set_id: str, image_path: Path) -> None:
    file_size = image_path.stat().st_size
    file_name = image_path.name

    # Step 1: reserve a screenshot resource (returns upload operations)
    body = {
        "data": {
            "type": "appScreenshots",
            "attributes": {"fileName": file_name, "fileSize": file_size},
            "relationships": {
                "appScreenshotSet": {
                    "data": {"type": "appScreenshotSets", "id": set_id}
                }
            }
        }
    }
    status, payload = api_request("POST", "/appScreenshots", token, body)
    if status not in (200, 201):
        raise RuntimeError(f"Reserve failed for {file_name}: HTTP {status}\n{payload}")
    screenshot = payload["data"]
    screenshot_id = screenshot["id"]
    upload_ops = screenshot["attributes"]["uploadOperations"]

    # Step 2: PUT each chunk's bytes to its URL
    with image_path.open("rb") as f:
        data = f.read()
    md5 = hashlib.md5(data).hexdigest()

    for op in upload_ops:
        op_url = op["url"]
        offset = op["offset"]
        length = op["length"]
        chunk = data[offset:offset + length]
        put = urllib.request.Request(op_url, data=chunk, method=op["method"])
        for h in op["requestHeaders"]:
            put.add_header(h["name"], h["value"])
        try:
            with urllib.request.urlopen(put) as resp:
                if resp.status not in (200, 201, 204):
                    raise RuntimeError(f"PUT chunk failed: HTTP {resp.status}")
        except urllib.error.HTTPError as e:
            raise RuntimeError(f"PUT chunk failed: HTTP {e.code}\n{e.read().decode()}")

    # Step 3: commit upload
    commit_body = {
        "data": {
            "type": "appScreenshots",
            "id": screenshot_id,
            "attributes": {"uploaded": True, "sourceFileChecksum": md5},
        }
    }
    status, payload = api_request("PATCH", f"/appScreenshots/{screenshot_id}",
                                   token, commit_body)
    if status not in (200, 201):
        raise RuntimeError(f"Commit failed for {file_name}: HTTP {status}\n{payload}")
    print(f"    [✓] {file_name} ({file_size // 1024} KB)")


def main() -> int:
    print("Acquiring JWT…")
    token = jwt()

    for device in DEVICE_SETS:
        print(f"\n--- {device['label']} → {device['displayType']} ---")
        if not device["folder"].is_dir():
            print(f"    SKIP: folder not found at {device['folder']}")
            continue
        set_id = find_or_create_screenshot_set(token, device["displayType"])
        for scene in SCENE_ORDER:
            png = device["folder"] / f"{scene}.png"
            if not png.is_file():
                print(f"    SKIP {scene}.png (not found)")
                continue
            try:
                upload_screenshot(token, set_id, png)
            except RuntimeError as e:
                print(f"    [✗] {png.name} → {e}")

    print("\nDone. Verify in App Store Connect → Version 1.0 Information → Previews and Screenshots.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
