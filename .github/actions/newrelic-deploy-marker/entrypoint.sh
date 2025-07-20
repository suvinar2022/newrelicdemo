#!/bin/bash

NEW_RELIC_API_KEY=$1
NEW_RELIC_APP_ID=$2
REVISION=$3
USER=$4
DESCRIPTION=$5

# 🔍 Debug logs (safe partial key output)
echo "[DEBUG] NEW_RELIC_API_KEY: ${NEW_RELIC_API_KEY:0:4}******"
echo "[DEBUG] NEW_RELIC_APP_ID: $NEW_RELIC_APP_ID"
echo "[DEBUG] REVISION: $REVISION"
echo "[DEBUG] USER: $USER"
echo "[DEBUG] DESCRIPTION: $DESCRIPTION"

# 🚫 Validate required inputs
if [ -z "$NEW_RELIC_API_KEY" ] || [ -z "$NEW_RELIC_APP_ID" ]; then
  echo "❌ ERROR: Missing required inputs (API key or App ID)"
  exit 1
fi

# ✅ Correct curl syntax
curl -X POST "https://api.newrelic.com/v2/applications/${NEW_RELIC_APP_ID}/deployments.json" \
  -H "Api-Key: ${NEW_RELIC_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
        \"deployment\": {
          \"revision\": \"${REVISION}\",
          \"user\": \"${USER}\",
          \"description\": \"${DESCRIPTION}\"
        }
      }"
