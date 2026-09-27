# Standalone CMake project — consumes an installed picomos SDK via
# find_package(Picomos). Configure with:
#   cmake -B build -G Ninja -DPicomos_DIR=/opt/picomos/share/picomos/cmake
#
# Portable across every machine the installed SDK ships. Builds one
# executable per machine (hello-zbc, hello-c64, hello-nes, ...) from a
# single main.c. Restrict to a subset with:
#   cmake -B build ... -DHELLO_MACHINES=c64
# (semicolon-separated for multiple).

cmake_minimum_required(VERSION 3.24)
project(hello LANGUAGES C)

# CTest must be enabled before any add_test() call, including those
# emitted by picomos_add_test() below.
enable_testing()

find_package(Picomos REQUIRED)

# Default to every machine the SDK provides; PICOMOS_MACHINES is set
# by PicomosConfig.cmake based on the installed picomos-*.cfg files.
set(HELLO_MACHINES "${PICOMOS_MACHINES}" CACHE STRING
    "picomos machines to build hello for (semicolon-separated).")

foreach(machine IN LISTS HELLO_MACHINES)
    picomos_add_executable(hello-${machine}
        MACHINE ${machine}
        SOURCES main.c)

    # `cmake --build build --target run-hello-<machine>` launches the
    # machine's registered emulator on the built binary. Override the
    # emulator binary via each machine's env var (PICOMOS_MAME, ...).
    picomos_run(hello-${machine} TIMEOUT 10)

    # `ctest -R hello-<machine>` runs the same emulator invocation and
    # asserts "hello, mos" appears in the captured stdio stream.
    picomos_add_test(hello-${machine} EXPECT "hello, mos" TIMEOUT 10)
endforeach()
