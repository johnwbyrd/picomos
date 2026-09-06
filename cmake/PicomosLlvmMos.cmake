# Acquire an llvm-mos toolchain and record the paths that other picomos
# build steps need. Four modes, in priority order:
#
#   1. -DPICOMOS_LLVM_MOS_ROOT=/path/to/installed/llvm-mos
#      Use the given tree directly. Nothing is fetched. Typical when a
#      developer already has llvm-mos built for other reasons.
#
#   2. -DPICOMOS_LLVM_MOS_REF=<git-tag-or-sha>          (DEFAULT for CI)
#      Fetch llvm-mos source at the given ref and build it from source.
#      This is what a release build uses — slow (~30-60 min), but
#      reproducible and free of any external release-asset dependency.
#
#   3. -DPICOMOS_LLVM_MOS_DOWNLOAD=<version-or-url>     (LOCAL FAST-PATH)
#      Download a prebuilt llvm-mos for this host from the llvm-mos
#      releases page. Fast, but locks us to llvm-mos's release schedule
#      and asset-naming scheme.
#
#   4. (nothing) — fall back to finding mos-clang on PATH.
#
# Modes 1, 2, 3 all populate PICOMOS_LLVM_MOS_INSTALL so downstream
# bundling (PICOMOS_INSTALL_TOOLCHAIN) sees a single install tree
# regardless of how the toolchain got there.

set(PICOMOS_LLVM_MOS_REF "" CACHE STRING
    "llvm-mos git ref (tag, branch, or SHA) to build from source. \
Preferred over PICOMOS_LLVM_MOS_DOWNLOAD when reproducibility matters.")

set(PICOMOS_LLVM_MOS_DOWNLOAD "" CACHE STRING
    "URL of a prebuilt llvm-mos tarball for this host (or a release tag). \
Fast local-dev fast path; not used by the release workflow.")

set(PICOMOS_LLVM_MOS_REPOSITORY "https://github.com/llvm-mos/llvm-mos.git"
    CACHE STRING "llvm-mos source repository.")

# -- Resolve the toolchain root ---------------------------------------------

set(_mos_root "")

if(PICOMOS_LLVM_MOS_ROOT)
    set(_mos_root "${PICOMOS_LLVM_MOS_ROOT}")

elseif(PICOMOS_LLVM_MOS_REF)
    # -------- BUILD-FROM-SOURCE mode --------

    include(ExternalProject)
    set(_src_dir     "${CMAKE_BINARY_DIR}/llvm-mos-src")
    set(_build_dir   "${CMAKE_BINARY_DIR}/llvm-mos-build")
    set(_install_dir "${CMAKE_BINARY_DIR}/llvm-mos-install")

    # llvm-mos two-stage build:
    #   Stage 1: LLVM/clang/lld host tools (targets MOS backend)
    #   Stage 2: compiler-rt builtins for mos-unknown-unknown, built
    #            with the just-installed mos-clang.
    # llvm-mos publishes a top-level CMakeLists at llvm/ that drives
    # both stages when LLVM_ENABLE_RUNTIMES is set. Runtime settings
    # per llvm-mos docs (bootstrap doc in the llvm-mos repo).
    #
    # NOTE: the concrete cmake flags below need to be pinned against a
    # specific llvm-mos ref and verified end-to-end. The shape is right;
    # options may need adjustment (e.g. LLVM_MOS_RUNTIME_TARGETS names).

    ExternalProject_Add(llvm-mos
        GIT_REPOSITORY  "${PICOMOS_LLVM_MOS_REPOSITORY}"
        GIT_TAG         "${PICOMOS_LLVM_MOS_REF}"
        GIT_SHALLOW     TRUE
        SOURCE_DIR      "${_src_dir}"
        SOURCE_SUBDIR   llvm
        BINARY_DIR      "${_build_dir}"
        INSTALL_DIR     "${_install_dir}"
        CMAKE_CACHE_ARGS
            -DCMAKE_BUILD_TYPE:STRING=Release
            -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR>
            -DLLVM_TARGETS_TO_BUILD:STRING=
            -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD:STRING=MOS
            -DLLVM_ENABLE_PROJECTS:STRING=clang$<SEMICOLON>lld
            -DLLVM_ENABLE_RUNTIMES:STRING=compiler-rt
            -DLLVM_DEFAULT_TARGET_TRIPLE:STRING=mos-unknown-unknown
            -DLLVM_INCLUDE_TESTS:BOOL=OFF
            -DLLVM_INCLUDE_EXAMPLES:BOOL=OFF
            -DLLVM_INCLUDE_BENCHMARKS:BOOL=OFF
            -DLLVM_BUILD_TESTS:BOOL=OFF
            -DCLANG_DEFAULT_LINKER:STRING=lld
            # clang picks target/mode from argv[0]; without these links the
            # install has only `clang`, and every downstream picomos step
            # (picolibc cross-file, config templates, PICOMOS_MOS_CLANG)
            # looks for `mos-clang`.
            -DCLANG_LINKS_TO_CREATE:STRING=mos-clang$<SEMICOLON>mos-clang++$<SEMICOLON>mos-clang-cpp$<SEMICOLON>mos-unknown-unknown-clang$<SEMICOLON>mos-unknown-unknown-clang++
        BUILD_COMMAND
            ${CMAKE_COMMAND} --build <BINARY_DIR> --target install
        INSTALL_COMMAND ""    # install is folded into BUILD_COMMAND
        BUILD_ALWAYS FALSE
        # Big build: don't try to log every line, it just fills disk.
        LOG_DOWNLOAD    ON
        LOG_UPDATE      ON
        LOG_CONFIGURE   ON
        LOG_BUILD       ON
        LOG_MERGED_STDOUTERR ON
        LOG_OUTPUT_ON_FAILURE ON)

    set(_mos_root "${_install_dir}")
    set(_llvm_mos_built_here TRUE)

