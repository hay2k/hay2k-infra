#!/usr/bin/env bash
# test-analysis-install.sh — validates analysis-install against a THROWAWAY root.
# No real software/containers/references; pure dummy filesystem simulation.
# M3-1 (20260610-01).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
TOOL="$HERE/analysis-install"
export ANALYSIS_ROOT="$(mktemp -d /tmp/m3-1-analysis-test.XXXXXX)"
SRC="$(mktemp -d /tmp/m3-1-src.XXXXXX)"
pass=0; fail=0
ok()   { echo "  PASS: $1"; pass=$((pass+1)); }
no()   { echo "  FAIL: $1"; fail=$((fail+1)); }
run()  { "$TOOL" "$@"; }   # expect success
assert()      { if eval "$1"; then ok "$2"; else no "$2"; fi; }
assert_fail() { if "$@" >/dev/null 2>&1; then no "expected failure but succeeded: $*"; else ok "rejected (as expected): $*"; fi; }

echo "ANALYSIS_ROOT=$ANALYSIS_ROOT"
echo "=== dummy artifacts ==="
echo "dummy nextflow pipeline v1.0" > "$SRC/pipe10.txt"
echo "dummy nextflow pipeline v1.1" > "$SRC/pipe11.txt"
printf 'FAKE-SIF-BYTES-pytorch-2.9-cuda13\n' > "$SRC/pytorch.sif"
mkdir -p "$SRC/ref/fasta"; echo ">chrTest" > "$SRC/ref/fasta/genome.fa"; echo "ACGT" >> "$SRC/ref/fasta/genome.fa"

echo "=== [1] versioned install + [4] manifest + [5] sha256 + [6] logging + [2] current ==="
run install pipeline nextflow nf-core-dummy 1.0 --from "$SRC/pipe10.txt" --source "https://example/nf#1.0" --accel cpu --set-current
assert "[ -d '$ANALYSIS_ROOT/pipeline/nextflow/nf-core-dummy/1.0' ]" "[1] version dir created"
assert "[ -f '$ANALYSIS_ROOT/pipeline/nextflow/nf-core-dummy/1.0/MANIFEST.md' ]" "[4] manifest written"
assert "grep -q '^sha256: [0-9a-f]\{64\}' '$ANALYSIS_ROOT/pipeline/nextflow/nf-core-dummy/1.0/MANIFEST.md'" "[5] sha256 recorded"
assert "[ -f '$ANALYSIS_ROOT/.analysis-install.log' ]" "[6] central install log created"
assert "[ \"\$(readlink '$ANALYSIS_ROOT/pipeline/nextflow/nf-core-dummy/current')\" = '1.0' ]" "[2] current -> 1.0"

echo "=== [1b] never overwrite an existing version ==="
assert_fail "$TOOL" install pipeline nextflow nf-core-dummy 1.0 --from "$SRC/pipe10.txt"

echo "=== [3] atomic current switching ==="
run install pipeline nextflow nf-core-dummy 1.1 --from "$SRC/pipe11.txt" --accel cpu
run set-current pipeline nextflow nf-core-dummy 1.1
assert "[ -L '$ANALYSIS_ROOT/pipeline/nextflow/nf-core-dummy/current' ]" "[3] current is a symlink"
assert "[ \"\$(readlink '$ANALYSIS_ROOT/pipeline/nextflow/nf-core-dummy/current')\" = '1.1' ]" "[3] current -> 1.1 (switched)"

echo "=== [7] rollback current to previous ==="
run rollback-current pipeline nextflow nf-core-dummy
assert "[ \"\$(readlink '$ANALYSIS_ROOT/pipeline/nextflow/nf-core-dummy/current')\" = '1.0' ]" "[7] rolled back current -> 1.0"

echo "=== [10] container tracking + GPU-first policy (accel both -> preferred gpu) ==="
run install container apptainer pytorch 2.9-cuda13 --from "$SRC/pytorch.sif" --source "docker://nvcr.io/pytorch@sha256:dead" --accel both --set-current
assert "grep -q '^preferred: gpu' '$ANALYSIS_ROOT/container/apptainer/pytorch/2.9-cuda13/MANIFEST.md'" "[GPU-first] accel=both defaulted preferred=gpu"

echo "=== [11] reference tracking (dir payload) + .regenerable marker ==="
run install reference genomes grch38-dummy ensembl-110 --from "$SRC/ref" --regenerable --set-current
assert "[ -f '$ANALYSIS_ROOT/reference/genomes/grch38-dummy/ensembl-110/.regenerable' ]" "[backup] .regenerable marker dropped"

echo "=== [5b] verify SHA256 (recorded vs artifact) ==="
assert "$TOOL verify container apptainer pytorch 2.9-cuda13 | grep -q 'VERIFY OK'" "[5b] container verify OK"
assert "$TOOL verify reference genomes grch38-dummy ensembl-110 | grep -q 'VERIFY OK'" "[5b] reference (dir) verify OK"

echo "=== [5c] sha256 hard-stop on mismatch at install ==="
assert_fail "$TOOL" install container apptainer pytorch 9.9-bad --from "$SRC/pytorch.sif" --sha256 0000000000000000000000000000000000000000000000000000000000000000

echo "=== [5d] verify FAILS if artifact tampered ==="
echo "tampered" >> "$ANALYSIS_ROOT/container/apptainer/pytorch/2.9-cuda13/pytorch.sif"
assert_fail "$TOOL" verify container apptainer pytorch 2.9-cuda13
# restore so later steps are clean (re-derive not needed; tampered version will be left as-is)

echo "=== [8] project reproducibility: pin resolves current -> concrete version+sha ==="
$TOOL pin pipeline nextflow nf-core-dummy > "$SRC/pin.txt"
echo "    pin: $(cat "$SRC/pin.txt")"
assert "grep -q 'nextflow/nf-core-dummy/1.0' '$SRC/pin.txt'" "[8] pin resolved current to concrete version 1.0"
assert "grep -qi 'NEVER pin' '$SRC/pin.txt'" "[8] pin warns against pinning 'current'"

echo "=== [9/10/11] tracking via list ==="
echo "--- list output ---"; $TOOL list | sed 's/^/    /'
assert "$TOOL list | grep -q 'pipeline/nextflow/nf-core-dummy'" "[9] pipeline tracked"
assert "$TOOL list | grep -q 'container/apptainer/pytorch'" "[10] container tracked"
assert "$TOOL list | grep -q 'reference/genomes/grch38-dummy'" "[11] reference tracked"

echo "=== [7b] remove guards: refuse current, allow non-current ==="
assert_fail "$TOOL" remove pipeline nextflow nf-core-dummy 1.0   # 1.0 is current -> refuse
run remove pipeline nextflow nf-core-dummy 1.1
assert "[ ! -d '$ANALYSIS_ROOT/pipeline/nextflow/nf-core-dummy/1.1' ]" "[7b] non-current version removed"
assert "grep -q 'remove' '$ANALYSIS_ROOT/pipeline/nextflow/nf-core-dummy/VERSIONS.md'" "[7b] removal logged in VERSIONS.md"

echo "=== install log (capability 6) tail ==="; sed 's/^/    /' "$ANALYSIS_ROOT/.analysis-install.log"

echo
echo "RESULTS: $pass passed, $fail failed"
echo "=== cleanup throwaway dirs ==="
rm -rf "$ANALYSIS_ROOT" "$SRC"
echo "  removed $ANALYSIS_ROOT and $SRC"
[ "$fail" -eq 0 ]
