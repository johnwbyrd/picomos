# Standalone CMake project — consumes an installed picomos SDK via
# find_package(Picomos). Configure with:
#   cmake -B build -G Ninja -DPicomos_DIR=/opt/picomos/share/picomos/cmake
#
# Portable across every machine the installed SDK ships. Builds one
# executable per machine (malloc_free-zbc, malloc_free-c64, ...) from
# a single main.c. Restrict to a subset with:
#   cmake -B build ... -DMALLOC_FREE_MACHINES=c64

cmake_minimum_required(VERSION 3.24)
project(malloc_free LANGUAGES C)

enable_testing()

find_package(Picomos REQUIRED)

set(MALLOC_FREE_MACHINES "${PICOMOS_MACHINES}" CACHE STRING
    "picomos machines to build malloc_free for (semicolon-separated).")

foreach(machine IN LISTS MALLOC_FREE_MACHINES)
    picomos_add_executable(malloc_free-${machine}
        MACHINE ${machine}
        SOURCES main.c)

    picomos_run(malloc_free-${machine} TIMEOUT 10)

    # Program prints "done." only if malloc/free round-trip succeeded.
    picomos_add_test(malloc_free-${machine} EXPECT "done\\." TIMEOUT 10)
endforeach()
