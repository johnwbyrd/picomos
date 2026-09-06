# Standalone CMake project — consumes an installed picomos SDK via
# find_package(Picomos). Configure with:
#   cmake -B build -DPicomos_DIR=/opt/picomos/share/picomos/cmake

cmake_minimum_required(VERSION 3.24)
project(hello LANGUAGES C)

# Enable CTest early — must precede any add_test() (including those
# emitted by picomos_add_test) for tests to be registered.
enable_testing()

find_package(Picomos REQUIRED)

picomos_add_executable(hello
    MACHINE zbc
    SOURCES main.c)

# `cmake --build build --target run-hello` launches MAME on the built
# ELF. Override MAME path with the PICOMOS_MAME environment variable
# if it isn't on PATH.
picomos_run(hello TIMEOUT 5)

# `ctest` runs MAME and asserts that "hello, mos" appears in the
# semihost stdout stream (which MAME's zbcm6502 driver routes to the
# subprocess's stdout without any lua help).
picomos_add_test(hello EXPECT "hello, mos" TIMEOUT 5)
