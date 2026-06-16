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
LOG="/data/admin/logs/cluster-backup.log"
AGE_RECIP=$(cat "$HOME/.secrets/age/recipient.txt")
KEEP=7   # encrypted-secrets archives to retain per peer

log(){ echo "[$(date -u +%FT%TZ)] $*" | tee -a "$LOG" ; }

log "=== backup run $TS START ==="

# F4: keep all transient files (incl. the brief plaintext secrets tar) in a
# private 0700 dir under $HOME — NEVER in world-readable /tmp.
umask 077
mkdir -p "$HOME/.cache"
WORK=$(mktemp -d "$HOME/.cache/clbk.XXXXXX")
trap 'rm -rf "$WORK"' EXIT
chmod 700 "$WORK"

# 1) Precious data: mirror NFS resources to each peer + SHA256 manifest
MANIFEST="$WORK/manifest.sha256"
( cd "$SRC" && find . -type f -exec sha256sum {} \; ) > "$MANIFEST" 2>/dev/null || true
for h in "${PEERS[@]}"; do
  rsync -a --delete --rsync-path="rsync" "$SRC"/ "$h":/srv/backup/resources/ \
    && log "data -> $h OK ($(wc -l < "$MANIFEST") files)" || log "data -> $h FAILED"
  # manifest kept as a SIBLING (outside the mirror) so restore never pollutes live data
  scp -q "$MANIFEST" "$h":/srv/backup/resources.manifest.sha256 || true
done

# 2) Secrets: tar (excluding the age identity itself) -> age-encrypt -> peers.
# Plaintext tar lives only in the 0700 $WORK dir and is removed on EXIT (trap).
SECTAR="$WORK/secrets.tar.gz"
tar czf "$SECTAR" -C "$HOME" \
    --exclude='.secrets/age/identity.txt' \
    .secrets .ssh/cluster_ed25519 .ssh/hay2k-infra_ed25519 2>/dev/null || true
ENC="$WORK/secrets.tar.gz.age"
age -r "$AGE_RECIP" -o "$ENC" "$SECTAR"
shred -u "$SECTAR" 2>/dev/null || rm -f "$SECTAR"   # remove plaintext promptly
for h in "${PEERS[@]}"; do
  scp -q "$ENC" "$h":/srv/backup/secrets/secrets-"$TS".tar.gz.age \
    && log "secrets -> $h OK ($(stat -c%s "$ENC") bytes, age-encrypted)" || log "secrets -> $h FAILED"
  # rotation: keep newest $KEEP
  ssh "$h" "ls -1t /srv/backup/secrets/secrets-*.tar.gz.age 2>/dev/null | tail -n +$((KEEP+1)) | xargs -r rm -f"
done

# 3) Research domain (analysis): precious code/spec/manifests/pins. EXCLUDE
# regenerables — container SIFs (rebuildable from pinned digest), engine cache,
# and large reference data (re-downloadable; manifests/checksums are kept).
ASRC=/data/analysis
if [ -d "$ASRC" ]; then
  AMAN="$WORK/analysis.manifest.sha256"
  # hash only the precious/backed-up set (skip bulk regenerables: SIFs, indexes,
  # models, genome/transcript FASTAs, GTFs, VCFs) so we don't checksum tens of GB.
  ( cd "$ASRC" && find . -type f \
      ! -name '*.sif' ! -path './reference/index/*' ! -path './reference/model/*' \
      ! -name '*.gz' ! -name '*.tbi' \
      -exec sha256sum {} \; ) > "$AMAN" 2>/dev/null || true
  for h in "${PEERS[@]}"; do
    # --delete-excluded so the backup mirrors ONLY the precious set (purges
    # regenerables, incl. any previously-copied bulk, from the destination).
    rsync -a --delete --delete-excluded \
      --exclude='container/apptainer/**/*.sif' \
      --exclude='**/_engine-cache/**' \
      --exclude='reference/index/**' --exclude='reference/model/**' \
      --exclude='reference/**/*.gz' --exclude='reference/**/*.tbi' \
      "$ASRC"/ "$h":/srv/backup/analysis/ \
      && log "analysis -> $h OK ($(wc -l < "$AMAN") precious files; SIFs/indexes/models/refdata excluded)" || log "analysis -> $h FAILED"
    scp -q "$AMAN" "$h":/srv/backup/analysis.manifest.sha256 || true
  done
fi

# 4) Admin (handoff archives + logs): precious project record.
if [ -d /data/admin ]; then
  for h in "${PEERS[@]}"; do
    rsync -a --delete /data/admin/ "$h":/srv/backup/admin/ \
      && log "admin -> $h OK" || log "admin -> $h FAILED"
  done
fi

log "=== backup run $TS DONE ==="
