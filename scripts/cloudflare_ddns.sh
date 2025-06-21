#!/bin/bash
# Cloudflare DDNS update script
# Requirements: curl, jq
# Usage: Set variables in .env file in the same directory or export them in the environment

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
  set -a
  . "$SCRIPT_DIR/.env"
  set +a
fi

: "${CF_API_TOKEN:?CF_API_TOKEN is required}"
: "${CF_ZONE_ID:?CF_ZONE_ID is required}"
: "${CF_RECORD_ID:?CF_RECORD_ID is required}"
: "${CF_RECORD_NAME:?CF_RECORD_NAME is required}"

IP=$(curl -s https://api.ipify.org)

RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records/$CF_RECORD_ID" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{"type":"A","name":"'$CF_RECORD_NAME'","content":"'$IP'","ttl":120,"proxied":false}')

if echo "$RESPONSE" | grep -q '"success":true'; then
  echo "Cloudflare DNS record updated to $IP"
else
  echo "Failed to update Cloudflare DNS record: $RESPONSE"
  exit 1
fi