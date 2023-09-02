#!/bin/bash
set -e

[[ -z "$GITHUB_TOKEN" ]] && { echo "Error: GITHUB_TOKEN is not set."; exit 1; }
[[ -z "$ROUTERS" ]] && { echo "Error: ROUTERS is not set."; exit 1; }

REACHABLE_ROUTERS=""

for ROUTER in $ROUTERS; do
  ping -c 1 -W 2 "$ROUTER" > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    REACHABLE_ROUTERS="$REACHABLE_ROUTERS $ROUTER"
  else
    echo "Warning: ${ROUTER} is not responding to ping. Skipping."
  fi
done

REACHABLE_ROUTERS=$(echo "$REACHABLE_ROUTERS" | sed -e 's/^ *//')

[[ -z "$REACHABLE_ROUTERS" ]] && { echo "Error: No reachable routers."; exit 1; }

MIKROTIK_KEY_PATH=${MIKROTIK_KEY_PATH:-~/.ssh/id_rsa}
SHOW_SENSITIVE=${SHOW_SENSITIVE:-false}
COMMAND='/export'
if [ "$SHOW_SENSITIVE" = false ]; then
  COMMAND="$COMMAND hide-sensitive"
else
  COMMAND="$COMMAND show-sensitive"
fi

echo "Using ssh key from ${MIKROTIK_KEY_PATH}"

for ROUTER in $REACHABLE_ROUTERS; do
  echo "Backing up ${ROUTER} to ${ROUTER}.rsc..."
  ssh -i "$MIKROTIK_KEY_PATH" "$MIKROTIK_SSH_USER"@"$ROUTER" "$COMMAND" > ${ROUTER}.rsc
  sed -i '1d' ${ROUTER}.rsc

  FILE="$ROUTER".rsc
  CONTENT=$(base64 -i "$FILE")
  TIMESTAMP=$(date +"%Y-%m-%d %T")
  JSON_FMT='{
    "message": "Backup: %s",
    "committer": {
      "name": "%s",
      "email": "%s"
    },
    "content": "%s",
    "sha": "%s"
  }'

  SHA=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/repos/$GITHUB_REPO/contents/$FILE" | jq -r '.sha')

  NEW_SHA=$(git hash-object "$FILE")

  if [ "$NEW_SHA" != "$SHA" ]; then
    JSON=$(printf "$JSON_FMT" "$TIMESTAMP" "$GITHUB_USER" "$GITHUB_EMAIL" "$CONTENT" "$SHA")
    echo "$JSON" > json_payload.txt
    curl -X PUT -H "Authorization: token $GITHUB_TOKEN" -d @json_payload.txt "https://api.github.com/repos/$GITHUB_REPO/contents/$FILE"
    rm json_payload.txt
  fi
done
