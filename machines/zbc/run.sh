#!/bin/sh
# Launch a picolibc-linked ELF under the ZBC MAME driver.
# Usage: run.sh <elf-path> [seconds_to_run]

set -eu

ELF=${1:?usage: run.sh <elf-path> [seconds]}
SECS=${2:-5}

MAME=${MAME:-mame}

exec "$MAME" zbcm6502 \
    -window \
    -skip_gameinfo \
    -elfload "$ELF" \
    -seconds_to_run "$SECS"
