#!/usr/bin/env bash
# expose-runtime-utils.sh — Runtime Utility Exposure Layer
#
# Exposes GENERAL-PURPOSE runtime utilities from the `bio` conda env as normal
# login-shell commands, by symlinking them into ~/.local/bin (already on PATH via
# the stock ~/.bashrc). `bio` remains the SINGLE SOURCE OF TRUTH — these are
# symlinks, not copies; the env (and its pins in infra/bio-environment.yml) is the
# only place the tools are installed.
#
# Bioinformatics / scientific software is DELIBERATELY NOT exposed here — it stays
# environment-controlled (`conda activate bio`) and container-first.
# See: infra/RUNTIME_TOOLS.md, infra/RUNTIME_FOUNDATION.md.
#
# Idempotent. Run per-node (home is local per-node): bash expose-runtime-utils.sh
# Rollback:  bash expose-runtime-utils.sh --remove

set -euo pipefail

BIO_BIN="/data/local/runtime/miniforge3/envs/bio/bin"
DEST="${HOME}/.local/bin"

# Allow-list: general-purpose operator utilities ONLY.
EXPOSE=(bat eza fd rg fzf btop jq yq tree pv parallel)

# Deny-list: scientific tools that MUST NOT be globally exposed (here for
# documentation / safety — the script only ever links the allow-list).
DENY=(samtools bcftools bedtools seqkit csvtk)

mode="${1:-install}"
mkdir -p "$DEST"

if [[ "$mode" == "--remove" ]]; then
  for t in "${EXPOSE[@]}"; do
    link="$DEST/$t"
    if [[ -L "$link" && "$(readlink "$link")" == "$BIO_BIN/$t" ]]; then
      rm -f "$link"; echo "removed  $link"
    fi
  done
  echo "Runtime Utility Exposure Layer removed on $(hostname -s)."
  exit 0
fi

echo "Exposing runtime utilities on $(hostname -s) -> $DEST"
missing=0
for t in "${EXPOSE[@]}"; do
  src="$BIO_BIN/$t"
  if [[ ! -e "$src" ]]; then
    echo "  WARN: $t not found in bio env ($src) — skipped"; missing=1; continue
  fi
  ln -sfn "$src" "$DEST/$t"
  echo "  linked $t -> $src"
done

# Safety: ensure no deny-listed tool was ever exposed by this layer.
for t in "${DENY[@]}"; do
  link="$DEST/$t"
  if [[ -L "$link" && "$(readlink "$link")" == "$BIO_BIN/"* ]]; then
    echo "  REMOVING disallowed exposure: $link"; rm -f "$link"
  fi
done

echo "Done ($([ $missing -eq 0 ] && echo 'all present' || echo 'some missing — see warnings'))."
