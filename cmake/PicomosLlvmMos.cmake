# Locate (or download) an llvm-mos toolchain and record the paths that
# other picomos build steps need.
#
# Three modes, in priority order:
#
#   1. -DPICOMOS_LLVM_MOS_ROOT=/path/to/installed/llvm-mos
#      Use the given tree directly. Nothing is fetched.
#
#   2. -DPICOMOS_LLVM_MOS_DOWNLOAD=<version-or-url>
#      Download a prebuilt llvm-mos for this host from the llvm-mos releases
#      page and extract it under ${CMAKE_BINARY_DIR}/llvm-mos-prebuilt/.
#      This is the workflow used by the release matrix.
#
#   3. (nothing)
#      Fall back to finding mos-clang on PATH.

set(PICOMOS_LLVM_MOS_DOWNLOAD "" CACHE STRING
    "URL of a prebuilt llvm-mos tarball for this host (or a version tag \
that expands to https://github.com/llvm-mos/llvm-mos/releases/download/<tag>/...) \
When set, downloaded + extracted; overrides PATH lookup.")

# -- Resolve the toolchain root ---------------------------------------------

if(PICOMOS_LLVM_MOS_ROOT)
    set(_mos_root "${PICOMOS_LLVM_MOS_ROOT}")

elseif(PICOMOS_LLVM_MOS_DOWNLOAD)
    # Map (host, url-or-tag) -> concrete download URL.
    if(PICOMOS_LLVM_MOS_DOWNLOAD MATCHES "^https?://")
        set(_url "${PICOMOS_LLVM_MOS_DOWNLOAD}")
    else()
        # Treat as a version tag. Asset naming per llvm-mos release conventions;
        # the exact filename is TODO once we pin an llvm-mos version and
        # confirm the release-asset scheme.
        if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
            set(_asset "llvm-mos-linux.tar.xz")
        elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
            set(_asset "llvm-mos-macos.tar.xz")
        elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
            set(_asset "llvm-mos-windows.zip")
        else()
            message(FATAL_ERROR
                "No known llvm-mos prebuilt for ${CMAKE_HOST_SYSTEM_NAME}. "
                "Pass PICOMOS_LLVM_MOS_DOWNLOAD as an explicit URL.")
        endif()
        set(_url "https://github.com/llvm-mos/llvm-mos/releases/download/${PICOMOS_LLVM_MOS_DOWNLOAD}/${_asset}")
    endif()

    set(_dl_dir "${CMAKE_BINARY_DIR}/llvm-mos-prebuilt")
    set(_dl_archive "${_dl_dir}/download.archive")

    if(NOT EXISTS "${_dl_dir}/bin/mos-clang" AND
       NOT EXISTS "${_dl_dir}/bin/mos-clang.exe")
        file(MAKE_DIRECTORY "${_dl_dir}")
        message(STATUS "picomos: downloading llvm-mos from ${_url}")
        file(DOWNLOAD "${_url}" "${_dl_archive}"
             SHOW_PROGRESS
             STATUS _dl_status)
        list(GET _dl_status 0 _dl_rc)
        if(NOT _dl_rc EQUAL 0)
            message(FATAL_ERROR
                "llvm-mos download failed (${_dl_status}) from ${_url}")
        endif()
        execute_process(
            COMMAND "${CMAKE_COMMAND}" -E tar xf "${_dl_archive}"
            WORKING_DIRECTORY "${_dl_dir}"
            RESULT_VARIABLE _rc)
        if(NOT _rc EQUAL 0)
            message(FATAL_ERROR "Extraction of ${_dl_archive} failed")
        endif()
        # llvm-mos releases typically wrap contents in a top-level dir;
        # if bin/ is not directly here, look one level down.
        if(NOT EXISTS "${_dl_dir}/bin")
            file(GLOB _sub "${_dl_dir}/*/bin")
            if(_sub)
                get_filename_component(_wrap "${_sub}" DIRECTORY)
                file(GLOB _entries "${_wrap}/*")
                foreach(_e IN LISTS _entries)
                    get_filename_component(_n "${_e}" NAME)
                    file(RENAME "${_e}" "${_dl_dir}/${_n}")
                endforeach()
                file(REMOVE_RECURSE "${_wrap}")
            endif()
        endif()
    endif()
    set(_mos_root "${_dl_dir}")

else()
    # PATH lookup only.
    set(_mos_root "")
endif()

# -- Locate the compiler + archiver ----------------------------------------

if(_mos_root)
    set(_hint HINTS "${_mos_root}/bin")
else()
    set(_hint HINTS ENV PATH)
endif()

find_program(PICOMOS_MOS_CLANG mos-clang REQUIRED ${_hint}
    DOC "llvm-mos clang driver")

get_filename_component(_mos_bin "${PICOMOS_MOS_CLANG}" DIRECTORY)
find_program(PICOMOS_MOS_AR llvm-ar REQUIRED
    HINTS "${_mos_bin}"
    DOC "llvm-ar (for building machine-overlay archives)")

# -- Locate libclang_rt.builtins.a for mos-unknown-unknown -----------------

execute_process(
    COMMAND "${PICOMOS_MOS_CLANG}" --print-libgcc-file-name
    OUTPUT_VARIABLE _libgcc_reported
    OUTPUT_STRIP_TRAILING_WHITESPACE
    RESULT_VARIABLE _rc)
if(NOT _rc EQUAL 0)
    message(FATAL_ERROR "mos-clang --print-libgcc-file-name failed")
endif()
get_filename_component(_clang_lib_parent "${_libgcc_reported}" DIRECTORY)
get_filename_component(_clang_lib_parent "${_clang_lib_parent}" DIRECTORY)

file(GLOB_RECURSE _librt_hits "${_clang_lib_parent}/*/libclang_rt.builtins.a")
if(NOT _librt_hits)
    message(FATAL_ERROR
        "Could not find libclang_rt.builtins.a under ${_clang_lib_parent}")
endif()
list(GET _librt_hits 0 _librt_first)
get_filename_component(PICOMOS_LIBRT_DIR "${_librt_first}" DIRECTORY CACHE)

# -- Expose llvm-mos install root for optional bundling --------------------

if(_mos_root)
    set(PICOMOS_LLVM_MOS_INSTALL "${_mos_root}" CACHE PATH "" FORCE)
endif()

message(STATUS "picomos: mos-clang    = ${PICOMOS_MOS_CLANG}")
message(STATUS "picomos: llvm-ar      = ${PICOMOS_MOS_AR}")
message(STATUS "picomos: libclang_rt  = ${PICOMOS_LIBRT_DIR}")
if(PICOMOS_LLVM_MOS_INSTALL)
    message(STATUS "picomos: llvm-mos     = ${PICOMOS_LLVM_MOS_INSTALL}")
endif()
