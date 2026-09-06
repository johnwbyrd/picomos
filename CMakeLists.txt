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

set(PICOMOS_MACHINES "zbc" CACHE STRING
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
