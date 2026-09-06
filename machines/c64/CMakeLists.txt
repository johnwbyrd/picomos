# Machine overlay for the Commodore 64 (MAME c64 driver).
#
# picolibc supplies libc.a and the machine-agnostic minimal crt0
# (libcrt0-minimal.a — provides _start, __do_init_stack, calls main and
# expects the linker script to provide __data_* / __bss_* symbols). Our
# overlay contributes:
#
#   linker/  MEMORY map + own SECTIONS (no INCLUDE of picolibc_noflash.ld:
#            the C64 emits a raw PRG image via OUTPUT_FORMAT { SHORT TRIM },
#            and we place a .basic_header section first).
#   crt/     BASIC "SYS <_start>" one-line loader that lets `MAME -quik`
#            (and a real C64) LOAD+RUN the PRG.
#   io/      chrout.S / chrin.S KERNAL wrappers + a picolibc stdio hook
#            (FDEV_SETUP_STREAM) that routes puts/getchar through CHROUT
#            ($FFD2) and GETIN ($FFE4).

include(${CMAKE_SOURCE_DIR}/cmake/PicomosMachine.cmake)

picomos_machine(c64
    CRT_SOURCES
        crt/basic_header.S
    IO_SOURCES
        io/chrout.S
        io/chrin.S
        io/stdio_hook.c
    LINKER_PARTS
        linker/memory.ld
        linker/sections.ld
)
