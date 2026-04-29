#!/usr/bin/env python3
"""
Creates the five Game Center leaderboards in App Store Connect for Neon
Mahjong's per-layout best-time tracking.

For each layout:
  POST /v1/gameCenterLeaderboards   — creates the leaderboard
  POST /v1/gameCenterLeaderboardLocalizations — en-US display name + format

Score format: ELAPSED_TIME_MINUTES_SECONDS so scores submitted as integer
seconds render as MM:SS (e.g. 218 → "3:38").

Sort: ASC (lower = better — fastest wins).
Submission: BEST (only the player's best score is kept).

Idempotent: skips a leaderboard whose vendorIdentifier already exists.
"""
from __future__ import annotations
import json
import subprocess
import sys
import urllib.error
import urllib.request

API = "https://api.appstoreconnect.apple.com"
APP_ID = "6764460470"
GC_DETAIL_ID = "fd563f14-3981-43da-b263-5f376930d2b3"

LEADERBOARDS = [
    {
        "vendorIdentifier": "com.anulfito.mahjong.leaderboard.bestTime.neon_pyramid",
        "referenceName":    "Neon Pyramid Best Time",
        "displayName":      "Neon Pyramid · Best Time",
    },
    {
        "vendorIdentifier": "com.anulfito.mahjong.leaderboard.bestTime.shanghai_turtle",
        "referenceName":    "Shanghai Turtle Best Time",
        "displayName":      "Shanghai Turtle · Best Time",
    },
    {
        "vendorIdentifier": "com.anulfito.mahjong.leaderboard.bestTime.dragon",
        "referenceName":    "Dragon Best Time",
        "displayName":      "Dragon · Best Time",
    },
    {
        "vendorIdentifier": "com.anulfito.mahjong.leaderboard.bestTime.sparkstone",
        "referenceName":    "Sparkstone Best Time",
        "displayName":      "Sparkstone · Best Time",
    },
    {
        "vendorIdentifier": "com.anulfito.mahjong.leaderboard.bestTime.cathedral",
        "referenceName":    "Cathedral Best Time",
        "displayName":      "Cathedral · Best Time",
    },
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


def existing_leaderboards(token: str) -> dict[str, str]:
    """Returns {vendorIdentifier: leaderboardID} of leaderboards already in
    Game Center for this app."""
    out: dict[str, str] = {}
    next_path = (
        f"/v1/gameCenterDetails/{GC_DETAIL_ID}/gameCenterLeaderboards?limit=200"
    )
    while next_path:
        status, data = call("GET", next_path, token)
        if status != 200 or not isinstance(data, dict):
            break
        for lb in data.get("data", []):
            attrs = lb["attributes"]
            out[attrs.get("vendorIdentifier", "")] = lb["id"]
        next_path = data.get("links", {}).get("next")
    return out


def create_leaderboard(token: str, lb: dict) -> str | None:
    body = {
        "data": {
            "type": "gameCenterLeaderboards",
            "attributes": {
                "referenceName":      lb["referenceName"],
                "vendorIdentifier":   lb["vendorIdentifier"],
                "scoreSortType":      "ASC",
                "defaultFormatter":   "INTEGER",
                "submissionType":     "BEST_SCORE",
                "scoreRangeStart":    "0",
                "scoreRangeEnd":      "86400",
            },
            "relationships": {
                "gameCenterDetail": {
                    "data": {"type": "gameCenterDetails", "id": GC_DETAIL_ID}
                }
            }
        }
    }
    status, payload = call("POST", "/v1/gameCenterLeaderboards", token, body)
    if status not in (200, 201):
        print(f"    [✗] create failed: HTTP {status}\n        {payload}")
        return None
    lb_id = payload["data"]["id"]
    print(f"    created: {lb_id}")
    return lb_id


def add_localization(token: str, lb_id: str, lb: dict) -> None:
    body = {
        "data": {
            "type": "gameCenterLeaderboardLocalizations",
            "attributes": {
                "locale": "en-US",
                "name": lb["displayName"],
                "formatterSuffix": "seconds",
                "formatterSuffixSingular": "second",
            },
            "relationships": {
                "gameCenterLeaderboard": {
                    "data": {"type": "gameCenterLeaderboards", "id": lb_id}
                }
            }
        }
    }
    status, payload = call("POST", "/v1/gameCenterLeaderboardLocalizations", token, body)
    if status in (200, 201):
        print(f"    [✓] localization en-US")
    else:
        print(f"    [✗] localization failed: HTTP {status}\n        {payload}")


def main() -> int:
    print("Acquiring JWT…")
    token = jwt()
    existing = existing_leaderboards(token)

    for lb in LEADERBOARDS:
        print(f"\n--- {lb['vendorIdentifier']} ---")
        if lb["vendorIdentifier"] in existing:
            print(f"    existing: {existing[lb['vendorIdentifier']]}  (skipping)")
            continue
        lb_id = create_leaderboard(token, lb)
        if lb_id:
            add_localization(token, lb_id, lb)

    print("\nDone. Verify in App Store Connect → Services → Game Center.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
