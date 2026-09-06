# Runner + output declarations for the c64 machine. Read by
# picomos_run() (for runner selection) and by picomos_add_executable()
# (for the output filename extension) at consumer time. Not consumed
# by picomos's own build.

# MAME's -quik picks a loader based on the file extension (.prg, .p00,
# .t64). Without one, quickload fails with "Unsupported operation".
set(PICOMOS_MACHINE_SUFFIX ".prg")
#
# Substitutions expanded when picomos_run invokes the emulator:
#   {PROGRAM}        absolute path to the built binary
#   {TIMEOUT}        seconds — from picomos_run's TIMEOUT arg (default 30)
#   {PLUGIN_SCRIPT}  absolute path to this runner's PLUGIN_SCRIPT file
#                    (installed alongside this runners.cmake)

picomos_register_runner(
    NAME          mame
    DEFAULT
    EXECUTABLE    mame
    ENV_OVERRIDE  PICOMOS_MAME
    PLUGIN_SCRIPT runner-mame.lua
    ARGS
        c64
        -window
        -skip_gameinfo
        -quik              {PROGRAM}
        -plugins
        -autoboot_script   {PLUGIN_SCRIPT}
        -seconds_to_run    {TIMEOUT}
)

# VICE runner sketched but not verified — no machinery in picomos exercises
# it yet. Enable via `picomos_run(hello EMULATOR vice)` or PICOMOS_EMULATOR=vice.
picomos_register_runner(
    NAME         vice
    EXECUTABLE   x64sc
    ENV_OVERRIDE PICOMOS_VICE
    ARGS
        -autostart          {PROGRAM}
        -warp
        -limitcycles        50000000
)
