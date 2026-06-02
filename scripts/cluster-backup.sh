#!/usr/bin/env bash
# cluster-backup.sh — on-cluster backup of precious data + encrypted secrets.
# Pushes from gpu-01 (NFS server / control) to peer backup areas on INDEPENDENT
# disks (gpu-02, gpu-03). Mitigates single-disk loss (R1) — NOT off-site.
# See BACKUP_AND_RECOVERY.md. Run by systemd timer (daily) as user hha.
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"

SRC=/srv/nfs/resources
PEERS=(gpu-02 gpu-03)
TS=$(date -u +%Y%m%dT%H%M%SZ)
LOG="$HOME/cluster-backup.log"
AGE_RECIP=$(cat "$HOME/.secrets/age/recipient.txt")
KEEP=7   # encrypted-secrets archives to retain per peer

log(){ echo "[$(date -u +%FT%TZ)] $*" | tee -a "$LOG" ; }

log "=== backup run $TS START ==="

# 1) Precious data: mirror NFS resources to each peer + SHA256 manifest
MANIFEST=$(mktemp)
( cd "$SRC" && find . -type f -exec sha256sum {} \; ) > "$MANIFEST" 2>/dev/null || true
for h in "${PEERS[@]}"; do
  rsync -a --delete --rsync-path="rsync" "$SRC"/ "$h":/srv/backup/resources/ \
    && log "data -> $h OK ($(wc -l < "$MANIFEST") files)" || log "data -> $h FAILED"
  # manifest kept as a SIBLING (outside the mirror) so restore never pollutes live data
  scp -q "$MANIFEST" "$h":/srv/backup/resources.manifest.sha256 || true
done
rm -f "$MANIFEST"

# 2) Secrets: tar (excluding the age identity itself) -> age-encrypt -> peers
SECTAR=$(mktemp --suffix=.tar.gz)
tar czf "$SECTAR" -C "$HOME" \
    --exclude='.secrets/age/identity.txt' \
    .secrets .ssh/cluster_ed25519 .ssh/hay2k-infra_ed25519 2>/dev/null || true
ENC=$(mktemp --suffix=.age)
age -r "$AGE_RECIP" -o "$ENC" "$SECTAR"
for h in "${PEERS[@]}"; do
  scp -q "$ENC" "$h":/srv/backup/secrets/secrets-"$TS".tar.gz.age \
    && log "secrets -> $h OK ($(stat -c%s "$ENC") bytes, age-encrypted)" || log "secrets -> $h FAILED"
  # rotation: keep newest $KEEP
  ssh "$h" "ls -1t /srv/backup/secrets/secrets-*.tar.gz.age 2>/dev/null | tail -n +$((KEEP+1)) | xargs -r rm -f"
done
rm -f "$SECTAR" "$ENC"

log "=== backup run $TS DONE ==="
