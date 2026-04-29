#!/usr/bin/env python3
"""
Uploads App Review screenshots to each in-app purchase in App Store Connect.
Apple requires one screenshot per IAP showing where the purchase is offered
in the app — used by reviewers to verify the IAP exists and works.

Mapping:
  All theme IAPs   → Screenshots/iap-review/themes.png   (Settings → Themes sheet)
  Remove Ads IAP   → Screenshots/iap-review/settings.png (Settings → Upgrades section)

Three-step upload, same as app screenshots:
  1. POST /v1/inAppPurchaseAppStoreReviewScreenshots — reserve, returns ops
  2. PUT chunks to operation URLs
  3. PATCH to commit (uploaded=true + md5)
"""
from __future__ import annotations
import hashlib
import json
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path

API = "https://api.appstoreconnect.apple.com"
PROJECT = Path("/Users/anulfito/Desktop/Mahjong project")
SHOTS = PROJECT / "Screenshots/iap-review"

# IAP id → review screenshot file
ASSIGNMENTS = [
    ("6764464520", "Solar Flare Theme",   SHOTS / "themes.png"),
    ("6764464516", "Cyberbloom Theme",    SHOTS / "themes.png"),
    ("6764464583", "Ocean Drift Theme",   SHOTS / "themes.png"),
    ("6764464584", "Remove Ads",          SHOTS / "settings.png"),
]


def jwt() -> str:
    return subprocess.check_output(
        ["python3", "/Users/anulfito/Desktop/NeonBlocks/NeonBlocks/tools/asc_jwt.py"]
    ).decode().strip()


def call(method: str, path: str, token: str, body: dict | None = None) -> tuple[int, dict | str]:
    url = path if path.startswith("http") else f"{API}{path}"
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


def existing_review_screenshot(token: str, iap_id: str) -> str | None:
    status, data = call(
        "GET",
        f"/v2/inAppPurchases/{iap_id}/appStoreReviewScreenshot",
        token,
    )
    if status == 200 and isinstance(data, dict):
        ref = data.get("data")
        return ref["id"] if ref else None
    return None


def delete_review_screenshot(token: str, screenshot_id: str) -> None:
    status, _ = call(
        "DELETE",
        f"/v1/inAppPurchaseAppStoreReviewScreenshots/{screenshot_id}",
        token,
    )
    print(f"    deleted existing screenshot {screenshot_id} (HTTP {status})")


def upload_review_screenshot(token: str, iap_id: str, image_path: Path) -> bool:
    file_size = image_path.stat().st_size
    file_name = image_path.name

    body = {
        "data": {
            "type": "inAppPurchaseAppStoreReviewScreenshots",
            "attributes": {"fileName": file_name, "fileSize": file_size},
            "relationships": {
                "inAppPurchaseV2": {
                    "data": {"type": "inAppPurchases", "id": iap_id}
                }
            }
        }
    }
    status, payload = call("POST", "/v1/inAppPurchaseAppStoreReviewScreenshots",
                           token, body)
    if status not in (200, 201):
        print(f"    [✗] reserve failed: HTTP {status}\n        {payload}")
        return False

    screenshot = payload["data"]
    screenshot_id = screenshot["id"]
    upload_ops = screenshot["attributes"]["uploadOperations"]

    with image_path.open("rb") as f:
        data = f.read()
    md5 = hashlib.md5(data).hexdigest()

    for op in upload_ops:
        chunk = data[op["offset"]:op["offset"] + op["length"]]
        put = urllib.request.Request(op["url"], data=chunk, method=op["method"])
        for h in op["requestHeaders"]:
            put.add_header(h["name"], h["value"])
        try:
            with urllib.request.urlopen(put) as resp:
                if resp.status not in (200, 201, 204):
                    print(f"    [✗] PUT chunk failed: HTTP {resp.status}")
                    return False
        except urllib.error.HTTPError as e:
            print(f"    [✗] PUT chunk failed: HTTP {e.code}\n        {e.read().decode()}")
            return False

    commit_body = {
        "data": {
            "type": "inAppPurchaseAppStoreReviewScreenshots",
            "id": screenshot_id,
            "attributes": {"uploaded": True, "sourceFileChecksum": md5},
        }
    }
    status, payload = call("PATCH",
                           f"/v1/inAppPurchaseAppStoreReviewScreenshots/{screenshot_id}",
                           token, commit_body)
    if status not in (200, 201):
        print(f"    [✗] commit failed: HTTP {status}\n        {payload}")
        return False
    print(f"    [✓] uploaded {file_name} ({file_size // 1024} KB)")
    return True


def main() -> int:
    print("Acquiring JWT…")
    token = jwt()

    for iap_id, name, png in ASSIGNMENTS:
        print(f"\n--- {name} ({iap_id}) ---")
        if not png.is_file():
            print(f"    [✗] missing: {png}")
            continue

        existing = existing_review_screenshot(token, iap_id)
        if existing:
            delete_review_screenshot(token, existing)

        upload_review_screenshot(token, iap_id, png)

    print("\nDone. Verify in App Store Connect → Monetization → In-App Purchases → each IAP → App Store Review Screenshot.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