elseif(PICOMOS_LLVM_MOS_DOWNLOAD)
    # -------- DOWNLOAD-PREBUILT mode --------

    if(PICOMOS_LLVM_MOS_DOWNLOAD MATCHES "^https?://")
        set(_url "${PICOMOS_LLVM_MOS_DOWNLOAD}")
    else()
        # Treat as a release tag. Asset naming per llvm-mos convention;
        # verify against actual llvm-mos releases before relying on this.
        if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
            set(_asset "llvm-mos-linux.tar.xz")
        elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
            set(_asset "llvm-mos-macos.tar.xz")
        elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
            set(_asset "llvm-mos-windows.zip")
        else()
            message(FATAL_ERROR
                "No known llvm-mos prebuilt for ${CMAKE_HOST_SYSTEM_NAME}. "
                "Use PICOMOS_LLVM_MOS_REF to build from source instead.")
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
             SHOW_PROGRESS STATUS _dl_status)
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
        # llvm-mos releases often wrap contents in a top-level dir.
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

endif()

# -- Locate the compiler + archiver ----------------------------------------

if(_mos_root)
    set(_hint HINTS "${_mos_root}/bin")
else()
    set(_hint HINTS ENV PATH)
endif()

if(_llvm_mos_built_here)
    # mos-clang doesn't exist yet at configure time; it will after
    # `cmake --build`. Record the future path and defer to build-time
    # discovery for downstream custom_commands that depend on the
    # llvm-mos target.
    set(PICOMOS_MOS_CLANG "${_mos_root}/bin/mos-clang${CMAKE_EXECUTABLE_SUFFIX}"
        CACHE FILEPATH "" FORCE)
    set(PICOMOS_MOS_AR    "${_mos_root}/bin/llvm-ar${CMAKE_EXECUTABLE_SUFFIX}"
        CACHE FILEPATH "" FORCE)
    # Runtime lib path is also only real post-build.
    set(PICOMOS_LIBRT_DIR "${_mos_root}/lib/clang/24/lib/mos-unknown-unknown"
        CACHE PATH "" FORCE)
    message(STATUS "picomos: llvm-mos will be built from source at ${_mos_root}")
else()
    find_program(PICOMOS_MOS_CLANG mos-clang REQUIRED ${_hint}
        DOC "llvm-mos clang driver")
    get_filename_component(_mos_bin "${PICOMOS_MOS_CLANG}" DIRECTORY)
    find_program(PICOMOS_MOS_AR llvm-ar REQUIRED
        HINTS "${_mos_bin}"
        DOC "llvm-ar (for building machine-overlay archives)")

    # Locate libclang_rt.builtins.a for mos-unknown-unknown.
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
endif()

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
