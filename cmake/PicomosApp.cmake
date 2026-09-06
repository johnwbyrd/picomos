# Convenience helper for downstream CMake projects consuming an installed
# picomos SDK. Expands to a plain mos-clang invocation with --config so it
# is functionally identical to the "direct compiler" and "Makefile" user
# workflows — no picomos-only behavior.
#
# Usage in a downstream CMakeLists.txt:
#
#   find_package(Picomos REQUIRED)
#   picomos_add_executable(hello
#       MACHINE zbc
#       SOURCES main.c)
#
# Under the hood this runs:
#   mos-clang --config=<picomos>/share/picomos/configs/picomos-zbc.cfg \
#             main.c -o hello.elf
#
# If a downstream user prefers `add_executable` and passes the config flag
# themselves, that works too — this function is a convenience, not a
# requirement.

function(picomos_add_executable target)
    cmake_parse_arguments(PARSE_ARGV 1 A
        "" "MACHINE" "SOURCES")

    if(NOT A_MACHINE)
        message(FATAL_ERROR "picomos_add_executable(${target}): MACHINE is required")
    endif()
    if(NOT A_SOURCES)
        message(FATAL_ERROR "picomos_add_executable(${target}): SOURCES is required")
    endif()

    set(_cfg "${PICOMOS_ROOT}/share/picomos/configs/picomos-${A_MACHINE}.cfg")
    if(NOT EXISTS "${_cfg}")
        message(FATAL_ERROR
            "picomos machine '${A_MACHINE}' not installed (missing ${_cfg})")
    endif()

    add_executable(${target} ${A_SOURCES})
    target_compile_options(${target} PRIVATE "--config=${_cfg}")
    target_link_options(${target}    PRIVATE "--config=${_cfg}")
    set_target_properties(${target} PROPERTIES SUFFIX ".elf")
endfunction()
