# Convenience helpers for downstream CMake projects consuming an
# installed picomos SDK. Two entry points:
#
#   picomos_add_executable(hello MACHINE zbc SOURCES main.c)
#       Wraps add_executable() with the right --config= flag. Also
#       stamps the PICOMOS_MACHINE property on the target so
#       picomos_run() can find it later.
#
#   picomos_run(hello)
#       Adds a custom target `run-hello` that launches the built
#       binary under a machine-appropriate emulator. Cross-platform
#       (no shell), reads each machine's runners.cmake, honours env
#       overrides like PICOMOS_MAME=/path/to/mame.
#
# Everything here is convenience — a downstream project can just
# `add_executable` + append `--config=` manually, and invoke the
# emulator by hand. See machines/<name>/README.md for raw command lines.

# ---------------------------------------------------------------------
# picomos_add_executable
# ---------------------------------------------------------------------

function(picomos_add_executable target)
    cmake_parse_arguments(PARSE_ARGV 1 A
        "" "MACHINE" "SOURCES")

    if(NOT A_MACHINE)
        message(FATAL_ERROR "picomos_add_executable(${target}): MACHINE is required")
    endif()
    if(NOT A_SOURCES)
        message(FATAL_ERROR "picomos_add_executable(${target}): SOURCES is required")
    endif()

    set(_cfg "${PICOMOS_ROOT}/share/picomos/configs/picomos-${A_MACHINE}.cfg")
    if(NOT EXISTS "${_cfg}")
        message(FATAL_ERROR
            "picomos machine '${A_MACHINE}' not installed (missing ${_cfg})")
    endif()

    add_executable(${target} ${A_SOURCES})
    target_compile_options(${target} PRIVATE "--config=${_cfg}")
    target_link_options(${target}    PRIVATE "--config=${_cfg}")

    # Peek at the machine's runners.cmake to learn the conventional
    # output-file extension (e.g. .prg for c64, .elf for zbc). Machines
    # set PICOMOS_MACHINE_SUFFIX as a top-level assignment.
    # Including runners.cmake here also triggers picomos_register_runner
    # calls; the resulting per-runner variables are scoped to this
    # function frame and discarded on return — harmless.
    set(PICOMOS_MACHINE_SUFFIX "")
    include(
        "${PICOMOS_ROOT}/mos-elf/usr/share/picomos/machines/${A_MACHINE}/runners.cmake"
        OPTIONAL)

    set_target_properties(${target} PROPERTIES
        PICOMOS_MACHINE "${A_MACHINE}"
        # Blank fallback avoids a Windows-hosted CMake tacking ".exe"
        # onto a MOS binary. Machine's runners.cmake overrides.
        SUFFIX "${PICOMOS_MACHINE_SUFFIX}")
endfunction()

# ---------------------------------------------------------------------
# picomos_register_runner
#
# Called from machines/<name>/runners.cmake when picomos_run() includes
# that file. Populates a set of per-runner variables in the CALLING
# scope (picomos_run's frame), which picomos_run then reads back.
# ---------------------------------------------------------------------

function(picomos_register_runner)
    cmake_parse_arguments(PARSE_ARGV 0 R
        "DEFAULT"                                      # options
        "NAME;EXECUTABLE;ENV_OVERRIDE;PLUGIN_SCRIPT"   # single-value
        "ARGS")                                        # multi-value

    if(NOT R_NAME OR NOT R_EXECUTABLE OR NOT R_ARGS)
        message(FATAL_ERROR
            "picomos_register_runner: NAME, EXECUTABLE, and ARGS required")
    endif()

    # Append to the runners list and stash per-runner data in the parent
    # scope (the picomos_run function frame that included us).
    list(APPEND _picomos_runner_names "${R_NAME}")
    set(_picomos_runner_names "${_picomos_runner_names}" PARENT_SCOPE)

    set(_picomos_runner_${R_NAME}_executable    "${R_EXECUTABLE}"    PARENT_SCOPE)
    set(_picomos_runner_${R_NAME}_env_override  "${R_ENV_OVERRIDE}"  PARENT_SCOPE)
    set(_picomos_runner_${R_NAME}_plugin_script "${R_PLUGIN_SCRIPT}" PARENT_SCOPE)
    set(_picomos_runner_${R_NAME}_args          "${R_ARGS}"          PARENT_SCOPE)

    if(R_DEFAULT AND NOT _picomos_runner_default)
        set(_picomos_runner_default "${R_NAME}" PARENT_SCOPE)
    endif()
endfunction()

