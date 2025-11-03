#!/usr/bin/env bash
# Generate GraphQL mutations for each linkedAccountId found in a file

TEMPLATE="sample_nonprod_all.txt"   # Template mutation file
ID_FILE="all_nonprod_linked.txt"    # File containing IDs
OUTFILE="mutations_all.graphql"     # Combined output file

if [[ ! -f "$TEMPLATE" || ! -f "$ID_FILE" ]]; then
  echo "❌ Missing required file(s)"
  exit 1
fi

> "$OUTFILE"  # Clear output file

# Extract all numeric IDs from JSON-like structure
IDS=$(grep -Eo '"id" *: *[0-9]+' "$ID_FILE" | grep -Eo '[0-9]+' | sort -u)

for ID in $IDS; do
  echo "🧩 Writing mutation for linkedAccountId: $ID"
  
  # Replace every occurrence of the placeholder with the real ID
  sed "s/linkedAccountId: 63456/linkedAccountId: $ID/g" "$TEMPLATE" >> "$OUTFILE"
  echo -e "\n" >> "$OUTFILE"
done

echo "✅ All mutations written to: $OUTFILE"

