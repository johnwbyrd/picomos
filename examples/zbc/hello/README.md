# hello (zbc)

Smallest complete picomos example — prints one line via the ZBC semihost
device and exits.

Two equivalent build workflows are shown below. Each produces the same
`hello.elf`; pick whichever fits your project.

## Direct compiler

```sh
export PICOMOS=/opt/picomos           # wherever you installed picomos

mos-clang --config=$PICOMOS/share/picomos/configs/picomos-zbc.cfg \
          main.c -o hello.elf

mame zbcm6502 -window -skip_gameinfo \
    -elfload hello.elf -seconds_to_run 5
```

Expected output on the host's stdout: `hello, mos`

## CMake

See [`CMakeLists.txt`](CMakeLists.txt) — uses `find_package(Picomos)`
plus `picomos_run(hello)` to add a `run-hello` target that launches
MAME automatically.

```sh
cmake -B build -G Ninja \
    -DCMAKE_TOOLCHAIN_FILE=$PICOMOS/share/picomos/cmake/mos-toolchain.cmake \
    -DPicomos_DIR=$PICOMOS/share/picomos/cmake
cmake --build build                  # produces build/hello.elf
cmake --build build --target run-hello   # invokes MAME on it
```

Override the MAME binary with `PICOMOS_MAME=/path/to/mame` in the
environment when configuring.

## Automated test

```sh
cmake --build build            # produces build/hello.elf
cd build && ctest --output-on-failure
```

CTest runs the same MAME invocation and asserts that "hello, mos"
appears in the semihost stdout stream. `zbc` needs no lua plugin —
the `zbcm6502` driver routes semihost writes directly to the
subprocess's stdout.
