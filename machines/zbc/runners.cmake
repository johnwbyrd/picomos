# Runner + output declarations for the zbc machine. Read by
# picomos_run() (for runner selection) and by picomos_add_executable()
# (for the output filename extension) at consumer time. Not consumed
# by picomos's own build.

# ZBC's MAME driver takes an ELF via -elfload — extension is
# conventional, not strictly required, but keeps consumer output tidy.
set(PICOMOS_MACHINE_SUFFIX ".elf")
#
# Substitutions expanded when picomos_run invokes the emulator:
#   {PROGRAM}        absolute path to the built binary
#   {TIMEOUT}        seconds — from picomos_run's TIMEOUT arg (default 30)
#   {PLUGIN_SCRIPT}  absolute path to this runner's PLUGIN_SCRIPT file
#                    (installed alongside this runners.cmake)

picomos_register_runner(
    NAME         mame
    DEFAULT
    EXECUTABLE   mame
    ENV_OVERRIDE PICOMOS_MAME
    ARGS
        zbcm6502
        -window
        -skip_gameinfo
        -elfload         {PROGRAM}
        -seconds_to_run  {TIMEOUT}
)
