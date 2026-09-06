#!/bin/sh
# Build picolibc ONCE for the MOS architecture.
#
# The output (libc.a, libm.a, arch-specific startup fragments, headers)
# is shared across every machine picomos supports; only linker scripts,
# crt0, and machine-specific I/O vary per machine (see build-machine.sh).
#
# Usage: build-picolibc.sh [<picolibc-src>]
#
# Outputs (relative to picomos root):
#   dist/picolibc/include/...
#   dist/picolibc/lib/libc.a
#   dist/picolibc/lib/libm.a           (if configured)
#   dist/picolibc/lib/crt0-generic.o   (no machine assumptions — machines
#                                       supply their own crt0 objects)
#
# Not yet implemented; placeholder sketch.

set -eu

PICOLIBC_SRC=${1:-$HOME/git/picolibc}
PICOMOS_ROOT=$(cd "$(dirname "$0")/.." && pwd)

BUILD_DIR="$PICOMOS_ROOT/build/picolibc"
DIST_DIR="$PICOMOS_ROOT/dist/picolibc"

echo "TODO: generate a MOS-architecture cross file (no machine specifics):"
echo "  - libgcc from llvm-mos"
echo "  - ram_only=true (MOS has no distinct flash region)"
echo "  - allowed_tests=[] (no tests baked in — SDK doesn't ship the test suite)"
echo "  - NO extra_memory / extra_sections / linker_preamble"
echo "    (those are machine-level; machines provide them at final link)"
echo ""
echo "TODO: rm -rf $BUILD_DIR && mkdir -p $BUILD_DIR"
echo "TODO: meson setup --cross-file <generic-mos-cross> \\"
echo "        -Dtests=false -Dmultilib=false \\"
echo "        $BUILD_DIR $PICOLIBC_SRC"
echo "TODO: ninja -C $BUILD_DIR"
echo "TODO: DESTDIR=$DIST_DIR meson install -C $BUILD_DIR --no-rebuild"
