# Standalone CMake project — consumes an installed picomos SDK via
# find_package(Picomos). Configure with:
#   cmake -B build -G Ninja \
#       -DCMAKE_TOOLCHAIN_FILE=$PICOMOS/share/picomos/cmake/mos-toolchain.cmake \
#       -DPicomos_DIR=$PICOMOS/share/picomos/cmake

cmake_minimum_required(VERSION 3.24)
project(hello LANGUAGES C)

# Enable CTest before find_package so picomos_add_test's add_test call
# is registered.
enable_testing()

find_package(Picomos REQUIRED)

picomos_add_executable(hello
    MACHINE nes
    SOURCES main.c)

# `cmake --build build --target run-hello` launches MAME on the built
# .nes file. The bundled runner-mame.lua plugin taps writes to $401B
# and mirrors each byte to the terminal.
picomos_run(hello TIMEOUT 10)

# `ctest` runs the same emulator invocation and asserts that "hello,
# mos" appears in the captured $401B stream.
picomos_add_test(hello EXPECT "hello, mos" TIMEOUT 10)
