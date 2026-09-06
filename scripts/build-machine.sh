#!/bin/sh
# Build the per-machine overlay: crt0.o, machine-specific I/O objects,
# and the assembled linker script. Consumes the shared picolibc under
# dist/picolibc/ produced by build-picolibc.sh.
#
# Usage: build-machine.sh <machine>
#
# Outputs:
#   dist/machines/<machine>/crt0.o
#   dist/machines/<machine>/io.a           (optional, if machine has io/)
#   dist/machines/<machine>/link.ld        (assembled from linker/*.ld)
#
# Not yet implemented; placeholder sketch.

set -eu

MACHINE=${1:?usage: build-machine.sh <machine>}
PICOMOS_ROOT=$(cd "$(dirname "$0")/.." && pwd)

MACHINE_DIR="$PICOMOS_ROOT/machines/$MACHINE"
[ -d "$MACHINE_DIR" ] || { echo "no such machine: $MACHINE"; exit 1; }

PICOLIBC_DIST="$PICOMOS_ROOT/dist/picolibc"
[ -d "$PICOLIBC_DIST" ] || { echo "run build-picolibc.sh first"; exit 1; }

DIST_DIR="$PICOMOS_ROOT/dist/machines/$MACHINE"

echo "TODO: compile $MACHINE_DIR/crt/*.[Sc] -> $DIST_DIR/crt0.o"
echo "TODO: compile $MACHINE_DIR/io/*.c -> $DIST_DIR/io.a (if present)"
echo "TODO: assemble $MACHINE_DIR/linker/*.ld -> $DIST_DIR/link.ld"
