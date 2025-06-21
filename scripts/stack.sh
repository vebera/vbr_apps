#!/bin/bash
# stack.sh - Management script for Cloudflare DDNS and Proxmox certificates

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
LOG_DIR="$SCRIPT_DIR/logs"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# --- Helper Functions ---

# Load environment variables if .env exists
load_env() {
    if [ -f "$ENV_FILE" ]; then
        set -a
        # shellcheck source=/dev/null
        source "$ENV_FILE"
        set +a
    else
        echo -e "${RED}Error: .env file not found. Please run '$0 setup-env' first.${NC}"
        exit 1
    fi
}

# Show help message
show_help() {
    echo -e "${GREEN}Usage: $0 [command]${NC}"
    echo
    echo "This script manages Cloudflare DDNS updates and Proxmox certificate renewals."
    echo
    echo "Available commands:"
    echo -e "  ${YELLOW}setup-env${NC}          - Create .env file from the example template."
    echo -e "  ${YELLOW}update-dns${NC}         - Update Cloudflare DNS records with your current public IP."
    echo -e "  ${YELLOW}renew-cert${NC}         - Renew and install the SSL certificate for Proxmox."
    echo -e "  ${YELLOW}install-cron${NC}       - Install cron jobs to automate DNS updates and certificate renewals."
    echo -e "  ${YELLOW}status${NC}             - Show current configuration, IP, and DNS status."
    echo -e "  ${YELLOW}help${NC}               - Show this help message."
    echo
    echo "Examples:"
    echo "  $0 setup-env"
    echo "  $0 update-dns"
    echo "  $0 install-cron"
}

# --- Core Functions ---

# Create .env file from .env.example
setup_env() {
    local example_file="$SCRIPT_DIR/.env.example"
    if [ ! -f "$example_file" ]; then
        echo -e "${RED}Error: .env.example not found! Cannot create .env file.${NC}"
        exit 1
    fi

    if [ -f "$ENV_FILE" ]; then
        echo -e "${YELLOW}.env file already exists. Backing up to .env.bak...${NC}"
        cp "$ENV_FILE" "${ENV_FILE}.bak"
    fi

    cp "$example_file" "$ENV_FILE"
    echo -e "${GREEN}Created .env file at $ENV_FILE${NC}"
    echo -e "${YELLOW}Please edit this file with your actual Cloudflare and Proxmox details.${NC}"
}

