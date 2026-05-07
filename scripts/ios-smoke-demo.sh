#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Building NutriWeek (iOS Simulator)"
xcodebuild \
  -project "$ROOT_DIR/iOS/NutriWeek/NutriWeek.xcodeproj" \
  -scheme "NutriWeek" \
  -destination 'generic/platform=iOS Simulator' \
  build

echo
echo "Build complete."
echo "Next manual checks:"
echo "1) Follow docs/phase-f-smoke-checklist.md"
echo "2) Verify usda-search and gemma-generate-week in app"
echo "3) Validate add/delete log flow and cache fallback"

