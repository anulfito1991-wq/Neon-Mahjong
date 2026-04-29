#!/usr/bin/env python3
"""
Pushes Neon Mahjong's metadata to App Store Connect via the ASC REST API.

Updates:
  - AppInfo categories (Games · Puzzle / Games · Board)
  - AppInfoLocalization (subtitle, privacy policy URL)
  - AppStoreVersion copyright
  - AppStoreVersionLocalization (description, keywords, what's new,
    promotional text, support URL, marketing URL)

Reads metadata strings from `Marketing/AppStoreMetadata.md` is overkill —
we just inline the canonical copy here so the script is self-sufficient.
"""
from __future__ import annotations
import json
import subprocess
import sys
import urllib.error
import urllib.request

# ── Identifiers (resolved by previous discovery) ──────────────────────────────
APP_ID           = "6764460470"
APP_INFO_ID      = "951470d1-5e48-4eb4-9ca1-b7a52270f1e7"
APP_INFO_LOC_ID  = "58beb74b-94d5-4bfc-adfe-c44280386f64"   # en-US
VERSION_ID       = "60a01b4d-f521-4cec-89d2-29999a7675a5"   # 1.0
VERSION_LOC_ID   = "9eac0aed-9f92-4e73-b3dc-d5711d4e4984"   # en-US

API = "https://api.appstoreconnect.apple.com/v1"

# ── Canonical metadata copy ───────────────────────────────────────────────────
SUBTITLE = "Match Tiles · Daily Puzzles"

PRIVACY_URL   = "https://anulfito1991-wq.github.io/Neon-Mahjong-site/privacy.html"
SUPPORT_URL   = "https://anulfito1991-wq.github.io/Neon-Mahjong-site/support.html"
MARKETING_URL = "https://anulfito1991-wq.github.io/Neon-Mahjong-site/"

COPYRIGHT = "2026 Anulfo Acosta"

PROMOTIONAL_TEXT = (
    "Now with 5 stunning layouts and Daily Challenges! Play Shanghai "
    "Turtle, Dragon, and more in modern neon style. Free to play, no time limits."
)

KEYWORDS = "mahjongg,tile,match,puzzle,brain,daily,zen,relax,offline,shanghai,pairs,classic,neon,arcade,casual"

WHATS_NEW = (
    "Welcome to Neon Mahjong Solitaire — a brand new take on the timeless "
    "tile-matching puzzle, built from the ground up for iPhone and iPad.\n\n"
    "• 5 unique board layouts including the iconic Shanghai Turtle\n"
    "• Daily Challenge with worldwide streak tracking\n"
    "• Game Center leaderboards for every layout\n"
    "• 4 themes to personalize your glow\n"
    "• Always-solvable boards (no impossible games)\n"
    "• No timers, no pressure, no energy system\n"
    "• Beautifully animated, satisfyingly tactile\n\n"
    "Enjoy the glow."
)

DESCRIPTION = (
    "Match. Glow. Repeat.\n\n"
    "Neon Mahjong Solitaire reinvents the timeless tile-matching puzzle in "
    "stunning modern neon style. Match free pairs of identical tiles to clear "
    "the board — but with a futuristic glow that brings every game to life.\n\n\n"
    "FIVE STUNNING LAYOUTS\n\n"
    "• Neon Pyramid — the modern classic (144 tiles)\n"
    "• Shanghai Turtle — the iconic shell shape (144 tiles)\n"
    "• Dragon — long, sweeping horizontal stretch (144 tiles)\n"
    "• Cathedral — tall and narrow (144 tiles)\n"
    "• Sparkstone — quick play (72 tiles, perfect for a coffee break)\n\n\n"
    "DAILY CHALLENGE\n\n"
    "A new puzzle every day, the same one for every player worldwide. Build "
    "your win streak and see how long you can keep it going. Miss a day, lose "
    "your streak — it's that simple, that compelling.\n\n\n"
    "MODERN POLISH\n\n"
    "• Smooth animations and satisfying haptics\n"
    "• Pulsing glow on every tile\n"
    "• Particle bursts on every match\n"
    "• Eye-friendly dark visuals\n"
    "• Designed for iPhone and iPad\n\n\n"
    "THOUGHTFUL GAMEPLAY\n\n"
    "• Hint system to unstick you\n"
    "• Undo any move\n"
    "• Shuffle when you're stuck\n"
    "• Always-solvable boards (no impossible games)\n"
    "• Full 144-tile set: all suits, winds, dragons, flowers, and seasons\n\n\n"
    "TRACK YOUR PROGRESS\n\n"
    "• Best times per layout\n"
    "• Win streak tracking\n"
    "• Worldwide Game Center leaderboards\n"
    "• Detailed stats screen\n\n\n"
    "PERSONALIZE WITH THEMES\n\n"
    "Unlock alternate neon palettes:\n"
    "• Solar Flare — sunset reds and gold\n"
    "• Cyberbloom — magenta in moonlight\n"
    "• Ocean Drift — below the waves\n\n\n"
    "NO PRESSURE\n\n"
    "• No timers (unless you want to track your time)\n"
    "• No energy or lives system\n"
    "• No interruptions during gameplay\n"
    "• Play offline, anytime, anywhere\n\n\n"
    "GENEROUS FREE TIER\n\n"
    "• All 5 layouts free\n"
    "• Daily Challenge free\n"
    "• 3 hints per game free\n"
    "• Watch a short ad for unlimited hints, or upgrade to Remove Ads forever\n\n\n"
    "Whether you're a Mahjong veteran or new to tile-matching puzzles, Neon "
    "Mahjong is the most beautiful way to play. Match tiles, beat your best "
    "time, and unwind in a glow-up of color and sound.\n\n"
    "Privacy: We don't collect personal data. Game Center sign-in is optional.\n\n"
    "— —\n"
    "In-App Purchases:\n"
    "• Theme Packs (Solar Flare, Cyberbloom, Ocean Drift) — $1.99 each\n"
    "• Remove Ads Forever — $3.99"
)