# ---------------------------------------------------------------------
# picomos_add_test(<target>
#     EXPECT       "regex to grep for in the emulator's stdout"
#   | EXPECT_FILE  path/to/golden-text-file
#     [EMULATOR name]
#     [TIMEOUT sec]
#     [EXTRA_ARGS ...])
#
# Adds a CTest entry that runs the target under an emulator (via the
# same machine `runners.cmake` machinery as picomos_run) and passes iff
# the captured stdout contains the EXPECT pattern.
#
# What "stdout" means depends on the machine. picomos's convention is
# that runner-*.lua streams each byte emitted through the machine's
# canonical output primitive (CHROUT on c64, KERNAL BSOUT elsewhere,
# semihost sys_write on zbc, ...) to the emulator subprocess's stdout.
# CTest greps that stream for the pattern — no screen-scraping, no
# extension per machine at this layer.
# ---------------------------------------------------------------------

function(picomos_add_test target)
    cmake_parse_arguments(PARSE_ARGV 1 T
        ""
        "EXPECT;EXPECT_FILE;EMULATOR;TIMEOUT;MACHINE"
        "EXTRA_ARGS")

    if(NOT T_EXPECT AND NOT T_EXPECT_FILE)
        message(FATAL_ERROR
            "picomos_add_test(${target}): pass EXPECT or EXPECT_FILE")
    endif()
    if(T_EXPECT AND T_EXPECT_FILE)
        message(FATAL_ERROR
            "picomos_add_test(${target}): EXPECT and EXPECT_FILE are exclusive")
    endif()

    # Resolve the machine — MACHINE arg wins, else the target's
    # PICOMOS_MACHINE property (set by picomos_add_executable).
    if(NOT T_MACHINE)
        get_target_property(T_MACHINE ${target} PICOMOS_MACHINE)
    endif()
    if(NOT T_MACHINE)
        message(FATAL_ERROR
            "picomos_add_test(${target}): no MACHINE and target has no "
            "PICOMOS_MACHINE property — was it built with picomos_add_executable?")
    endif()

    if(NOT T_TIMEOUT)
        set(T_TIMEOUT 15)
    endif()

    # Read runners.cmake to pick the emulator + build its argv, exactly
    # as picomos_run() does.
    set(_picomos_runner_names "")
    set(_picomos_runner_default "")
    set(_machine_dir
        "${PICOMOS_ROOT}/mos-elf/usr/share/picomos/machines/${T_MACHINE}")
    include("${_machine_dir}/runners.cmake" OPTIONAL)

    if(T_EMULATOR)
        set(_chosen "${T_EMULATOR}")
    elseif(DEFINED ENV{PICOMOS_EMULATOR})
        set(_chosen "$ENV{PICOMOS_EMULATOR}")
    elseif(_picomos_runner_default)
        set(_chosen "${_picomos_runner_default}")
    elseif(_picomos_runner_names)
        list(GET _picomos_runner_names 0 _chosen)
    else()
        message(FATAL_ERROR
            "picomos_add_test(${target}): no runners registered for machine "
            "'${T_MACHINE}'")
    endif()

    set(_env "${_picomos_runner_${_chosen}_env_override}")
    if(_env AND DEFINED ENV{${_env}})
        set(_exe "$ENV{${_env}}")
    else()
        set(_exe "${_picomos_runner_${_chosen}_executable}")
    endif()

    set(_plugin_script "")
    if(_picomos_runner_${_chosen}_plugin_script)
        set(_plugin_script
            "${_machine_dir}/${_picomos_runner_${_chosen}_plugin_script}")
    endif()

    set(_argv "")
    foreach(_arg IN LISTS _picomos_runner_${_chosen}_args)
        string(REPLACE "{TIMEOUT}"       "${T_TIMEOUT}"       _arg "${_arg}")
        string(REPLACE "{PLUGIN_SCRIPT}" "${_plugin_script}"  _arg "${_arg}")
        string(REPLACE "{PROGRAM}" "$<TARGET_FILE:${target}>" _arg "${_arg}")
        list(APPEND _argv "${_arg}")
    endforeach()

    # Compose the expected pattern. EXPECT_FILE is read at configure
    # time — small files only. Escape regex metacharacters unless the
    # user opts into a raw regex via CMake's own $<> escapes (not
    # supported here yet — keep it plain-text for now).
    if(T_EXPECT_FILE)
        file(READ "${T_EXPECT_FILE}" _pattern)
    else()
        set(_pattern "${T_EXPECT}")
    endif()

    # CTest kills the process after `TIMEOUT` seconds wall-clock. Pad
    # a few seconds over the emulator's own -seconds_to_run so that
    # MAME shuts down cleanly rather than being SIGKILLed.
    math(EXPR _ctest_timeout "${T_TIMEOUT} + 10")

    add_test(NAME ${target}
        COMMAND ${_exe} ${_argv} ${T_EXTRA_ARGS})
    set_tests_properties(${target} PROPERTIES
        PASS_REGULAR_EXPRESSION "${_pattern}"
        TIMEOUT "${_ctest_timeout}")
