#!/data/data/com.termux/files/usr/bin/bash
# Baca token dari file lokal
TOKEN=$(cat ~/.bridge_token)
USER="bintangmulya340-rgb"
REPO="raw"
LAST_CMD="READY"

echo "[*] Bridge started..."

while true; do
  CMD=$(curl -s "https://raw.githubusercontent.com/$USER/$REPO/main/bridge/cmd.txt?$(date +%s)")

  if [ "$CMD" != "$LAST_CMD" ] && [ "$CMD" != "READY" ]; then
    echo "[+] CMD: $CMD"
    OUTPUT=$(eval "$CMD" 2>&1)
    LAST_CMD="$CMD"

    SHA=$(curl -s -H "Authorization: Bearer $TOKEN" \
      "https://api.github.com/repos/$USER/$REPO/contents/bridge/status.txt" \
      | python3 -c "import sys,json; print(json.load(sys.stdin)[\"sha\"])")

    CONTENT=$(printf "%s" "$OUTPUT" | base64 | tr -d "\n")
    curl -s -X PUT "https://api.github.com/repos/$USER/$REPO/contents/bridge/status.txt" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"message\":\"output\",\"sha\":\"$SHA\",\"content\":\"$CONTENT\"}" > /dev/null

    echo "[+] Output uploaded"
  fi

  sleep 5
done