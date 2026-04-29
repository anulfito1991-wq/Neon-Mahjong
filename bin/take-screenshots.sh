#!/usr/bin/env bash
#
# Drives the ScreenshotTests UI tests across the App Store device matrix and
# extracts the PNG attachments into ./Screenshots/<device-folder>/.
#
# Required simulators (Xcode 17+, 2026 App Store):
#   - iPhone 17 Pro Max  (6.9")  — primary iPhone
#   - iPad Pro 13-inch (M5)      — primary iPad
#
# Apple auto-scales smaller device sizes from these two, so we only ship the
# largest of each form factor.
#
# Usage: ./bin/take-screenshots.sh
#
set -euo pipefail

cd "$(dirname "$0")/.."
PROJECT="Mahjong project.xcodeproj"
SCHEME="Mahjong project"
OUT_ROOT="Screenshots"
TMP_RESULTS=".screenshot-results"

# device label → simulator name
DEVICES=(
  "iPhone-6.9:iPhone 17 Pro Max"
  "iPad-13:iPad Pro 13-inch (M5)"
)

mkdir -p "$OUT_ROOT"
rm -rf "$TMP_RESULTS"
mkdir -p "$TMP_RESULTS"

for entry in "${DEVICES[@]}"; do
  label="${entry%%:*}"
  device="${entry##*:}"
  echo
  echo "============================================================"
  echo "  $label  →  $device"
  echo "============================================================"

  result_bundle="$TMP_RESULTS/$label.xcresult"
  rm -rf "$result_bundle"

  xcodebuild test \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,name=$device" \
    -only-testing:"Mahjong projectUITests/ScreenshotTests" \
    -resultBundlePath "$result_bundle" \
    | xcpretty 2>/dev/null || true

  out_dir="$OUT_ROOT/$label"
  mkdir -p "$out_dir"
  rm -f "$out_dir"/*.png

  # Extract every PNG attachment named "scene-<name>".
  python3 "bin/extract_screenshots.py" "$result_bundle" "$out_dir"
  echo "  → wrote $(ls -1 "$out_dir" | wc -l | tr -d ' ') images to $out_dir"
done

echo
echo "Done. PNGs are under $OUT_ROOT/."