# ── Helpers ───────────────────────────────────────────────────────────────────

def jwt() -> str:
    out = subprocess.check_output(
        ["python3", "/Users/anulfito/Desktop/NeonBlocks/NeonBlocks/tools/asc_jwt.py"]
    )
    return out.decode().strip()

def call(method: str, path: str, token: str, body: dict | None = None):
    url = f"{API}{path}"
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
        body = e.read().decode()
        return e.code, body

def show(label: str, status: int, payload):
    ok = 200 <= status < 300
    icon = "✓" if ok else "✗"
    print(f"  [{icon}] {label} → HTTP {status}")
    if not ok:
        print(f"        {payload}")

# ── Patches ───────────────────────────────────────────────────────────────────

def patch_app_info_localization(token: str) -> None:
    body = {
        "data": {
            "type": "appInfoLocalizations",
            "id": APP_INFO_LOC_ID,
            "attributes": {
                "subtitle": SUBTITLE,
                "privacyPolicyUrl": PRIVACY_URL,
            }
        }
    }
    status, payload = call("PATCH", f"/appInfoLocalizations/{APP_INFO_LOC_ID}",
                           token, body)
    show("AppInfoLocalization (subtitle, privacy URL)", status, payload)

def patch_app_info_categories(token: str) -> None:
    # Apple forbids the same parent category in both primary & secondary slots.
    # For game apps the convention is: primaryCategory = GAMES with TWO
    # subcategories (Puzzle + Board), no separate secondary parent.
    body = {
        "data": {
            "type": "appInfos",
            "id": APP_INFO_ID,
            "relationships": {
                "primaryCategory":         {"data": {"type": "appCategories", "id": "GAMES"}},
                "primarySubcategoryOne":   {"data": {"type": "appCategories", "id": "GAMES_PUZZLE"}},
                "primarySubcategoryTwo":   {"data": {"type": "appCategories", "id": "GAMES_BOARD"}},
            }
        }
    }
    status, payload = call("PATCH", f"/appInfos/{APP_INFO_ID}", token, body)
    show("AppInfo categories (Games · Puzzle / Games · Board)", status, payload)

def patch_app_store_version(token: str) -> None:
    body = {
        "data": {
            "type": "appStoreVersions",
            "id": VERSION_ID,
            "attributes": {
                "copyright": COPYRIGHT
            }
        }
    }
    status, payload = call("PATCH", f"/appStoreVersions/{VERSION_ID}", token, body)
    show("AppStoreVersion (copyright)", status, payload)

def patch_version_localization(token: str) -> None:
    body = {
        "data": {
            "type": "appStoreVersionLocalizations",
            "id": VERSION_LOC_ID,
            "attributes": {
                # whatsNew is locked on initial 1.0 release (no prior version
                # to compare to). It becomes editable on v1.1+.
                "description":      DESCRIPTION,
                "keywords":         KEYWORDS,
                "promotionalText":  PROMOTIONAL_TEXT,
                "supportUrl":       SUPPORT_URL,
                "marketingUrl":     MARKETING_URL,
            }
        }
    }
    status, payload = call("PATCH",
                           f"/appStoreVersionLocalizations/{VERSION_LOC_ID}",
                           token, body)
    show("AppStoreVersionLocalization (description, keywords, what's new, …)",
         status, payload)

# ── Main ──────────────────────────────────────────────────────────────────────

def main() -> int:
    print("Acquiring JWT…")
    token = jwt()
    print("Pushing metadata to App Store Connect:\n")

    patch_app_info_localization(token)
    patch_app_info_categories(token)
    patch_app_store_version(token)
    patch_version_localization(token)

    print("\nDone. Verify in https://appstoreconnect.apple.com.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
