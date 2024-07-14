#!/bin/bash

set -euo pipefail

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check if a variable is set
check_var() {
    if [[ -z "${!1:-}" ]]; then
        log "Error: $1 is not set."
        exit 1
    fi
}

# Function to check router availability
check_router() {
    if timeout 5 bash -c "ping -c 1 $1" &>/dev/null; then
        echo "$1"
    else
        log "Warning: $1 is not responding to ping. Skipping."
    fi
}

# Function to upload file to GitHub
upload_to_github() {
    local file="$1"
    local content
    content=$(base64 -i "$file")
    local timestamp
    timestamp=$(date +"%Y-%m-%d %T")
    local json_fmt='{
        "message": "Backup: %s",
        "committer": {
            "name": "%s",
            "email": "%s"
        },
        "content": "%s",
        "sha": "%s"
    }'

    local sha
    sha=$(curl -sS -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/repos/$GITHUB_REPO/contents/$file" | jq -r '.sha')
    local new_sha
    new_sha=$(git hash-object "$file")

    if [[ "$new_sha" != "$sha" ]]; then
        local json
        json=$(printf "$json_fmt" "$timestamp" "$GITHUB_USER" "$GITHUB_EMAIL" "$content" "$sha")
        curl -X PUT -H "Authorization: token $GITHUB_TOKEN" -d "$json" "https://api.github.com/repos/$GITHUB_REPO/contents/$file"
    fi
}

# Check required environment variables
check_var GITHUB_TOKEN
check_var ROUTERS
check_var GITHUB_REPO
check_var GITHUB_USER
check_var GITHUB_EMAIL

# Set default values
MIKROTIK_KEY_PATH=${MIKROTIK_KEY_PATH:-"$HOME/.ssh/id_rsa"}
SHOW_SENSITIVE=${SHOW_SENSITIVE:-false}
MIKROTIK_SSH_USER=${MIKROTIK_SSH_USER:-admin}

# Check router availability
mapfile -t REACHABLE_ROUTERS < <(for router in $ROUTERS; do check_router "$router"; done)

if [[ ${#REACHABLE_ROUTERS[@]} -eq 0 ]]; then
    log "Error: No reachable routers."
    exit 1
fi

# Set command based on SHOW_SENSITIVE
COMMAND="/export $(if [[ "$SHOW_SENSITIVE" == false ]]; then echo "hide-sensitive"; else echo "show-sensitive"; fi)"

log "Using ssh key from ${MIKROTIK_KEY_PATH}"

for ROUTER in "${REACHABLE_ROUTERS[@]}"; do
    log "Backing up ${ROUTER} to ${ROUTER}.rsc..."
    ssh -i "$MIKROTIK_KEY_PATH" "${MIKROTIK_SSH_USER}@${ROUTER}" "$COMMAND" | sed '1d' > "${ROUTER}.rsc"
    upload_to_github "${ROUTER}.rsc"
done

log "Backup process completed."
