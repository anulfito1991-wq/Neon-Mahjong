#!/usr/bin/env python3
"""
Creates the four non-consumable IAPs in App Store Connect for Neon Mahjong:

  com.anulfito.mahjong.theme.solarflare    $1.99
  com.anulfito.mahjong.theme.cyberbloom    $1.99
  com.anulfito.mahjong.theme.oceandrift    $1.99
  com.anulfito.mahjong.removeads           $3.99

For each product:
  1. POST /v2/inAppPurchases — creates the product
  2. POST /v1/inAppPurchaseLocalizations — display name + description (en-US)
  3. GET pricePoints, find tier matching desired customerPrice (USA)
  4. POST /v1/inAppPurchasePriceSchedules — sets price across all territories

Idempotent: if a product with the given productId already exists, that product
is reused and only missing localization/pricing is created.
"""
from __future__ import annotations
import json
import subprocess
import sys
import urllib.error
import urllib.request

API = "https://api.appstoreconnect.apple.com"
APP_ID = "6764460470"

PRODUCTS = [
    {
        "productId": "com.anulfito.mahjong.theme.solarflare",
        "name": "Solar Flare Theme",
        "type": "NON_CONSUMABLE",
        "reviewNote": "Open Settings → Appearance → Themes → tap Solar Flare to test.",
        "displayName": "Solar Flare Theme",
        "description": "Sunset reds, deep oranges, and gold. Warm and dramatic.",
        "price": "1.99",
    },
    {
        "productId": "com.anulfito.mahjong.theme.cyberbloom",
        "name": "Cyberbloom Theme",
        "type": "NON_CONSUMABLE",
        "reviewNote": "Open Settings → Appearance → Themes → tap Cyberbloom to test.",
        "displayName": "Cyberbloom Theme",
        "description": "Hot magenta and lavender. Florals in moonlight.",
        "price": "1.99",
    },
    {
        "productId": "com.anulfito.mahjong.theme.oceandrift",
        "name": "Ocean Drift Theme",
        "type": "NON_CONSUMABLE",
        "reviewNote": "Open Settings → Appearance → Themes → tap Ocean Drift to test.",
        "displayName": "Ocean Drift Theme",
        "description": "Cool teals and aquamarines. Below the waves.",
        "price": "1.99",
    },
    {
        "productId": "com.anulfito.mahjong.removeads",
        "name": "Remove Ads",
        "type": "NON_CONSUMABLE",
        "reviewNote": "Open Settings → Upgrades → Remove Ads to test purchase.",
        "displayName": "Remove Ads",
        "description": "No ads ever, plus unlimited hints. One-time buy.",
        "price": "3.99",
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


def find_existing_iap(token: str, product_id: str) -> str | None:
    # The "list IAPs for an app" endpoint is /v1/apps/{id}/inAppPurchasesV2.
    # filter[productId] works on the v1 endpoint.
    status, data = call(
        "GET",
        f"/v1/apps/{APP_ID}/inAppPurchasesV2?filter[productId]={product_id}&limit=5",
        token,
    )
    if status == 200 and isinstance(data, dict):
        for p in data.get("data", []):
            if p["attributes"]["productId"] == product_id:
                return p["id"]
    return None


def create_iap(token: str, p: dict) -> str | None:
    body = {
        "data": {
            "type": "inAppPurchases",
            "attributes": {
                "name": p["name"],
                "productId": p["productId"],
                "inAppPurchaseType": p["type"],
                "reviewNote": p["reviewNote"],
            },
            "relationships": {
                "app": {"data": {"type": "apps", "id": APP_ID}}
            }
        }
    }
    status, payload = call("POST", "/v2/inAppPurchases", token, body)
    if status not in (200, 201):
        print(f"    [✗] create failed: HTTP {status}\n        {payload}")
        return None
    iap_id = payload["data"]["id"]
    print(f"    created: {iap_id}")
    return iap_id


def has_localization(token: str, iap_id: str) -> bool:
    status, data = call(
        "GET",
        f"/v2/inAppPurchases/{iap_id}/inAppPurchaseLocalizations",
        token,
    )
    if status == 200 and isinstance(data, dict):
        return any(l["attributes"]["locale"] == "en-US" for l in data.get("data", []))
    return False


def add_localization(token: str, iap_id: str, p: dict) -> None:
    body = {
        "data": {
            "type": "inAppPurchaseLocalizations",
            "attributes": {
                "locale": "en-US",
                "name": p["displayName"],
                "description": p["description"],
            },
            "relationships": {
                "inAppPurchaseV2": {
                    "data": {"type": "inAppPurchases", "id": iap_id}
                }
            }
        }
    }
    status, payload = call("POST", "/v1/inAppPurchaseLocalizations", token, body)
    if status in (200, 201):
        print(f"    [✓] localization en-US")
    else:
        print(f"    [✗] localization failed: HTTP {status}\n        {payload}")


def find_price_point(token: str, iap_id: str, customer_price: str) -> str | None:
    """Walks pricePoints (paginated, filter by USA) until we find the one whose
    customerPrice exactly matches `customer_price`."""
    next_path = (
        f"/v2/inAppPurchases/{iap_id}/pricePoints"
        f"?filter[territory]=USA&limit=200"
    )
    while next_path:
        status, data = call("GET", next_path, token)
        if status != 200 or not isinstance(data, dict):
            return None
        for pp in data.get("data", []):
            if pp["attributes"].get("customerPrice") == customer_price:
                return pp["id"]
        next_path = data.get("links", {}).get("next")
    return None


def has_price_schedule(token: str, iap_id: str) -> bool:
    status, data = call(
        "GET",
        f"/v2/inAppPurchases/{iap_id}/iapPriceSchedule",
        token,
    )
    return status == 200 and isinstance(data, dict) and data.get("data") is not None


def set_price(token: str, iap_id: str, customer_price: str) -> None:
    point_id = find_price_point(token, iap_id, customer_price)
    if not point_id:
        print(f"    [✗] could not find ${customer_price} price point for USA")
        return
    body = {
        "data": {
            "type": "inAppPurchasePriceSchedules",
            "relationships": {
                "inAppPurchase": {
                    "data": {"type": "inAppPurchases", "id": iap_id}
                },
                "baseTerritory": {
                    "data": {"type": "territories", "id": "USA"}
                },
                "manualPrices": {
                    "data": [{"type": "inAppPurchasePrices", "id": "${price1}"}]
                },
            }
        },
        "included": [
            {
                "type": "inAppPurchasePrices",
                "id": "${price1}",
                "attributes": {"startDate": None},
                "relationships": {
                    "inAppPurchasePricePoint": {
                        "data": {"type": "inAppPurchasePricePoints", "id": point_id}
                    }
                }
            }
        ]
    }
    status, payload = call("POST", "/v1/inAppPurchasePriceSchedules", token, body)
    if status in (200, 201):
        print(f"    [✓] price set: ${customer_price} (USA base, all territories)")
    else:
        print(f"    [✗] price failed: HTTP {status}\n        {payload}")


def main() -> int:
    print("Acquiring JWT…")
    token = jwt()

    for p in PRODUCTS:
        print(f"\n--- {p['productId']} ---")
        iap_id = find_existing_iap(token, p["productId"])
        if iap_id:
            print(f"    existing IAP: {iap_id}")
        else:
            iap_id = create_iap(token, p)
            if not iap_id:
                continue

        if not has_localization(token, iap_id):
            add_localization(token, iap_id, p)
        else:
            print(f"    [✓] localization en-US (already set)")

        if not has_price_schedule(token, iap_id):
            set_price(token, iap_id, p["price"])
        else:
            print(f"    [✓] price (already set)")

    print("\nDone. Verify in App Store Connect → Monetization → In-App Purchases.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
