# Standalone CMake project — consumes an installed picomos SDK via
# find_package(Picomos). Configure with:
#   cmake -B build -G Ninja -DPicomos_DIR=/opt/picomos/share/picomos/cmake

cmake_minimum_required(VERSION 3.24)
project(hello LANGUAGES C)

# Enable CTest early — must precede any add_test() (including those
# emitted by picomos_add_test) for tests to be registered.
enable_testing()

find_package(Picomos REQUIRED)

picomos_add_executable(hello
    MACHINE c64
    SOURCES main.c)

# `cmake --build build --target run-hello` launches MAME on the built
# PRG, auto-types RUN via the bundled runner-mame.lua plugin, and
# mirrors KERNAL CHROUT output to the terminal. Override the MAME
# binary with the PICOMOS_MAME environment variable.
picomos_run(hello TIMEOUT 10)

# `ctest` runs the same emulator invocation and asserts that "hello,
# mos" appears anywhere in the captured CHROUT stream. The KERNAL
# banner ends up in the output too — CTest's PASS_REGULAR_EXPRESSION
# is a substring match.
picomos_add_test(hello EXPECT "hello, mos" TIMEOUT 10)
