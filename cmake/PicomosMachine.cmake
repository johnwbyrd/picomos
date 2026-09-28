# PicomosMachine.cmake — machine-registration helpers used by
# machines/<name>/machine.cmake.
#
# Two user-visible calls:
#
#   picomos_machine(<name>
#       [ABSTRACT]              # Base for other machines; not built or installed.
#       [INHERITS <parent>]     # Pull sources / metadata from an ancestor.
#       DISPLAY_NAME "..."      # Required on concrete machines.
#       CPU 6502                # Inherited if unset.
#       ENDIANNESS little       # Inherited if unset.
#       MEMORY_MAP "..."        # Human-facing memory description.
#       [DEFINES ...]           # -D flags for crt0 + I/O compilation.
#       [LINK_LIBS ...]         # Extra libs the machine's cfg pulls in.
#
#       # Source overrides. Empty (the default) means "auto-discover
#       # crt/*.[cS], io/*.[cS], linker/*.ld from this machine's dir and
#       # every ancestor. Child files override ancestor files by basename.
#       # Absolute paths or dir-relative paths accepted."
#       [CRT_SOURCES  ...]
#       [IO_SOURCES   ...]
#       [LINKER_PARTS ...]
#       [EXCLUDE_SOURCES ...])  # Basenames to drop from auto-discovery.
#
#   picomos_emulator(<machine> <emulator>
#       [DEFAULT]               # Mark this as the machine's default runner.
#       EXECUTABLE <exe>        # Emulator binary name or path.
#       [ENV_OVERRIDE <VAR>]    # Env var that overrides the binary path.
#       [PLUGIN_SCRIPT <file>]  # Helper script (e.g. runner-mame.lua).
#       [OUTPUT_EXT .prg]       # File extension for built programs.
#       [REQUIRES_ROMS]         # Documentation flag; picked up in notes.
#       [NOTES "..."]           # Human-facing note.
#       ARGS ...)               # emulator argv with {PROGRAM}, {TIMEOUT},
#                               # {PLUGIN_SCRIPT} substitution tokens.
#
# The two calls are declarative. picomos_process_machines(), invoked once
# by machines/CMakeLists.txt after every machine.cmake has been included,
# walks the registered set and emits the build rules (crt0.o, libio.a,
# link.ld, installed runners.cmake, clang config).

include(${CMAKE_CURRENT_LIST_DIR}/PicomosConfigWrite.cmake)

# ---------------------------------------------------------------------
# Registry state. All machine data lives in CACHE INTERNAL vars so it
# survives across include() boundaries without PARENT_SCOPE plumbing.
# Cleared at the top of machines/CMakeLists.txt via _picomos_reset_registry.
# ---------------------------------------------------------------------

macro(_picomos_reset_registry)
    set(_picomos_machines "" CACHE INTERNAL "")
endmacro()

# ---------------------------------------------------------------------
# picomos_machine
# ---------------------------------------------------------------------

function(picomos_machine name)
    cmake_parse_arguments(PARSE_ARGV 1 M
        "ABSTRACT"
        "INHERITS;DISPLAY_NAME;CPU;ENDIANNESS;MEMORY_MAP"
        "DEFINES;LINK_LIBS;CRT_SOURCES;IO_SOURCES;LINKER_PARTS;EXCLUDE_SOURCES")

    if(NOT DEFINED _picomos_machine_current_dir)
        message(FATAL_ERROR
            "picomos_machine(${name}): must be called from a machine.cmake "
            "that was included by machines/CMakeLists.txt (missing "
            "_picomos_machine_current_dir).")
    endif()

    # Enforce single registration per name.
    if("${name}" IN_LIST _picomos_machines)
        message(FATAL_ERROR
            "picomos_machine(${name}): already registered (from "
            "${_picomos_machine_${name}_dir}).")
    endif()

    set(_new_list "${_picomos_machines}")
    list(APPEND _new_list "${name}")
    set(_picomos_machines "${_new_list}" CACHE INTERNAL "")

    # Per-machine cache slots.
    set(_picomos_machine_${name}_dir       "${_picomos_machine_current_dir}" CACHE INTERNAL "")
    set(_picomos_machine_${name}_abstract  "${M_ABSTRACT}" CACHE INTERNAL "")
    set(_picomos_machine_${name}_parent    "${M_INHERITS}" CACHE INTERNAL "")
    set(_picomos_machine_${name}_display   "${M_DISPLAY_NAME}" CACHE INTERNAL "")
    set(_picomos_machine_${name}_cpu       "${M_CPU}" CACHE INTERNAL "")
    set(_picomos_machine_${name}_endian    "${M_ENDIANNESS}" CACHE INTERNAL "")
    set(_picomos_machine_${name}_memmap    "${M_MEMORY_MAP}" CACHE INTERNAL "")
    set(_picomos_machine_${name}_defines   "${M_DEFINES}" CACHE INTERNAL "")
    set(_picomos_machine_${name}_link_libs "${M_LINK_LIBS}" CACHE INTERNAL "")
    set(_picomos_machine_${name}_crt_over  "${M_CRT_SOURCES}" CACHE INTERNAL "")
    set(_picomos_machine_${name}_io_over   "${M_IO_SOURCES}" CACHE INTERNAL "")
    set(_picomos_machine_${name}_ld_over   "${M_LINKER_PARTS}" CACHE INTERNAL "")
    set(_picomos_machine_${name}_excludes  "${M_EXCLUDE_SOURCES}" CACHE INTERNAL "")
    set(_picomos_machine_${name}_emulators "" CACHE INTERNAL "")