endfunction()

# ---------------------------------------------------------------------
# picomos_run(<target> [EMULATOR name] [TIMEOUT sec] [EXTRA_ARGS ...])
#
# Adds a `run-<target>` custom target that invokes the machine's
# emulator on the built binary. Selects the runner from (in order):
#   1. EMULATOR argument
#   2. PICOMOS_EMULATOR environment variable
#   3. the machine's DEFAULT runner from runners.cmake
#   4. the first runner registered
#
# Executable path override per emulator via ENV_OVERRIDE (typically
# PICOMOS_MAME, PICOMOS_VICE, ...), so users don't have to touch
# runners.cmake to point at a locally-built emulator.
# ---------------------------------------------------------------------

function(picomos_run target)
    cmake_parse_arguments(PARSE_ARGV 1 P
        ""
        "EMULATOR;TIMEOUT;MACHINE"
        "EXTRA_ARGS")

    # 1. Resolve machine — MACHINE arg wins, else target property, else fail.
    if(NOT P_MACHINE)
        get_target_property(P_MACHINE ${target} PICOMOS_MACHINE)
    endif()
    if(NOT P_MACHINE)
        message(FATAL_ERROR
            "picomos_run(${target}): cannot determine target machine. "
            "Pass MACHINE, or create the target via picomos_add_executable.")
    endif()

    # 2. Load runners.cmake from the machine overlay. Populates
    # _picomos_runner_names, _picomos_runner_default, and per-runner
    # _picomos_runner_<name>_* variables in this function scope via
    # picomos_register_runner's PARENT_SCOPE writes.
    set(_picomos_runner_names "")
    set(_picomos_runner_default "")
    set(_machine_dir
        "${PICOMOS_ROOT}/mos-elf/usr/share/picomos/machines/${P_MACHINE}")
    set(_runners_file "${_machine_dir}/runners.cmake")
    if(NOT EXISTS "${_runners_file}")
        message(FATAL_ERROR
            "picomos_run(${target}): no runners.cmake for machine "
            "'${P_MACHINE}' (looked at ${_runners_file})")
    endif()
    include("${_runners_file}")

    # 3. Pick a runner.
    if(P_EMULATOR)
        set(_chosen "${P_EMULATOR}")
    elseif(DEFINED ENV{PICOMOS_EMULATOR})
        set(_chosen "$ENV{PICOMOS_EMULATOR}")
    elseif(_picomos_runner_default)
        set(_chosen "${_picomos_runner_default}")
    elseif(_picomos_runner_names)
        list(GET _picomos_runner_names 0 _chosen)
    else()
        message(FATAL_ERROR
            "picomos_run(${target}): runners.cmake for '${P_MACHINE}' "
            "registered no runners.")
    endif()

    if(NOT "${_chosen}" IN_LIST _picomos_runner_names)
        message(FATAL_ERROR
            "picomos_run(${target}): emulator '${_chosen}' not registered "
            "for machine '${P_MACHINE}'. Available: ${_picomos_runner_names}")
    endif()

    # 4. Resolve executable (env override wins over runners.cmake default).
    set(_env "${_picomos_runner_${_chosen}_env_override}")
    if(_env AND DEFINED ENV{${_env}})
        set(_exe "$ENV{${_env}}")
    else()
        set(_exe "${_picomos_runner_${_chosen}_executable}")
    endif()

    # 5. Substitute {PROGRAM} / {TIMEOUT} / {PLUGIN_SCRIPT} in argv.
    if(NOT P_TIMEOUT)
        set(P_TIMEOUT 30)
    endif()
    set(_plugin_script "")
    if(_picomos_runner_${_chosen}_plugin_script)
        set(_plugin_script
            "${_machine_dir}/${_picomos_runner_${_chosen}_plugin_script}")
    endif()

    set(_argv "")
    foreach(_arg IN LISTS _picomos_runner_${_chosen}_args)
        string(REPLACE "{TIMEOUT}"       "${P_TIMEOUT}"       _arg "${_arg}")
        string(REPLACE "{PLUGIN_SCRIPT}" "${_plugin_script}"  _arg "${_arg}")
        # {PROGRAM} is a generator expression resolved at build time,
        # so the target need not exist yet.
        string(REPLACE "{PROGRAM}" "$<TARGET_FILE:${target}>" _arg "${_arg}")
        list(APPEND _argv "${_arg}")
    endforeach()

    # 6. Custom build target — `cmake --build build --target run-<target>`.
    add_custom_target(run-${target}
        COMMAND ${_exe} ${_argv} ${P_EXTRA_ARGS}
        DEPENDS ${target}
        VERBATIM
        USES_TERMINAL
        COMMENT "picomos: running ${target} on machine ${P_MACHINE} under ${_chosen}")
endfunction()
