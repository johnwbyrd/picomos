# Standalone CMake project — consumes an installed picomos SDK via
# find_package(Picomos). Configure with:
#   cmake -B build -G Ninja -DPicomos_DIR=/opt/picomos/share/picomos/cmake

cmake_minimum_required(VERSION 3.24)
project(hello LANGUAGES C)

find_package(Picomos REQUIRED)

picomos_add_executable(hello
    MACHINE c64
    SOURCES main.c)

# Optional: `cmake --build build --target run-hello` launches MAME on
# the built PRG, auto-types RUN via the bundled runner-mame.lua plugin,
# and prints "HELLO, MOS" on the emulated C64 screen. Override the MAME
# binary with the PICOMOS_MAME environment variable.
picomos_run(hello TIMEOUT 10)