endfunction()

# ---------------------------------------------------------------------
# picomos_emulator
# ---------------------------------------------------------------------

function(picomos_emulator machine emul)
    cmake_parse_arguments(PARSE_ARGV 2 E
        "DEFAULT;REQUIRES_ROMS"
        "EXECUTABLE;ENV_OVERRIDE;PLUGIN_SCRIPT;OUTPUT_EXT;NOTES"
        "ARGS")

    if(NOT "${machine}" IN_LIST _picomos_machines)
        message(FATAL_ERROR
            "picomos_emulator(${machine} ${emul}): machine '${machine}' "
            "not registered — call picomos_machine(${machine} ...) first.")
    endif()
    if(NOT E_EXECUTABLE)
        message(FATAL_ERROR
            "picomos_emulator(${machine} ${emul}): EXECUTABLE required.")
    endif()
    if(NOT E_ARGS)
        message(FATAL_ERROR
            "picomos_emulator(${machine} ${emul}): ARGS required.")
    endif()

    set(_emus "${_picomos_machine_${machine}_emulators}")
    if("${emul}" IN_LIST _emus)
        message(FATAL_ERROR
            "picomos_emulator(${machine} ${emul}): already registered.")
    endif()
    list(APPEND _emus "${emul}")
    set(_picomos_machine_${machine}_emulators "${_emus}" CACHE INTERNAL "")

    set(_prefix _picomos_machine_${machine}_emulator_${emul})
    set(${_prefix}_default        "${E_DEFAULT}"        CACHE INTERNAL "")
    set(${_prefix}_executable     "${E_EXECUTABLE}"     CACHE INTERNAL "")
    set(${_prefix}_env_override   "${E_ENV_OVERRIDE}"   CACHE INTERNAL "")
    set(${_prefix}_plugin_script  "${E_PLUGIN_SCRIPT}"  CACHE INTERNAL "")
    set(${_prefix}_output_ext     "${E_OUTPUT_EXT}"     CACHE INTERNAL "")
    set(${_prefix}_requires_roms  "${E_REQUIRES_ROMS}"  CACHE INTERNAL "")
    set(${_prefix}_notes          "${E_NOTES}"          CACHE INTERNAL "")
    set(${_prefix}_args           "${E_ARGS}"           CACHE INTERNAL "")
endfunction()

# ---------------------------------------------------------------------
# Inheritance-aware helpers.
# ---------------------------------------------------------------------

# Return in <out_var> the ancestor chain of <name>, root first (so most-
# distant ancestor is first, then descendants, then <name> itself).
function(_picomos_ancestor_chain name out_var)
    set(_chain "")
    set(_cursor "${name}")
    while(_cursor)
        list(INSERT _chain 0 "${_cursor}")
        set(_cursor "${_picomos_machine_${_cursor}_parent}")
        if(_cursor AND NOT "${_cursor}" IN_LIST _picomos_machines)
            message(FATAL_ERROR
                "picomos_machine(${name}): parent '${_cursor}' referenced "
                "via INHERITS is not registered.")
        endif()
        if("${_cursor}" IN_LIST _chain)
            message(FATAL_ERROR
                "picomos_machine(${name}): inheritance cycle through "
                "'${_cursor}'.")
        endif()
    endwhile()
    set(${out_var} "${_chain}" PARENT_SCOPE)
