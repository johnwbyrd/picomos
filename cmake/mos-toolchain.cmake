# CMake toolchain file for picomos.
#
# Passed to consumer projects via:
#   cmake -B build -G Ninja \
#       -DCMAKE_TOOLCHAIN_FILE=$PICOMOS/share/picomos/cmake/mos-toolchain.cmake
#
# After installation this file lives at:
#   <picomos-root>/share/picomos/cmake/mos-toolchain.cmake
# so it can locate the shipped mos-clang under <picomos-root>/bin/ by
# walking up three levels from its own location. If PICOMOS_INSTALL_TOOLCHAIN
# was OFF for the SDK build (compiler not bundled), we fall back to PATH.

set(CMAKE_SYSTEM_NAME       Generic)
set(CMAKE_SYSTEM_PROCESSOR  mos)

# Locate the picomos root relative to this file. Layout:
#   <root>/share/picomos/cmake/mos-toolchain.cmake  <-- CMAKE_CURRENT_LIST_FILE
#   <root>/bin/mos-clang                            <-- what we're looking for
get_filename_component(_pt_dir  "${CMAKE_CURRENT_LIST_FILE}" DIRECTORY)
get_filename_component(_pt_root "${_pt_dir}/../../.." ABSOLUTE)

find_program(CMAKE_C_COMPILER   mos-clang
    HINTS "${_pt_root}/bin"
    NO_CMAKE_FIND_ROOT_PATH REQUIRED)
find_program(CMAKE_CXX_COMPILER mos-clang++
    HINTS "${_pt_root}/bin"
    NO_CMAKE_FIND_ROOT_PATH REQUIRED)
find_program(CMAKE_AR           llvm-ar
    HINTS "${_pt_root}/bin"
    NO_CMAKE_FIND_ROOT_PATH REQUIRED)

# llvm-mos is freestanding — CMake's default TRY_COMPILE builds an
# executable, which fails without a machine's link.ld. Test with a
# static library instead.
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
