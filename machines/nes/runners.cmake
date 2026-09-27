# Runner + output declarations for the nes machine. Read by
# picomos_run() (for runner selection) and by picomos_add_executable()
# (for the output filename extension).

# iNES 2.0 (.nes) is what every emulator's cartridge slot expects.
set(PICOMOS_MACHINE_SUFFIX ".nes")

picomos_register_runner(
    NAME          mame
    DEFAULT
    EXECUTABLE    mame
    ENV_OVERRIDE  PICOMOS_MAME
    PLUGIN_SCRIPT runner-mame.lua
    ARGS
        nes
        -window
        -skip_gameinfo
        -cart              {PROGRAM}
        -plugins
        -autoboot_script   {PLUGIN_SCRIPT}
        -seconds_to_run    {TIMEOUT}
)
