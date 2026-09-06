# Machine overlay for ZBC (MAME zbcm6502).

include(${CMAKE_SOURCE_DIR}/cmake/PicomosMachine.cmake)

picomos_machine(zbc
    CRT_SOURCES
        # crt/init-stack.S       # TODO: fill in
        # crt/vectors.S
    IO_SOURCES
        # io/zbc_semihost.c      # TODO
    LINKER_PARTS
        # linker/memory.ld       # TODO
        # linker/sections.ld
)
