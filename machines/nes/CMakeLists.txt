# Machine overlay for the Nintendo Entertainment System (MAME nes driver).
#
# Fixed configuration for this first cut:
#   - Mapper: 0 (NROM)
#   - PRG-ROM: 16 KiB, mirrored to $8000 and $C000 (NROM-128)
#   - CHR-RAM: 8 KiB
#   - Mirroring: horizontal
#
# picolibc gives us libc, libcrt0-minimal, memcpy/memset, and the
# TinyStdio machinery. We contribute an NES-specific reset routine
# (crt/startup.S), a $401B side-channel __putchar (io/putchar.c) plus
# the FILE * stdout/stderr/stdin hookup (io/stdio_hook.c), and the
# linker script bits that emit an iNES 2.0 header + the fixed
# NROM memory map.
#
# The runner + test hook use a MAME memory write-tap at $401B; see
# runner-mame.lua for details.

include(${CMAKE_SOURCE_DIR}/cmake/PicomosMachine.cmake)

picomos_machine(nes
    CRT_SOURCES
        crt/startup.S
    IO_SOURCES
        io/putchar.c
        io/stdio_hook.c
    LINKER_PARTS
        linker/memory.ld
        linker/sections.ld
)
