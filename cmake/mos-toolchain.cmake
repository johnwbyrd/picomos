# CMake toolchain file for llvm-mos.
#
# Passed to user CMakeLists via:
#   cmake -B build -DCMAKE_TOOLCHAIN_FILE=<picomos>/cmake/mos-toolchain.cmake \
#         -DPICOMOS_ROOT=<picomos>/dist -DPICOMOS_MACHINE=zbc
#
# Also invoked internally when building the machine overlays and examples.

set(CMAKE_SYSTEM_NAME       Generic)
set(CMAKE_SYSTEM_PROCESSOR  mos)

# Callers must set PICOMOS_LLVM_MOS_ROOT, or mos-clang must be on PATH.
if(DEFINED PICOMOS_LLVM_MOS_ROOT AND PICOMOS_LLVM_MOS_ROOT)
    set(_mos_bin "${PICOMOS_LLVM_MOS_ROOT}/bin")
    set(CMAKE_C_COMPILER   "${_mos_bin}/mos-clang${CMAKE_EXECUTABLE_SUFFIX}")
    set(CMAKE_CXX_COMPILER "${_mos_bin}/mos-clang++${CMAKE_EXECUTABLE_SUFFIX}")
    set(CMAKE_AR           "${_mos_bin}/llvm-ar${CMAKE_EXECUTABLE_SUFFIX}")
else()
    find_program(CMAKE_C_COMPILER   mos-clang   REQUIRED)
    find_program(CMAKE_CXX_COMPILER mos-clang++ REQUIRED)
    find_program(CMAKE_AR           llvm-ar     REQUIRED)
endif()

# llvm-mos is a hosted-target-free freestanding toolchain.
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# Shared flags. Machine overlays add -T<machine>/link.ld and -Wl,--defsym= etc.
add_compile_options(
    -nostdlib
    -flto
    -Oz
    -Wno-tautological-compare
)
