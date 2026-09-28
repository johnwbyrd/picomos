# ZBC — the reference/testing machine used by picolibc's MOS port.
# Runs under MAME's zbcm6502 driver. Semihost device at $FCE0.
#
# No crt or io sources: picolibc's own crt0 + semihost stdio backend
# is enough, since zbcm6502's semihost device speaks the picolibc
# semihost protocol directly. Only a linker script (memory.ld +
# sections.ld) and the mame emulator declaration below.

picomos_machine(zbc
    DISPLAY_NAME "ZBC (MAME zbcm6502)"
    CPU          6502
    ENDIANNESS   little
    MEMORY_MAP   "63 KB RAM at 0x0000-0xFCDF, semihost device \
0xFCE0-0xFCFF, vectors at 0xFFFA"
    LINK_LIBS
        # ZBC routes stdio through picolibc's semihost library: puts ->
        # sys_write -> libsemihost's ZBC RIFF client -> MMIO device at
        # 0xFCE0. libsemihost also provides _exit and the POSIX stdout
        # FILE that picolibc's crt0-semihost-zbc expects.
        -lsemihost
)

# MAME's zbcm6502 driver. No external ROMs required. Loads programs
# via -elfload (ELF, not raw). Semihost writes route to host stdout,
# so no plugin script is needed for CTest — CTest just matches on
# MAME's own stdout stream.
picomos_emulator(zbc mame
    DEFAULT
    EXECUTABLE     mame
    ENV_OVERRIDE   PICOMOS_MAME
    OUTPUT_EXT     .elf
    NOTES          "No external ROMs required; the zbcm6502 driver is a \
bare-metal 6502 with a MMIO semihost device at 0xFCE0."
    ARGS
        zbcm6502
        -window
        -skip_gameinfo
        -elfload         {PROGRAM}
        -seconds_to_run  {TIMEOUT}
)