endfunction()

# Resolve the effective source list for one bucket ("crt" / "io" / "linker")
# for machine <name>: walk the ancestor chain root-to-leaf and glob
# <ancestor_dir>/<subdir>/<glob> from each. Child files override parent
# by basename (later wins). Explicit overrides on the machine (CRT_SOURCES
# etc.) short-circuit the chain — machine sets everything by hand.
function(_picomos_collect_sources name subdir globs override_var excludes_var out_var)
    set(${out_var} "" PARENT_SCOPE)

    # If the leaf machine set an explicit override, honour it verbatim
    # (relative to its own dir).
    set(_override "${_picomos_machine_${name}_${override_var}}")
    if(_override)
        set(_abs "")
        foreach(_s IN LISTS _override)
            if(IS_ABSOLUTE "${_s}")
                list(APPEND _abs "${_s}")
            else()
                list(APPEND _abs "${_picomos_machine_${name}_dir}/${_s}")
            endif()
        endforeach()
        set(${out_var} "${_abs}" PARENT_SCOPE)
        return()
    endif()

    _picomos_ancestor_chain("${name}" _chain)
    set(_excludes "${_picomos_machine_${name}_${excludes_var}}")

    # Merge with later (more-derived) files replacing earlier ones by
    # basename. Store as parallel lists: _keys (basename) → _paths (abs).
    set(_keys "")
    set(_paths "")
    foreach(_ancestor IN LISTS _chain)
        set(_dir "${_picomos_machine_${_ancestor}_dir}/${subdir}")
        if(NOT IS_DIRECTORY "${_dir}")
            continue()
        endif()
        set(_absglobs "")
        foreach(_g IN LISTS globs)
            list(APPEND _absglobs "${_dir}/${_g}")
        endforeach()
        file(GLOB _found ${_absglobs})
        list(SORT _found)
        foreach(_f IN LISTS _found)
            get_filename_component(_b "${_f}" NAME)
            if("${_b}" IN_LIST _excludes)
                continue()
            endif()
            if("${_b}" IN_LIST _keys)
                # Later ancestor overrides earlier — update the path in place.
                list(FIND _keys "${_b}" _idx)
                list(REMOVE_AT _paths ${_idx})
                list(INSERT _paths ${_idx} "${_f}")
            else()
                list(APPEND _keys  "${_b}")
                list(APPEND _paths "${_f}")
            endif()
        endforeach()
    endforeach()
    set(${out_var} "${_paths}" PARENT_SCOPE)
endfunction()

# Look up a piece of metadata; fall back through the inheritance chain.
function(_picomos_inherited name key out_var)
    _picomos_ancestor_chain("${name}" _chain)
    list(REVERSE _chain)  # leaf first, walk toward root
    foreach(_m IN LISTS _chain)
        set(_v "${_picomos_machine_${_m}_${key}}")
        if(_v)
            set(${out_var} "${_v}" PARENT_SCOPE)
            return()
        endif()
    endforeach()
    set(${out_var} "" PARENT_SCOPE)
endfunction()

# ---------------------------------------------------------------------
# picomos_process_machines — driver called once after every machine.cmake
# has been included. Emits build rules for every non-abstract machine
# that's in PICOMOS_MACHINES.
# ---------------------------------------------------------------------

function(picomos_process_machines)
    # Validate PICOMOS_MACHINES: entries must be registered AND non-abstract.
    foreach(_m IN LISTS PICOMOS_MACHINES)
        if(NOT "${_m}" IN_LIST _picomos_machines)
            message(FATAL_ERROR
                "PICOMOS_MACHINES contains unknown machine '${_m}'. "
                "Registered: ${_picomos_machines}")
        endif()
        if(_picomos_machine_${_m}_abstract)
            message(FATAL_ERROR
                "PICOMOS_MACHINES contains abstract machine '${_m}'. "
                "Abstract machines are inherited from, not built directly.")
        endif()
    endforeach()

    foreach(_m IN LISTS PICOMOS_MACHINES)
        _picomos_emit_machine("${_m}")
    endforeach()
endfunction()

