# Abstract base for Commodore 8-bit machines (c64, vic20, plus/4, c128,
# ...). Ships the pieces every CBM machine reuses verbatim:
#
#   crt/basic_header.S       BASIC one-line "SYS <_start>" launcher.
#                            The SYS-target address is resolved at link
#                            time via .mos_addr_asciz, so the same file
#                            works on any CBM machine — the linker
#                            script's placement of .basic_header at
#                            $0801 (c64), $1001 (vic20), etc. is what
#                            differs, not the header source.
#
#   io/chrout.S              KERNAL CHROUT wrapper (jsr $FFD2).
#   io/chrin.S               KERNAL GETIN wrapper (jsr $FFE4).
#   io/stdio_hook.c          picolibc FILE * hook that routes putc/getc
#                            through CHROUT/GETIN plus the standard
#                            PETSCII \n <-> \r translation.
#
#   runner-mame.lua          MAME plugin: auto-types RUN into the KERNAL
#                            keyboard buffer at $0277 (all CBMs share
#                            this ring-buffer address) and mirrors CHROUT
#                            output to stdout for CTest matching.
#
# Concrete descendants (c64, future vic20, ...) contribute:
#   - linker/memory.ld       machine-specific memory map.
#   - linker/sections.ld     machine-specific section layout.
#   - machine.cmake          picomos_machine(<name> INHERITS cbm ...) +
#                            picomos_emulator(<name> mame ...) declarations.
#   - runner-mame.lua        OPTIONAL — override if the machine needs a
#                            different auto-RUN sequence or tap.

picomos_machine(cbm
    ABSTRACT
    CPU        6502
    ENDIANNESS little
)
