#!/bin/sh
# Launch a picomos-built C64 program under MAME's c64 driver.
#
# Usage: run.sh <prg-path> [seconds_to_run]
#
# The PRG is delivered via MAME's `-quik` (quickload) media slot, which
# LOADs the file into RAM at the address in the first two bytes and
# runs it. The C64 needs a human-visible pause for the KERNAL power-on
# banner + BASIC READY prompt before the quickload finishes; that pause
# is baked into MAME's c64 driver behaviour.

set -eu

PRG=${1:?usage: run.sh <prg-path> [seconds]}
SECS=${2:-10}

MAME=${MAME:-mame}

exec "$MAME" c64 \
    -window \
    -skip_gameinfo \
    -quik "$PRG" \
    -seconds_to_run "$SECS"