# ---------------------------------------------------------------------
# Internal: build rules for one concrete machine.
# ---------------------------------------------------------------------

function(_picomos_emit_machine machine_name)
    set(_rel  "usr/share/picomos/machines/${machine_name}")
    set(_dest "${PICOMOS_SYSROOT_RELATIVE}/${_rel}")
    set(_stage_dir "${PICOMOS_PICOLIBC_STAGING}/${_rel}")
    file(MAKE_DIRECTORY "${_stage_dir}")

    # If llvm-mos is being built from source in this run, custom
    # commands that invoke mos-clang must wait for it.
    set(_machine_extra_deps "")
    if(TARGET llvm-mos)
        list(APPEND _machine_extra_deps llvm-mos)
    endif()

    # Resolve source lists via inheritance chain.
    _picomos_collect_sources("${machine_name}" "crt"
        "*.c;*.S;*.s" "crt_over" "excludes" _crt_sources)
    _picomos_collect_sources("${machine_name}" "io"
        "*.c;*.S;*.s" "io_over" "excludes" _io_sources)
    _picomos_collect_sources("${machine_name}" "linker"
        "*.ld" "ld_over" "excludes" _linker_parts)

    # Compose DEFINES / LINK_LIBS from ancestor chain.
    _picomos_ancestor_chain("${machine_name}" _chain)
    set(_defines "")
    set(_link_libs "")
    foreach(_a IN LISTS _chain)
        list(APPEND _defines   ${_picomos_machine_${_a}_defines})
        list(APPEND _link_libs ${_picomos_machine_${_a}_link_libs})
    endforeach()
    list(REMOVE_DUPLICATES _defines)
    list(REMOVE_DUPLICATES _link_libs)

    # --- assembled linker script -----------------------------------
    if(_linker_parts)
        set(_link_ld "${_stage_dir}/link.ld")
        add_custom_command(
            OUTPUT "${_link_ld}"
            COMMAND ${CMAKE_COMMAND} -E cat ${_linker_parts} > "${_link_ld}"
            DEPENDS ${_linker_parts}
            COMMENT "picomos[${machine_name}]: assembling link.ld")
        add_custom_target(${machine_name}-link ALL DEPENDS "${_link_ld}")
        install(FILES "${_link_ld}" DESTINATION "${_dest}")
    endif()

    # --- crt0.o ----------------------------------------------------
    if(_crt_sources)
        set(_crt0_o "${_stage_dir}/crt0.o")
        set(_crt_defs "")
        foreach(_d IN LISTS _defines)
            list(APPEND _crt_defs "-D${_d}")
        endforeach()
        add_custom_command(
            OUTPUT "${_crt0_o}"
            COMMAND "${PICOMOS_MOS_CLANG}"
                    -nostdlib -Oz -flto
                    -D__IEEE_LITTLE_ENDIAN -D_LDBL_EQ_DBL
                    -isystem "${PICOMOS_PICOLIBC_STAGING}/usr/include"
                    ${_crt_defs}
                    -r -o "${_crt0_o}"
                    ${_crt_sources}
            DEPENDS ${_crt_sources} picolibc-mos ${_machine_extra_deps}
            COMMENT "picomos[${machine_name}]: compiling crt0.o")
        add_custom_target(${machine_name}-crt0 ALL DEPENDS "${_crt0_o}")
        install(FILES "${_crt0_o}" DESTINATION "${_dest}")
    endif()

    # --- libio.a ---------------------------------------------------
    if(_io_sources)
        set(_libio "${_stage_dir}/libio.a")
        set(_io_objs "")
        foreach(_src IN LISTS _io_sources)
            get_filename_component(_stem "${_src}" NAME_WE)
            set(_obj "${_stage_dir}/io_${_stem}.o")
            list(APPEND _io_objs "${_obj}")
            add_custom_command(
                OUTPUT "${_obj}"
                COMMAND "${PICOMOS_MOS_CLANG}"
                        -nostdlib -Oz -flto
                        -D__IEEE_LITTLE_ENDIAN -D_LDBL_EQ_DBL
                        -isystem "${PICOMOS_PICOLIBC_STAGING}/usr/include"
                        -c -o "${_obj}" "${_src}"
                DEPENDS "${_src}" picolibc-mos ${_machine_extra_deps}
                COMMENT "picomos[${machine_name}]: compiling io/${_stem}.o")
        endforeach()
        add_custom_command(
            OUTPUT "${_libio}"
            COMMAND "${PICOMOS_MOS_AR}" rcs "${_libio}" ${_io_objs}
            DEPENDS ${_io_objs}
            COMMENT "picomos[${machine_name}]: linking libio.a")
        add_custom_target(${machine_name}-io ALL DEPENDS "${_libio}")
        install(FILES "${_libio}" DESTINATION "${_dest}")
    endif()

    # --- runner scripts + generated runners.cmake -------------------
    _picomos_emit_runners("${machine_name}" "${_stage_dir}" "${_dest}")

    # --- clang config file -----------------------------------------
    picomos_write_config(${machine_name}
        HAS_LINK "${_linker_parts}"
        HAS_CRT0 "${_crt_sources}"
        HAS_IO   "${_io_sources}"
        LINK_LIBS "${_link_libs}")
