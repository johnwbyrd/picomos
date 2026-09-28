# Standalone CMake project — consumes an installed picomos SDK via
# find_package(Picomos). Configure with:
#   cmake -B build -G Ninja -DPicomos_DIR=/opt/picomos/share/picomos/cmake
#
# Portable across every machine the installed SDK ships. Builds one
# executable per machine from a single main.c. Restrict to a subset with:
#   cmake -B build ... -DPRINTF_FORMATTERS_MACHINES=c64

cmake_minimum_required(VERSION 3.24)
project(printf_formatters LANGUAGES C)

enable_testing()

find_package(Picomos REQUIRED)

set(PRINTF_FORMATTERS_MACHINES "${PICOMOS_MACHINES}" CACHE STRING
    "picomos machines to build printf_formatters for (semicolon-separated).")

foreach(machine IN LISTS PRINTF_FORMATTERS_MACHINES)
    picomos_add_executable(printf_formatters-${machine}
        MACHINE ${machine}
        SOURCES main.c)

    picomos_run(printf_formatters-${machine} TIMEOUT 10)

    # Assert the %ld line renders exactly right: that catches integer
    # conversion regressions (e.g. a broken software 32-bit divide) that
    # a plain "done." match would let through unnoticed.
    picomos_add_test(printf_formatters-${machine}
        EXPECT "ld: 1000000 -1000000" TIMEOUT 10)
endforeach()
