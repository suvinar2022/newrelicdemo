#!/bin/bash

NEW_RELIC_API_KEY=$1
NEW_RELIC_APP_ID=$2
REVISION=$3
USER=$4
DESCRIPTION=$5

curl -X POST 
"https://api.newrelic.com/v2/applications/${NEW_RELIC_APP_ID}/deployments.json" \
  -H "Api-Key:${NEW_RELIC_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
        "deployment": {
          "revision": "'"${REVISION}"'",
          "user": "'"${USER}"'",
          "description": "'"${DESCRIPTION}"'"
        }
      }'

