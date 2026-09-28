# Auto-discover machines: every subdirectory of machines/ that contains
# a machine.cmake is treated as a machine (concrete or abstract).
#
# Machine registration flow:
#   1. Reset the registry (survives across CMake reconfigures via CACHE
#      INTERNAL vars, so clear on every configure).
#   2. Include every discovered machine.cmake in this scope. Each one
#      calls picomos_machine() and picomos_emulator() to add itself and
#      its runners to the registry.
#   3. picomos_process_machines() walks the registry and emits build
#      rules for every concrete machine that's in PICOMOS_MACHINES.
#
# Abstract machines (declared with the ABSTRACT keyword) exist to be
# inherited from — see machines/cbm/machine.cmake for an example. They
# never appear in PICOMOS_MACHINES and never emit build artifacts on
# their own.

include(${CMAKE_SOURCE_DIR}/cmake/PicomosMachine.cmake)

_picomos_reset_registry()

file(GLOB _picomos_machine_cmakes
     "${CMAKE_CURRENT_SOURCE_DIR}/*/machine.cmake")
list(SORT _picomos_machine_cmakes)

foreach(_mc IN LISTS _picomos_machine_cmakes)
    get_filename_component(_picomos_machine_current_dir "${_mc}" DIRECTORY)
    include("${_mc}")
endforeach()
unset(_picomos_machine_current_dir)

picomos_process_machines()
