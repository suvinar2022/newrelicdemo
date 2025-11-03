#!/usr/bin/env bash
# ---------------------------------------------------------------
# post_mutations_to_nerdgraph.sh
#
# Reads all linkedAccountIds from a JSON-like file, replaces
# `linkedAccountId: 63456` in the given mutation template, and
# POSTs each mutation to New Relic's NerdGraph endpoint.
#
# Usage:
#   export NR_API_TOKEN="NRAK-xxxxxx"
#   ./post_mutations_to_nerdgraph.sh -t sample_nonprod_all.txt -i all_nonprod_linked.txt
#
# Optional flags:
#   -u  Override API URL (default: https://api.newrelic.com/graphql)
#   -o  Directory for responses (default: ./responses)
#
# ---------------------------------------------------------------

set -euo pipefail

TEMPLATE=""
ID_FILE=""
API_URL="https://api.newrelic.com/graphql"
OUTDIR="./responses"

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--template) TEMPLATE="$2"; shift 2 ;;
    -i|--ids)      ID_FILE="$2"; shift 2 ;;
    -u|--url)      API_URL="$2"; shift 2 ;;
    -o|--out)      OUTDIR="$2"; shift 2 ;;
    *) echo "Usage: $0 -t <template> -i <ids> [-u <url>] [-o <outdir>]" >&2; exit 1 ;;
  esac
done

if [[ -z "${NR_API_TOKEN:-}" ]]; then
  echo "❌ ERROR: Please export your New Relic API key first:"
  echo "   export NR_API_TOKEN=\"NRAK-xxxx\""
  exit 2
fi

[[ -f "$TEMPLATE" ]] || { echo "❌ Template not found: $TEMPLATE"; exit 3; }
[[ -f "$ID_FILE"  ]] || { echo "❌ ID list not found: $ID_FILE"; exit 4; }

mkdir -p "$OUTDIR"

# Extract numeric IDs from "id": <num> pattern
mapfile -t IDS < <(grep -Eo '"id" *: *[0-9]+' "$ID_FILE" | grep -Eo '[0-9]+' | sort -u)

if [[ ${#IDS[@]} -eq 0 ]]; then
  echo "⚠️  No valid IDs found in $ID_FILE"
  exit 5
fi

echo "📡 Sending mutations to NerdGraph..."
for ID in "${IDS[@]}"; do
  echo "→ linkedAccountId: $ID"

  # Build mutation payload
  TMP_MUTATION="$(mktemp)"
  sed "s/linkedAccountId: 63456/linkedAccountId: $ID/g" "$TEMPLATE" > "$TMP_MUTATION"

  # Collapse newlines & escape quotes for JSON payload
  QUERY_JSON=$(awk 'BEGIN{ORS="\\n"}{gsub(/\\/,"\\\\");gsub(/"/,"\\\"");print}' "$TMP_MUTATION")

  RESP_FILE="${OUTDIR}/response_${ID}.json"

  # POST to NerdGraph
  curl -sS -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -H "API-Key: ${NR_API_TOKEN}" \
    -d "{\"query\":\"${QUERY_JSON}\"}" \
    -o "$RESP_FILE"

  # Optional: print success/failure from response
  if grep -q '"errors"' "$RESP_FILE"; then
    echo "   ❌ Error for ID $ID (see $RESP_FILE)"
  else
    echo "   ✅ Success (response saved)"
  fi

  rm -f "$TMP_MUTATION"
done

echo "🏁 Done. All responses saved under: $OUTDIR"

