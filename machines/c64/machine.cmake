# Commodore 64. Inherits the shared CBM base (basic_header.S, chrout.S,
# chrin.S, stdio_hook.c, runner-mame.lua); this file only contributes
# the c64-specific linker script and emulator declarations.

picomos_machine(c64
    INHERITS     cbm
    DISPLAY_NAME "Commodore 64 (MAME c64)"
    MEMORY_MAP   "0x0800 stack/system, 0x0801-0x9FFF free RAM (BASIC \
area), BASIC ROM 0xA000-0xBFFF, KERNAL 0xE000-0xFFFF, I/O at \
0xD000-0xDFFF"
)

# MAME's c64 driver. Loads PRGs via -quik (BASIC-compatible), needs
# Commodore's original BASIC/KERNAL/character ROMs in the MAME romset.
# The bundled runner-mame.lua (inherited from cbm/) pokes RUN into the
# KERNAL keyboard buffer and mirrors CHROUT output for CTest.
picomos_emulator(c64 mame
    DEFAULT
    EXECUTABLE     mame
    ENV_OVERRIDE   PICOMOS_MAME
    PLUGIN_SCRIPT  runner-mame.lua
    OUTPUT_EXT     .prg
    REQUIRES_ROMS
    NOTES          "Needs Commodore's BASIC/KERNAL/character ROMs in \
your MAME romset."
    ARGS
        c64
        -window
        -skip_gameinfo
        -quik              {PROGRAM}
        -plugins
        -autoboot_script   {PLUGIN_SCRIPT}
        -seconds_to_run    {TIMEOUT}
)

# VICE runner sketched but not verified end-to-end.
picomos_emulator(c64 vice
    EXECUTABLE     x64sc
    ENV_OVERRIDE   PICOMOS_VICE
    OUTPUT_EXT     .prg
    NOTES          "Sketch runner; not verified end-to-end yet."
    ARGS
        -autostart          {PROGRAM}
        -warp
        -limitcycles        50000000
)
