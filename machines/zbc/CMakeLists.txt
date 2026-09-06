# Machine overlay for ZBC (MAME zbcm6502).
#
# picolibc (our fork) already ships the semihost transport (libsemihost.a
# includes ZBC RIFF client) and a matching picocrt (libcrt0-semihost-zbc.a
# supplies _start / __do_init_stack). The overlay's only job here is the
# linker script: memory.ld overrides picolibc's placeholder __flash/__ram
# with the ZBC memory map; sections.ld GROUP()s the picolibc crt0 archive
# and INCLUDEs picolibc's noflash SECTIONS layout.

include(${CMAKE_SOURCE_DIR}/cmake/PicomosMachine.cmake)

picomos_machine(zbc
    LINKER_PARTS
        linker/memory.ld
        linker/sections.ld
)
