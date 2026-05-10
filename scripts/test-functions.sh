#!/usr/bin/env bash
# Test deployed Supabase edge functions
# Usage: ./scripts/test-functions.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$SCRIPT_DIR/.env" 2>/dev/null || {
  echo "ERROR: .env not found at $SCRIPT_DIR/.env"
  exit 1
}

SUPABASE_URL="${EXPO_PUBLIC_SUPABASE_URL}"
ANON_KEY="${EXPO_PUBLIC_SUPABASE_ANON_KEY}"
TODAY=$(date +%Y-%m-%d)

echo "=== 1. USDA Search ==="
echo "Searching for 'banana'..."
curl -s -X POST "${SUPABASE_URL}/functions/v1/usda-search" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ANON_KEY}" \
  -d '{"query":"banana","pageSize":2}' \
  | python3 -m json.tool 2>/dev/null || echo "(raw output)"

echo ""
echo "=== 2. Gemini Day Generation ==="
curl -s -X POST "${SUPABASE_URL}/functions/v1/gemma-generate-day" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ANON_KEY}" \
  -d "{\"profile\":{},\"targetCalories\":2000,\"macros\":{\"protein\":80,\"carbs\":250,\"fat\":65},\"dayName\":\"Monday\",\"date\":\"$TODAY\"}" \
  | python3 -m json.tool 2>/dev/null || echo "(raw output)"

echo ""
echo "=== 3. Gemini Week Generation ==="
curl -s -X POST "${SUPABASE_URL}/functions/v1/gemma-generate-week" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ANON_KEY}" \
  -d "{\"profile\":{},\"targetCalories\":2000,\"macros\":{\"protein\":80,\"carbs\":250,\"fat\":65},\"weekStartDate\":\"$TODAY\"}" \
  | python3 -m json.tool 2>/dev/null || echo "(raw output)"

echo ""
echo "=== DONE ==="
