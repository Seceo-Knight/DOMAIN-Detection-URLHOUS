#!/bin/bash

set -euo pipefail

FEED="https://urlhaus.abuse.ch/downloads/text/"
BASE="/var/ossec/etc/lists/urlhaus"
OUT="$BASE/urlhaus_blacklist"
WHITELIST="$BASE/whitelist.txt"
LOG="$BASE/update.log"
BACKUP_DIR="$BASE/backups"
OUT_NEW="$BASE/urlhaus_blacklist.new"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG"
}

cleanup() {
    rm -f "$OUT_NEW" /tmp/urlhaus_*.txt
}
trap cleanup EXIT

log "========== URLhaus Update Started =========="

mkdir -p "$BACKUP_DIR"

# Download with retry
MAX_RETRIES=3
ATTEMPT=1

while [ $ATTEMPT -le $MAX_RETRIES ]; do
    if curl -s --max-time 30 --retry 2 "$FEED" > /tmp/urlhaus_raw.txt 2>> "$LOG"; then
        if [ -s /tmp/urlhaus_raw.txt ]; then
            log "✓ Downloaded $(wc -l < /tmp/urlhaus_raw.txt) lines"
            break
        fi
    fi
    ATTEMPT=$((ATTEMPT + 1))
    [ $ATTEMPT -le $MAX_RETRIES ] && sleep 5
done

if [ $ATTEMPT -gt $MAX_RETRIES ]; then
    log "ERROR: Download failed"
    exit 1
fi

# Extract domains from URLs - UNIQUE ONLY
grep -E '^https?://' /tmp/urlhaus_raw.txt 2>/dev/null | \
    sed 's|^https*://||' | cut -d'/' -f1 | cut -d':' -f1 | \
    sed '/^$/d' | sort -u > /tmp/urlhaus_domains.txt

DOMAIN_COUNT=$(wc -l < /tmp/urlhaus_domains.txt)
log "Extracted $DOMAIN_COUNT unique domains"

# Extract IPs - UNIQUE ONLY
grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' /tmp/urlhaus_raw.txt 2>/dev/null | \
    sort -u > /tmp/urlhaus_ips.txt

IP_COUNT=$(wc -l < /tmp/urlhaus_ips.txt)
log "Extracted $IP_COUNT unique IPs"

# Create output file - NO DUPLICATES
> "$OUT_NEW"

# Filter domains - ONE ENTRY PER DOMAIN
FILTERED_DOMAINS=0
while IFS= read -r domain; do
    [ -z "$domain" ] && continue
    if grep -qxF "$domain:" "$WHITELIST" 2>/dev/null; then
        FILTERED_DOMAINS=$((FILTERED_DOMAINS + 1))
        continue
    fi
    # Add ONLY ONCE with standard description
    echo "$domain:urlhaus" >> "$OUT_NEW"
done < /tmp/urlhaus_domains.txt

# Filter IPs - ONE ENTRY PER IP
FILTERED_IPS=0
while IFS= read -r ip; do
    [ -z "$ip" ] && continue
    if grep -qxF "$ip:" "$WHITELIST" 2>/dev/null; then
        FILTERED_IPS=$((FILTERED_IPS + 1))
        continue
    fi
    # Add ONLY ONCE with standard description
    echo "$ip:urlhaus" >> "$OUT_NEW"
done < /tmp/urlhaus_ips.txt

log "Filtered: $FILTERED_DOMAINS domains, $FILTERED_IPS IPs (whitelisted)"

# Final deduplication (in case of any overlaps)
BEFORE=$(wc -l < "$OUT_NEW")
sort -u "$OUT_NEW" -o "$OUT_NEW"
AFTER=$(wc -l < "$OUT_NEW")

log "Final: $BEFORE lines → $AFTER unique entries (removed $((BEFORE - AFTER)) duplicates)"

# Safety check
if [ $AFTER -lt 100 ]; then
    log "ERROR: Output too small ($AFTER entries)"
    exit 1
fi

# Backup and deploy
if [ -f "$OUT" ]; then
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    cp "$OUT" "$BACKUP_DIR/urlhaus_blacklist.$TIMESTAMP"
    log "Backed up previous list"
fi

mv "$OUT_NEW" "$OUT"
chown wazuh:wazuh "$OUT"
chmod 640 "$OUT"

log "✓ Deployed: $AFTER unique entries (NO DUPLICATES)"

# Clean old backups (30-day window)
DELETED=$(find "$BACKUP_DIR" -name "urlhaus_blacklist.*" -mtime +30 -delete -print | wc -l)
log "Cleaned: Deleted $DELETED old backups"

KEPT=$(ls "$BACKUP_DIR"/urlhaus_blacklist.* 2>/dev/null | wc -l)
log "Kept: $KEPT backups in 30-day window"

log "========== Update Complete =========="
