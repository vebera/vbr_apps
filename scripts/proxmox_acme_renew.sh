#!/bin/bash
# Proxmox ACME certificate renewal script using acme.sh and Cloudflare DNS API
# Requirements: acme.sh, curl, jq
# Usage: Set variables in .env file in the same directory or export them in the environment

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
  set -a
  . "$SCRIPT_DIR/.env"
  set +a
fi

: "${CF_API_TOKEN:?CF_API_TOKEN is required}"
: "${CF_ACCOUNT_ID:?CF_ACCOUNT_ID is required}"
: "${DOMAIN:?DOMAIN is required}"
: "${PVE_HOST:?PVE_HOST is required}"
: "${PVE_USER:?PVE_USER is required}"
: "${PVE_PASS:?PVE_PASS is required}"

export CF_Token="$CF_API_TOKEN"
export CF_Account_ID="$CF_ACCOUNT_ID"

# Issue or renew cert
~/.acme.sh/acme.sh --issue --dns dns_cf -d "$DOMAIN" --force

# Install cert to Proxmox
~/.acme.sh/acme.sh --install-cert -d "$DOMAIN" \
  --cert-file /etc/pve/local/pve-ssl.pem \
  --key-file /etc/pve/local/pve-ssl.key \
  --fullchain-file /etc/pve/local/pve-ssl.pem \
  --reloadcmd "/usr/sbin/service pveproxy restart && /usr/sbin/service pvedaemon restart"

# Optionally, use ssh/scp to copy certs to remote Proxmox if not running locally
# scp /etc/pve/local/pve-ssl.pem $PVE_USER@$PVE_HOST:/etc/pve/local/pve-ssl.pem
# scp /etc/pve/local/pve-ssl.key $PVE_USER@$PVE_HOST:/etc/pve/local/pve-ssl.key