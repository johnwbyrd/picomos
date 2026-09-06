# Helpers used by each machine's CMakeLists.txt.
#
# Usage inside machines/<name>/CMakeLists.txt:
#
#   picomos_machine(<name>
#       CRT_SOURCES   crt/init-stack.S crt/vectors.S
#       IO_SOURCES    io/io.c
#       LINKER_PARTS  linker/memory.ld linker/sections.ld
#       DEFINES       ZBC_SEMIHOST=1 STACK_SIZE=0x100)
#
# For each machine this produces (in the build tree, staged into the
# sysroot layout so downstream examples work in-tree):
#
#   <staging>/usr/share/picomos/machines/<name>/crt0.o
#   <staging>/usr/share/picomos/machines/<name>/libio.a       (if IO_SOURCES)
#   <staging>/usr/share/picomos/machines/<name>/link.ld
#   <staging>/usr/share/picomos/machines/<name>/run.sh        (if present)
#
# plus a clang config file consumed via `mos-clang --config=...`:
#
#   <bin>/staging/share/picomos/configs/picomos-<name>.cfg
#
# The `install()` rules place the same files under the final install prefix.

include(${CMAKE_CURRENT_LIST_DIR}/PicomosConfigWrite.cmake)

function(picomos_machine machine_name)
    cmake_parse_arguments(PARSE_ARGV 1 M
        ""
        ""
        "CRT_SOURCES;IO_SOURCES;LINKER_PARTS;DEFINES")

    # If llvm-mos is being built from source in this run, custom
    # commands that invoke mos-clang must wait for it.
    set(_machine_extra_deps "")
    if(TARGET llvm-mos)
        list(APPEND _machine_extra_deps llvm-mos)
    endif()

    # Where inside the sysroot this machine's overlay lives.
    set(_rel  "usr/share/picomos/machines/${machine_name}")
    set(_dest "${PICOMOS_SYSROOT_RELATIVE}/${_rel}")
    set(_stage_dir "${PICOMOS_PICOLIBC_STAGING}/${_rel}")
    file(MAKE_DIRECTORY "${_stage_dir}")

    # --- assembled linker script ---------------------------------------
    if(M_LINKER_PARTS)
        set(_link_ld "${_stage_dir}/link.ld")
        add_custom_command(
            OUTPUT "${_link_ld}"
            COMMAND ${CMAKE_COMMAND} -E cat ${M_LINKER_PARTS} > "${_link_ld}"
            DEPENDS ${M_LINKER_PARTS}
            WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
            COMMENT "picomos[${machine_name}]: assembling link.ld")
        add_custom_target(${machine_name}-link ALL DEPENDS "${_link_ld}")
        install(FILES "${_link_ld}" DESTINATION "${_dest}")

        # llvm-mos's clang driver unconditionally appends `-Tlink.ld` to
        # every link, resolved via the sysroot's -L paths. Install a copy
        # of this machine's link.ld at mos-elf/usr/lib/link.ld so that
        # driver-added -T finds it, and let the picomos-<machine>.cfg
        # config file skip its own explicit -T (avoids duplicate-INCLUDE
        # errors from having the same script pulled in twice).
        #
        # TODO(multi-machine): mos-elf/usr/lib/ is shared across all
        # machines in a single SDK bundle. Today with only zbc this works;
        # once a second machine lands, we need per-machine sysroots or a
        # config-file mechanism that overrides the driver's -Tlink.ld.
        install(FILES "${_link_ld}"
                DESTINATION "${PICOMOS_SYSROOT_RELATIVE}/usr/lib")
    endif()

    # --- crt0.o --------------------------------------------------------
    # Compiled with the external mos-clang (see PicomosLlvmMos.cmake).
    # We use a custom command instead of add_executable/add_library so we
    # can hand the resulting single .o directly to link.
    if(M_CRT_SOURCES)
        set(_crt0_o "${_stage_dir}/crt0.o")
        set(_abs_crt_sources "")
        foreach(_s IN LISTS M_CRT_SOURCES)
            list(APPEND _abs_crt_sources "${CMAKE_CURRENT_SOURCE_DIR}/${_s}")
        endforeach()
        set(_crt_defs "")
        foreach(_d IN LISTS M_DEFINES)
            list(APPEND _crt_defs "-D${_d}")
        endforeach()
        add_custom_command(
            OUTPUT "${_crt0_o}"
            COMMAND "${PICOMOS_MOS_CLANG}"
                    -nostdlib -Oz -flto
                    -isystem "${PICOMOS_PICOLIBC_STAGING}/usr/include"
                    ${_crt_defs}
                    -r -o "${_crt0_o}"
                    ${_abs_crt_sources}
            DEPENDS ${_abs_crt_sources} picolibc-mos ${_machine_extra_deps}
            COMMENT "picomos[${machine_name}]: compiling crt0.o")
        add_custom_target(${machine_name}-crt0 ALL DEPENDS "${_crt0_o}")
        install(FILES "${_crt0_o}" DESTINATION "${_dest}")
    endif()

    # --- libio.a (machine-specific I/O backend) ------------------------
    if(M_IO_SOURCES)
        set(_libio "${_stage_dir}/libio.a")
        set(_abs_io_sources "")
        foreach(_s IN LISTS M_IO_SOURCES)
            list(APPEND _abs_io_sources "${CMAKE_CURRENT_SOURCE_DIR}/${_s}")
        endforeach()
        # Build .o files first, then archive.
        set(_io_objs "")
        foreach(_src IN LISTS _abs_io_sources)
            get_filename_component(_stem "${_src}" NAME_WE)
            set(_obj "${_stage_dir}/io_${_stem}.o")
            list(APPEND _io_objs "${_obj}")
            add_custom_command(
                OUTPUT "${_obj}"
                COMMAND "${PICOMOS_MOS_CLANG}"
                        -nostdlib -Oz -flto
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

    # --- emulator runner ------------------------------------------------
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/run.sh")
        file(COPY "${CMAKE_CURRENT_SOURCE_DIR}/run.sh" DESTINATION "${_stage_dir}")
        install(PROGRAMS "${CMAKE_CURRENT_SOURCE_DIR}/run.sh" DESTINATION "${_dest}")
    endif()

    # --- clang config file --------------------------------------------
    # This is what makes picomos a "real SDK": users invoke
    #   mos-clang --config=picomos-<machine>.cfg foo.c
    # and get the right sysroot, crt0, linker script, and I/O lib.
    picomos_write_config(${machine_name}
        HAS_LINK "${M_LINKER_PARTS}"
        HAS_CRT0 "${M_CRT_SOURCES}"
        HAS_IO   "${M_IO_SOURCES}")
endfunction()
