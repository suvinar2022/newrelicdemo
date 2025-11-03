#!/usr/bin/env bash
# Reads linkedAccountId (or "id" fields) from a file and prints them cleanly

INPUT_FILE="all_nonprod_linked.txt"

if [[ ! -f "$INPUT_FILE" ]]; then
  echo "File not found: $INPUT_FILE"
  exit 1
fi

echo "Extracting linkedAccountIds from $INPUT_FILE ..."
grep -Eo '"id" *: *[0-9]+' "$INPUT_FILE" | grep -Eo '[0-9]+' | sort -u

