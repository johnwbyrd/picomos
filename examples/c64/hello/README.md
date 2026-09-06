# hello (c64)

Smallest complete picomos example for the Commodore 64. Uses picolibc's
`puts()` — routed by the c64 machine overlay's stdio hook through
KERNAL CHROUT ($FFD2) — and returns to BASIC when `main()` exits.

Output on the C64 screen:

```
HELLO, MOS
```

(All-caps because the C64 boots in the shifted PETSCII character set;
lower-case ASCII letters map to that set's glyphs. Switch the C64 to
lower-case mode to see mixed case.)

## Direct compiler

```sh
export PICOMOS=/opt/picomos           # wherever you installed picomos

mos-clang --config=$PICOMOS/share/picomos/configs/picomos-c64.cfg \
          main.c -o hello.prg

mame c64 -window -skip_gameinfo -quik hello.prg \
    -plugins -autoboot_script \
    $PICOMOS/mos-elf/usr/share/picomos/machines/c64/runner-mame.lua \
    -seconds_to_run 10
```

The bundled `runner-mame.lua` plugin pokes RUN into the C64 keyboard
buffer once the KERNAL reaches READY, so the program starts without a
human typing it.

## CMake

See [`CMakeLists.txt`](CMakeLists.txt) — uses `find_package(Picomos)`
and `picomos_run(hello)` to add a `run-hello` target.

```sh
cmake -B build -G Ninja \
    -DCMAKE_TOOLCHAIN_FILE=$PICOMOS/share/picomos/cmake/mos-toolchain.cmake \
    -DPicomos_DIR=$PICOMOS/share/picomos/cmake
cmake --build build                       # produces build/hello.prg
cmake --build build --target run-hello    # invokes MAME on it
```

Override the MAME binary with `PICOMOS_MAME=/path/to/mame` in the
environment when configuring.

## Automated test

```sh
cmake --build build            # produces build/hello.prg
cd build && ctest --output-on-failure
```

The example's [CMakeLists.txt](CMakeLists.txt) calls
`picomos_add_test(hello EXPECT "hello, mos")` — CTest runs MAME with
the same runner config and asserts that "hello, mos" appears anywhere
in the CHROUT stream captured by [runner-mame.lua](../../../machines/c64/runner-mame.lua).
No screen scraping, no PETSCII translation: the tap fires the moment
the CPU executes `JSR $FFD2` and reads the byte straight from the
accumulator.
