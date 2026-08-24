#!/data/data/com.termux/files/usr/bin/bash

# ─────────────────────────────────────────
#  BRIDGE CLIENT v2.0 - Termux Side
#  Claude → GitHub → Termux
# ─────────────────────────────────────────

TOKEN=$(cat ~/.bridge_token)
USER="bintangmulya340-rgb"
REPO="raw"
API="https://api.github.com/repos/$USER/$REPO/contents/bridge"
LAST_CMD_ID=""

log() { echo "[$(date '+%H:%M:%S')] $1"; }

gh_read() {
  curl -s -H "Authorization: Bearer $TOKEN" \
    -H "Cache-Control: no-cache" \
    "$API/$1" | python3 -c "
import sys,json,base64
try:
  r=json.load(sys.stdin)
  print(base64.b64decode(r[\"content\"]).decode().strip())
except:
  print(\"ERROR\")
"
}

gh_write() {
  local FILE=$1
  local CONTENT=$2
  local MSG=$3
  SHA=$(curl -s -H "Authorization: Bearer $TOKEN" \
    "$API/$FILE" | python3 -c "import sys,json; print(json.load(sys.stdin).get(\"sha\",\"\"))" 2>/dev/null)
  ENCODED=$(printf "%s" "$CONTENT" | base64 | tr -d "\n")
  if [ -n "$SHA" ]; then
    curl -s -X PUT "$API/$FILE" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"message\":\"$MSG\",\"sha\":\"$SHA\",\"content\":\"$ENCODED\"}" > /dev/null
  else
    curl -s -X PUT "$API/$FILE" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"message\":\"$MSG\",\"content\":\"$ENCODED\"}" > /dev/null
  fi
}

log "Bridge v2.0 started"
gh_write "status.txt" "ONLINE|$(date '+%Y-%m-%d %H:%M:%S')|$(whoami)@$(hostname)" "bridge: online"
log "ONLINE dikirim ke GitHub"

while true; do
  RAW=$(gh_read "cmd.txt")
  CMD_ID=$(echo "$RAW" | cut -d'|' -f1)
  CMD=$(echo "$RAW" | cut -d'|' -f2-)

  if [ "$CMD_ID" != "$LAST_CMD_ID" ] && [ "$CMD_ID" != "READY" ] && [ -n "$CMD_ID" ] && [ "$CMD_ID" != "ERROR" ]; then
    log "CMD [$CMD_ID]: $CMD"
    LAST_CMD_ID="$CMD_ID"

    gh_write "status.txt" "ACK|$CMD_ID|$(date '+%H:%M:%S')" "ack: $CMD_ID"
    log "ACK terkirim"

    START=$(date +%s)
    OUTPUT=$(eval "$CMD" 2>&1)
    END=$(date +%s)
    ELAPSED=$((END-START))

    RESULT="DONE|$CMD_ID|${ELAPSED}s|$(date '+%H:%M:%S')
$OUTPUT"
    gh_write "status.txt" "$RESULT" "output: $CMD_ID"
    log "Output uploaded (${ELAPSED}s)"
  fi

  sleep 5
done