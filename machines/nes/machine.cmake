# Nintendo Entertainment System (NROM-128).
#
# Fixed configuration for this first cut:
#   - Mapper: 0 (NROM)
#   - PRG-ROM: 16 KiB, mirrored to $8000 and $C000 (NROM-128)
#   - CHR-RAM: 8 KiB
#   - Mirroring: horizontal
#
# picolibc gives us libc, libcrt0-minimal, memcpy/memset, and the
# TinyStdio machinery. This overlay contributes an NES-specific reset
# routine (crt/startup.S), a $401B side-channel __putchar (io/putchar.c)
# plus the FILE * stdout/stderr/stdin hookup (io/stdio_hook.c), and the
# linker script bits that emit an iNES 2.0 header + NROM memory map.

picomos_machine(nes
    DISPLAY_NAME "NES (MAME nes)"
    CPU          6502
    ENDIANNESS   little
    MEMORY_MAP   "2 KB internal RAM $0000-$07FF, PPU regs $2000-$2007, \
APU/IO $4000-$4017, PRG-ROM $C000-$FFFF (16 KB, NROM-128), 8 KB CHR-RAM"
)

# MAME's nes driver. Standalone (no BIOS ROMs). Loads via -cart. The
# bundled runner-mame.lua taps writes at $401B (our __putchar target)
# and mirrors each byte to the emulator subprocess's stdout.
picomos_emulator(nes mame
    DEFAULT
    EXECUTABLE     mame
    ENV_OVERRIDE   PICOMOS_MAME
    PLUGIN_SCRIPT  runner-mame.lua
    OUTPUT_EXT     .nes
    NOTES          "MAME's nes driver runs standalone (no BIOS ROM \
needed for standard NROM cartridges). Loads .nes iNES 2.0 images via \
-cart."
    ARGS
        nes
        -window
        -skip_gameinfo
        -cart              {PROGRAM}
        -plugins
        -autoboot_script   {PLUGIN_SCRIPT}
        -seconds_to_run    {TIMEOUT}
)
