#!/usr/bin/env bash
# analysis-env.sh — container cache locations for the research domain.
# Punch-list items N1 (engine cache) + N5 (build cache), M2-0 (20260605-03).
#
# STATUS: NOT yet wired into the live shell. The NXF cache path lives under
# analysis/ (shared NFS), which is deployed in M2-1. Source this from your profile
# (or have the version-management tooling source it) ONCE M2-1 has created
# /home/hha/analysis. Until then it is documentation-as-code.
#
# Reversible: remove this file / the source line; unset the two vars.

# --- Apptainer BUILD cache (N5): LOCAL, regenerable, never on NFS, backup-excluded.
# Build SIFs locally then move the verified artifact onto NFS (N3).
export APPTAINER_CACHEDIR="${APPTAINER_CACHEDIR:-$HOME/.cache/apptainer}"

# --- Workflow-engine (Nextflow/nf-core) container cache (N1): inside the governed
# store so engine-pulled images stay managed. Pinned by pipeline revision.
export NXF_SINGULARITY_CACHEDIR="${NXF_SINGULARITY_CACHEDIR:-/home/hha/analysis/container/apptainer/_engine-cache}"

# Cleanup helper (run after builds; build cache is regenerable):
#   apptainer cache clean --force   # or: rm -rf "$APPTAINER_CACHEDIR"/*
