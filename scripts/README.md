# Scripts Directory

## cloudflare_ddns.sh

Updates a Cloudflare DNS A record with the current public IP address (Dynamic DNS).

### Usage
1. Copy `.env.example` to `.env` and fill in your Cloudflare credentials and DNS record details:
   ```sh
   cp .env.example .env
   # Edit .env with your values
   ```
2. Run the script:
   ```sh
   ./cloudflare_ddns.sh
   ```

- The script will automatically load variables from `.env` in the same directory.
- You can also export the variables in your environment instead of using `.env`.

### Required Variables
- `CF_API_TOKEN`: Cloudflare API token with DNS edit permissions
- `CF_ZONE_ID`: Cloudflare Zone ID
- `CF_RECORD_ID`: Cloudflare DNS Record ID
- `CF_RECORD_NAME`: DNS record name (e.g., sub.domain.com)

## proxmox_acme_renew.sh

Renews and installs SSL certificates for Proxmox using acme.sh and the Cloudflare DNS API.

### Usage
1. Copy `.env.example` to `.env` and fill in your Cloudflare and Proxmox details:
   ```sh
   cp .env.example .env
   # Edit .env with your values
   ```
2. Run the script:
   ```sh
   ./proxmox_acme_renew.sh
   ```

- The script will automatically load variables from `.env` in the same directory.
- You can also export the variables in your environment instead of using `.env`.

### Required Variables
- `CF_API_TOKEN`: Cloudflare API token with DNS edit permissions
- `CF_ACCOUNT_ID`: Cloudflare Account ID
- `DOMAIN`: Domain name for the certificate (e.g., proxmox.domain.com)
- `PVE_HOST`: Proxmox host (for remote copy, if needed)
- `PVE_USER`: Proxmox user (e.g., root@pam)
- `PVE_PASS`: Proxmox password (for remote copy, if needed)