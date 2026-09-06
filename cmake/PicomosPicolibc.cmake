# Provide picolibc's built MOS artifacts (headers + libc.a + libm.a)
# in the picomos sysroot layout.
#
# Two acquisition modes:
#
#   1. PREBUILT  (default in the release workflow)
#      -DPICOMOS_PICOLIBC_PREBUILT=<file-or-url>
#      Downloads (or copies) a picolibc-mos tarball already built on Linux
#      and extracts it into the staging sysroot. NO meson runs on this host.
#
#   2. BUILD-FROM-SOURCE  (default when developing)
#      -DPICOMOS_PICOLIBC_SOURCE=<path>  OR  auto-fetched via PICOMOS_PICOLIBC_REF
#      Invokes meson via ExternalProject and installs into the staging
#      sysroot. Requires meson + ninja on the build host; only supported
#      on Linux (macOS best-effort, Windows unsupported by picolibc CI).
#
# Both modes end up with identical contents in
#   ${CMAKE_BINARY_DIR}/staging/mos-elf/usr/{include,lib}/
# and identical install() rules -> <prefix>/mos-elf/usr/{include,lib}/.

set(PICOMOS_PICOLIBC_PREBUILT "" CACHE STRING
    "Path or URL to a prebuilt picolibc-mos tarball. When set, skips \
building picolibc from source. Format: .tar.xz containing usr/include/... \
and usr/lib/...")

set(PICOMOS_SYSROOT_RELATIVE "mos-elf")
set(PICOMOS_SYSROOT          "${CMAKE_INSTALL_PREFIX}/${PICOMOS_SYSROOT_RELATIVE}"
    CACHE PATH "" FORCE)
set(_staging "${CMAKE_BINARY_DIR}/staging/${PICOMOS_SYSROOT_RELATIVE}")
set(PICOMOS_PICOLIBC_STAGING "${_staging}" CACHE PATH "" FORCE)

if(PICOMOS_PICOLIBC_PREBUILT)

    # -------------------- PREBUILT MODE -----------------------------------

    message(STATUS "picomos: using prebuilt picolibc-mos = ${PICOMOS_PICOLIBC_PREBUILT}")

    set(_tarball "${CMAKE_BINARY_DIR}/picolibc-mos-prebuilt.tar.xz")

    if(PICOMOS_PICOLIBC_PREBUILT MATCHES "^https?://")
        file(DOWNLOAD "${PICOMOS_PICOLIBC_PREBUILT}" "${_tarball}"
             SHOW_PROGRESS
             STATUS _dl_status)
        list(GET _dl_status 0 _dl_rc)
        if(NOT _dl_rc EQUAL 0)
            message(FATAL_ERROR
                "Download of ${PICOMOS_PICOLIBC_PREBUILT} failed: ${_dl_status}")
        endif()
    else()
        # Local file path.
        if(NOT EXISTS "${PICOMOS_PICOLIBC_PREBUILT}")
            message(FATAL_ERROR
                "PICOMOS_PICOLIBC_PREBUILT does not exist: ${PICOMOS_PICOLIBC_PREBUILT}")
        endif()
        set(_tarball "${PICOMOS_PICOLIBC_PREBUILT}")
    endif()

    # Extract into the staging sysroot. The tarball is expected to contain
    # usr/include/... and usr/lib/... at its root.
    file(MAKE_DIRECTORY "${_staging}")
    add_custom_target(picolibc-mos ALL
        COMMAND ${CMAKE_COMMAND} -E tar xf "${_tarball}"
        WORKING_DIRECTORY "${_staging}"
        BYPRODUCTS "${_staging}/usr/include" "${_staging}/usr/lib"
        COMMENT "picomos: extracting prebuilt picolibc-mos")

else()

    # ----------------- BUILD-FROM-SOURCE MODE ----------------------------

    if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
        message(FATAL_ERROR
            "Building picolibc from source is not supported on Windows. "
            "Set PICOMOS_PICOLIBC_PREBUILT to a tarball produced on Linux.")
    elseif(NOT CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
        message(WARNING
            "Building picolibc from source on ${CMAKE_HOST_SYSTEM_NAME} is "
            "not tested. Prefer PICOMOS_PICOLIBC_PREBUILT.")
    endif()

    include(ExternalProject)
    include(FetchContent)

    find_program(MESON_EXE meson REQUIRED)
    find_program(NINJA_EXE ninja REQUIRED)

    if(PICOMOS_PICOLIBC_SOURCE)
        set(_picolibc_src "${PICOMOS_PICOLIBC_SOURCE}")
    else()
        FetchContent_Declare(picolibc
            GIT_REPOSITORY https://github.com/picolibc/picolibc.git
            GIT_TAG        ${PICOMOS_PICOLIBC_REF}
            GIT_SHALLOW    TRUE)
        FetchContent_Populate(picolibc)
        set(_picolibc_src "${picolibc_SOURCE_DIR}")
    endif()

    set(_cross_file "${CMAKE_BINARY_DIR}/picolibc-mos-generic.cross")
    configure_file(
        "${CMAKE_SOURCE_DIR}/cmake/picolibc-mos-generic.cross.in"
        "${_cross_file}"
        @ONLY)

    # If llvm-mos is being built from source in this same CMake run,
    # picolibc must wait for it. TARGET_EXISTS check avoids adding a
    # dependency on a target that isn't defined (llvm-mos supplied
    # externally or via prebuilt).
    set(_picolibc_depends "")
    if(TARGET llvm-mos)
        list(APPEND _picolibc_depends DEPENDS llvm-mos)
    endif()

    ExternalProject_Add(picolibc-mos
        SOURCE_DIR      "${_picolibc_src}"
        BINARY_DIR      "${CMAKE_BINARY_DIR}/picolibc-build"
        CONFIGURE_COMMAND
            ${MESON_EXE} setup --reconfigure
                --cross-file "${_cross_file}"
                --prefix /usr
                -Dtests=false
                -Dmultilib=false
                <BINARY_DIR> <SOURCE_DIR>
        BUILD_COMMAND
            ${NINJA_EXE} -C <BINARY_DIR>
        INSTALL_COMMAND
            ${CMAKE_COMMAND} -E env DESTDIR=${_staging}
                ${MESON_EXE} install -C <BINARY_DIR> --no-rebuild
        BUILD_ALWAYS FALSE
        ${_picolibc_depends})

    # For the release workflow: also produce a tarball of the built sysroot
    # so Job B on the non-Linux hosts can consume it via prebuilt mode.
    add_custom_target(picolibc-mos-tarball
        COMMAND ${CMAKE_COMMAND} -E chdir "${_staging}"
                ${CMAKE_COMMAND} -E tar cJf
                    "${CMAKE_BINARY_DIR}/picolibc-mos.tar.xz" usr
        DEPENDS picolibc-mos
        COMMENT "picomos: packaging picolibc-mos.tar.xz for reuse")

endif()

# Install picolibc into the real sysroot at `cmake --install` time.
install(DIRECTORY "${_staging}/usr/"
        DESTINATION "${PICOMOS_SYSROOT_RELATIVE}/usr"
        USE_SOURCE_PERMISSIONS)
