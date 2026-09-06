# picomos — batteries-included SDK for MOS 6502-family targets.
#
# The output of `cmake --install` is a self-contained SDK tree:
#
#   <install-prefix>/
#     bin/                          host toolchain (llvm-mos)
#     mos-elf/usr/{include,lib}/    picolibc as the sysroot
#     mos-elf/usr/share/picomos/machines/<name>/
#                                   per-machine crt0.o, link.ld, libio.a, run.sh
#     share/picomos/configs/picomos-<name>.cfg
#                                   clang config file consumed via --config=
#     share/picomos/cmake/PicomosConfig.cmake
#                                   find_package(Picomos) support for downstream CMake
#
# See README.md for the user-facing workflows.

cmake_minimum_required(VERSION 3.24)
project(picomos LANGUAGES NONE)

# --- User-facing options ---------------------------------------------------

set(PICOMOS_LLVM_MOS_ROOT "" CACHE PATH
    "Path to an installed llvm-mos (bin/, lib/, ...). If empty, use PATH.")

set(PICOMOS_PICOLIBC_SOURCE "" CACHE PATH
    "Path to a picolibc source tree. If empty, FetchContent pulls a pinned ref.")

set(PICOMOS_PICOLIBC_REPOSITORY "https://github.com/johnwbyrd/picolibc.git"
    CACHE STRING
    "picolibc git repository to fetch when PICOMOS_PICOLIBC_SOURCE is empty. \
Defaults to the picomos-maintained fork with MOS support, since upstream \
picolibc has no MOS arch yet.")

set(PICOMOS_PICOLIBC_REF "feature/upstream-rebase-2026-09" CACHE STRING
    "picolibc git tag/branch/SHA to fetch when PICOMOS_PICOLIBC_SOURCE is empty.")

set(PICOMOS_MACHINES "zbc;c64" CACHE STRING
    "Semicolon-separated list of machines to build (subdirs of machines/).")

option(PICOMOS_INSTALL_TOOLCHAIN
    "Install the llvm-mos toolchain into <prefix>/bin/ (off during dev when \
llvm-mos lives elsewhere on disk; on for release bundles)." OFF)

# --- Toolchain discovery ---------------------------------------------------

include(cmake/PicomosLlvmMos.cmake)   # PICOMOS_MOS_CLANG, PICOMOS_MOS_AR, PICOMOS_LIBRT_DIR

# --- Build picolibc ONCE for MOS, install to sysroot ----------------------

include(cmake/PicomosPicolibc.cmake)  # sets PICOMOS_SYSROOT + PICOMOS_PICOLIBC_STAGING

# --- Build each enabled machine overlay -----------------------------------

foreach(machine IN LISTS PICOMOS_MACHINES)
    if(NOT EXISTS "${CMAKE_SOURCE_DIR}/machines/${machine}/CMakeLists.txt")
        message(FATAL_ERROR "No such machine: ${machine}")
    endif()
    add_subdirectory(machines/${machine})
endforeach()

# --- Install PicomosConfig.cmake + PicomosApp.cmake for find_package() ----

include(CMakePackageConfigHelpers)
configure_package_config_file(
    cmake/PicomosConfig.cmake.in
    "${CMAKE_BINARY_DIR}/PicomosConfig.cmake"
    INSTALL_DESTINATION share/picomos/cmake)
install(FILES
    "${CMAKE_BINARY_DIR}/PicomosConfig.cmake"
    cmake/PicomosApp.cmake
    DESTINATION share/picomos/cmake)

# --- Optionally bundle the llvm-mos toolchain into the SDK ---------------

if(PICOMOS_INSTALL_TOOLCHAIN)
    if(NOT PICOMOS_LLVM_MOS_INSTALL)
        message(FATAL_ERROR
            "PICOMOS_INSTALL_TOOLCHAIN requires an llvm-mos install "
            "(set PICOMOS_LLVM_MOS_ROOT or PICOMOS_LLVM_MOS_DOWNLOAD).")
    endif()
    install(DIRECTORY "${PICOMOS_LLVM_MOS_INSTALL}/bin/"
            DESTINATION bin USE_SOURCE_PERMISSIONS)
    install(DIRECTORY "${PICOMOS_LLVM_MOS_INSTALL}/lib/"
            DESTINATION lib USE_SOURCE_PERMISSIONS)
endif()

# --- Examples are consumed OUT-OF-TREE against the installed SDK ---------
# They are NOT built here; see examples/README.md.
install(DIRECTORY examples/ DESTINATION share/picomos/examples
        PATTERN "build" EXCLUDE
        PATTERN ".git*" EXCLUDE)

# --- Packaging via CPack --------------------------------------------------
# `cmake --build build --target package` produces a single archive of
# everything cmake --install would place under the prefix:
#
#   Linux/macOS -> picomos-<version>-<host>.tar.xz  (CPack TXZ generator)
#   Windows     -> picomos-<version>-<host>.zip     (CPack ZIP generator)
#
# The archive is genuinely batteries-included IFF -DPICOMOS_INSTALL_TOOLCHAIN=ON
# was passed at configure time (otherwise bin/ is empty and users would still
# need llvm-mos on PATH). Both generators are libarchive-backed and work on
# every host — Windows tar.xz support is limited enough that we ship .zip
# there instead of forcing users onto 7-Zip.

set(PICOMOS_VERSION "0.1.0"
    CACHE STRING "Version stamp embedded in the release archive filename.")

set(PICOMOS_HOST_LABEL "" CACHE STRING
    "Explicit host label for the release archive filename (e.g. \
'linux-x86_64', 'macos-arm64', 'windows-x86_64'). Overrides auto-detection \
from CMAKE_HOST_SYSTEM_NAME / _PROCESSOR — CI passes this so bundles are \
named identically across runners regardless of local naming quirks like \
Windows's AMD64 vs x86_64.")

set(CPACK_PACKAGE_NAME              "picomos")
set(CPACK_PACKAGE_VERSION           "${PICOMOS_VERSION}")
set(CPACK_PACKAGE_VENDOR            "picomos")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY
    "Batteries-included cross-development SDK for MOS 6502-family targets")

# Host label mirrors the release workflow's matrix.host: linux-x86_64,
# macos-arm64, windows-x86_64, etc.
if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
    set(CPACK_GENERATOR "TXZ")
    set(_picomos_host_os "linux")
elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
    set(CPACK_GENERATOR "TXZ")
    set(_picomos_host_os "macos")
elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
    set(CPACK_GENERATOR "ZIP")
    set(_picomos_host_os "windows")
else()
    set(CPACK_GENERATOR "TXZ")
    set(_picomos_host_os "${CMAKE_HOST_SYSTEM_NAME}")
    string(TOLOWER "${_picomos_host_os}" _picomos_host_os)
endif()
string(TOLOWER "${CMAKE_HOST_SYSTEM_PROCESSOR}" _picomos_host_arch)
if(PICOMOS_HOST_LABEL)
    set(CPACK_PACKAGE_FILE_NAME
        "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}-${PICOMOS_HOST_LABEL}")
else()
    set(CPACK_PACKAGE_FILE_NAME
        "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}-${_picomos_host_os}-${_picomos_host_arch}")
endif()

# CPack's default install-inside-archive path prefixes every file with
# a versioned dir — good, so `tar xf picomos-*.tar.xz` unpacks into a
# single self-contained top-level directory.
set(CPACK_PACKAGE_INSTALL_DIRECTORY "picomos-${CPACK_PACKAGE_VERSION}")

# Skip CPack's boilerplate license/README prompts.
set(CPACK_MONOLITHIC_INSTALL ON)

include(CPack)
