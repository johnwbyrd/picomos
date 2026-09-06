# Standalone CMake project — consumes an installed picomos SDK via
# find_package(Picomos). Configure with:
#   cmake -B build -DPicomos_DIR=/opt/picomos/share/picomos/cmake

cmake_minimum_required(VERSION 3.24)
project(hello LANGUAGES C)

find_package(Picomos REQUIRED)

picomos_add_executable(hello
    MACHINE zbc
    SOURCES main.c)

# Optional: `cmake --build build --target run-hello` launches MAME on
# the built ELF. Override MAME path with the PICOMOS_MAME environment
# variable if it isn't on PATH.
picomos_run(hello TIMEOUT 5)
