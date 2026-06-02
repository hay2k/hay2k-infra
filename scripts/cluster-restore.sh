#!/usr/bin/env bash
# cluster-restore.sh — restore precious data / secrets from a peer backup.
# Usage:
#   cluster-restore.sh data   [gpu-02|gpu-03]      # restore /srv/nfs/resources
#   cluster-restore.sh secrets [gpu-02|gpu-03] [archive]  # decrypt latest (or named) secrets
# Requires the age identity at ~/.secrets/age/identity.txt (keep a copy OFF-SITE).
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"
MODE=${1:?mode: data|secrets}; SRCH=${2:-gpu-02}

case "$MODE" in
  data)
    echo "Restoring /srv/nfs/resources from $SRCH:/srv/backup/resources ..."
    rsync -a --delete "$SRCH":/srv/backup/resources/ /srv/nfs/resources/
    echo "verifying against manifest:"
    scp -q "$SRCH":/srv/backup/resources.manifest.sha256 /tmp/.m.$$ 2>/dev/null || true
    ( cd /srv/nfs/resources && sha256sum -c /tmp/.m.$$ 2>/dev/null | tail -3 ) || echo "(no manifest / empty)"
    rm -f /tmp/.m.$$ ;;
  secrets)
    ARCH=${3:-$(ssh "$SRCH" 'ls -1t /srv/backup/secrets/secrets-*.tar.gz.age 2>/dev/null | head -1')}
    echo "Decrypting $SRCH:$ARCH to /tmp/secrets-restore.$$ ..."
    mkdir -p /tmp/secrets-restore.$$ && chmod 700 /tmp/secrets-restore.$$
    ssh "$SRCH" "cat $ARCH" | age -d -i "$HOME/.secrets/age/identity.txt" | tar xzf - -C /tmp/secrets-restore.$$
    echo "restored secrets tree to /tmp/secrets-restore.$$ (review, then place manually):"
    find /tmp/secrets-restore.$$ -type f ;;
  *) echo "unknown mode"; exit 1 ;;
esac
