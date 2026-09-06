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
    LINK_LIBS
        # ZBC routes stdio through picolibc's semihost library: puts →
        # sys_write → libsemihost's ZBC RIFF client → MMIO device
        # at 0xFCE0. libsemihost also provides `exit` and the POSIX
        # stdout FILE that picolibc's crt0-semihost-zbc expects.
        -lsemihost
)