endfunction()

# ---------------------------------------------------------------------
# Emit the runners.cmake consumers read at build time. This file is the
# SDK ABI seen by PicomosApp.cmake — its shape must not drift.
# Also copy runner-*.lua / runner-*.py helpers from every ancestor dir.
# ---------------------------------------------------------------------

function(_picomos_emit_runners machine_name stage_dir dest)
    _picomos_ancestor_chain("${machine_name}" _chain)

    # Copy plugin scripts from every ancestor. Later-ancestor files (i.e.
    # the leaf machine's own) override same-basename earlier ones.
    set(_seen "")
    foreach(_a IN LISTS _chain)
        set(_ad "${_picomos_machine_${_a}_dir}")
        file(GLOB _scripts
             "${_ad}/runner-*.lua"
             "${_ad}/runner-*.py")
        foreach(_s IN LISTS _scripts)
            get_filename_component(_b "${_s}" NAME)
            if("${_b}" IN_LIST _seen)
                # Already got a later copy staged; skip.
                continue()
            endif()
            list(APPEND _seen "${_b}")
            file(COPY "${_s}" DESTINATION "${stage_dir}")
            install(FILES "${_s}" DESTINATION "${dest}")
        endforeach()
    endforeach()

    # runners.cmake is generated from picomos_emulator() calls. Iterate
    # only the leaf machine's emulators — emulator declarations are NOT
    # auto-inherited; each concrete machine declares its own.
    set(_emus "${_picomos_machine_${machine_name}_emulators}")
    if(NOT _emus)
        return()
    endif()

    set(_content
        "# Generated by picomos -- do not edit.\n"
        "# One picomos_register_runner() call per emulator declared\n"
        "# via picomos_emulator() in machines/${machine_name}/machine.cmake.\n\n")

    # First emulator's OUTPUT_EXT wins for PICOMOS_MACHINE_SUFFIX (matches
    # legacy runners.cmake behaviour where a single suffix was set at top).
    foreach(_e IN LISTS _emus)
        set(_ext "${_picomos_machine_${machine_name}_emulator_${_e}_output_ext}")
        if(_ext)
            list(APPEND _content
                "set(PICOMOS_MACHINE_SUFFIX \"${_ext}\")\n\n")
            break()
        endif()
    endforeach()

    foreach(_e IN LISTS _emus)
        set(_p _picomos_machine_${machine_name}_emulator_${_e})
        list(APPEND _content "picomos_register_runner(\n")
        list(APPEND _content "    NAME          ${_e}\n")
        if(${_p}_default)
            list(APPEND _content "    DEFAULT\n")
        endif()
        list(APPEND _content "    EXECUTABLE    ${${_p}_executable}\n")
        if(${_p}_env_override)
            list(APPEND _content "    ENV_OVERRIDE  ${${_p}_env_override}\n")
        endif()
        if(${_p}_plugin_script)
            list(APPEND _content "    PLUGIN_SCRIPT ${${_p}_plugin_script}\n")
        endif()
        list(APPEND _content "    ARGS\n")
        foreach(_arg IN LISTS ${_p}_args)
            list(APPEND _content "        ${_arg}\n")
        endforeach()
        list(APPEND _content ")\n\n")
    endforeach()

    set(_runners "${stage_dir}/runners.cmake")
    string(CONCAT _joined ${_content})
    file(WRITE "${_runners}" "${_joined}")
    install(FILES "${_runners}" DESTINATION "${dest}")
endfunction()