# Update multiple Cloudflare DNS A-records
update_dns() {
    load_env
    echo -e "${GREEN}--- Starting DNS Update ---${NC}"

    : "${CF_API_TOKEN:?CF_API_TOKEN is not set in .env}"
    : "${CF_ZONE_ID:?CF_ZONE_ID is not set in .env}"
    : "${CF_RECORDS:?CF_RECORDS is not set in .env}"

    local public_ip
    public_ip=$(curl -s https://api.ipify.org)
    if [ -z "$public_ip" ]; then
        echo -e "${RED}Error: Failed to get public IP address.${NC}"
        exit 1
    fi
    echo "Current public IP: $public_ip"

    IFS=',' read -r -a records_array <<< "$CF_RECORDS"

    for record_name in "${records_array[@]}"; do
        record_name=$(echo "$record_name" | xargs) # Trim whitespace
        [ -z "$record_name" ] && continue

        echo -e "\nProcessing record: ${YELLOW}$record_name${NC}"

        # Get record details from Cloudflare API
        local record_details
        record_details=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records?type=A&name=$record_name" \
          -H "Authorization: Bearer $CF_API_TOKEN" \
          -H "Content-Type: application/json")

        local success
        success=$(echo "$record_details" | jq -r '.success')
        if [ "$success" != "true" ]; then
            echo -e "${RED}  Error: Failed to fetch DNS record details from Cloudflare.${NC}"
            continue
        fi

        local record_ip
        record_ip=$(echo "$record_details" | jq -r '.result[0].content')
        local record_id
        record_id=$(echo "$record_details" | jq -r '.result[0].id')

        if [ "$record_ip" == "$public_ip" ]; then
            echo -e "${GREEN}  IP address is already up to date. No change needed.${NC}"
        else
            echo "  IP mismatch. Current DNS IP is $record_ip. Updating to $public_ip..."
            local update_response
            update_response=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records/$record_id" \
              -H "Authorization: Bearer $CF_API_TOKEN" \
              -H "Content-Type: application/json" \
              --data "{\"type\":\"A\",\"name\":\"$record_name\",\"content\":\"$public_ip\",\"ttl\":120,\"proxied\":false}")

            if echo "$update_response" | jq -e '.success' > /dev/null; then
                echo -e "${GREEN}  Successfully updated DNS record for $record_name.${NC}"
            else
                local error_message
                error_message=$(echo "$update_response" | jq -r '.errors[0].message')
                echo -e "${RED}  Error updating DNS record: $error_message${NC}"
            fi
        fi
    done
    echo -e "${GREEN}--- DNS Update Finished ---${NC}"
}

# Renew Proxmox certificate using acme.sh
renew_cert() {
    load_env
    echo -e "${GREEN}--- Starting Proxmox Certificate Renewal ---${NC}"

    : "${CF_API_TOKEN:?CF_API_TOKEN is not set for Proxmox renewal}"
    : "${CF_ACCOUNT_ID:?CF_ACCOUNT_ID is not set for Proxmox renewal}"
    : "${DOMAIN:?DOMAIN for Proxmox is not set}"

    # Set environment variables for acme.sh
    export CF_Token="$CF_API_TOKEN"
    export CF_Account_ID="$CF_ACCOUNT_ID"

    # Check if acme.sh is installed
    if [ ! -f "$HOME/.acme.sh/acme.sh" ]; then
        echo -e "${RED}Error: acme.sh not found in $HOME/.acme.sh/${NC}"
        echo "Please install it from https://github.com/acmesh-official/acme.sh"
        exit 1
    fi

    echo "Issuing/Renewing certificate for $DOMAIN..."
    "$HOME"/.acme.sh/acme.sh --issue --dns dns_cf -d "$DOMAIN" --force

    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to issue certificate from acme.sh.${NC}"
        exit 1
    fi

    echo "Installing certificate to Proxmox..."
    "$HOME"/.acme.sh/acme.sh --install-cert -d "$DOMAIN" \
      --cert-file /etc/pve/local/pve-ssl.pem \
      --key-file /etc/pve/local/pve-ssl.key \
      --fullchain-file /etc/pve/local/pve-ssl.pem \
      --reloadcmd "systemctl restart pveproxy && systemctl restart pvedaemon"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Certificate installed and services restarted successfully.${NC}"
    else
        echo -e "${RED}Error: Failed to install certificate to Proxmox.${NC}"
    fi
    echo -e "${GREEN}--- Certificate Renewal Finished ---${NC}"
}

# Install cron jobs for automation
install_cron() {
    local script_path
    script_path="$(realpath "$0")"
    local log_dns="$LOG_DIR/update-dns.log"
    local log_cert="$LOG_DIR/renew-cert.log"

    # Cron job for DNS updates (every 15 minutes)
    local dns_job="*/15 * * * * $script_path update-dns >> $log_dns 2>&1"
    # Cron job for certificate renewal (1st of every month at 2 AM)
    local cert_job="0 2 1 * * $script_path renew-cert >> $log_cert 2>&1"

    (crontab -l 2>/dev/null | grep -v "update-dns" | grep -v "renew-cert"; \
     echo "$dns_job"; echo "$cert_job") | crontab -

    echo -e "${GREEN}Cron jobs installed successfully.${NC}"
    echo "Current crontab:"
    crontab -l
}

# Show status
show_status() {
    load_env
    echo -e "${GREEN}--- System Status ---${NC}"
    echo -e "Script Directory: $SCRIPT_DIR"
    echo -e "Environment File: $ENV_FILE"

    if [ -f "$ENV_FILE" ]; then
        echo -e "\n${GREEN}Environment Variables:${NC}"
        # Mask sensitive values
        grep -v '^#' "$ENV_FILE" | grep -v '^$' | while read -r line; do
            if [[ $line == *"TOKEN"* ]] || [[ $line == *"PASS"* ]]; then
                key=$(echo "$line" | cut -d'=' -f1)
                echo -e "  ${YELLOW}$key=${RED}<hidden>${NC}"
            else
                echo -e "  ${YELLOW}$line${NC}"
            fi
        done
    fi

    echo -e "\n${GREEN}Network Status:${NC}"
    local public_ip
    public_ip=$(curl -s https://api.ipify.org)
    echo -e "  Current Public IP: ${YELLOW}$public_ip${NC}"

    echo -e "\n${GREEN}DNS Records Status:${NC}"
    IFS=',' read -r -a records_array <<< "$CF_RECORDS"
    for record_name in "${records_array[@]}"; do
        record_name=$(echo "$record_name" | xargs)
        [ -z "$record_name" ] && continue
        local dns_ip
        dns_ip=$(dig +short "$record_name" @1.1.1.1)
        if [ "$dns_ip" == "$public_ip" ]; then
            echo -e "  - ${GREEN}$record_name -> $dns_ip (OK)${NC}"
        else
            echo -e "  - ${RED}$record_name -> $dns_ip (MISMATCH)${NC}"
        fi
    done
}


# --- Main Logic ---

main() {
    # Show help if no arguments provided
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi

    local command="$1"
    shift # remove command from arguments

    case "$command" in
        setup-env)
            setup_env
            ;;
        update-dns)
            update_dns
            ;;
        renew-cert)
            renew_cert
            ;;
        install-cron)
            install_cron
            ;;
        status)
            show_status
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}Error: Unknown command '$command'${NC}"
            show_help
            exit 1
            ;;
    esac
}

main "$@"