# hello (nes)

Smallest complete picomos example for the NES. Uses picolibc's
`puts()` — routed by the nes machine overlay through `__putchar`,
which stores each byte to the `$401B` side-channel MMIO. The bundled
`runner-mame.lua` taps writes at `$401B` and mirrors them to the
emulator's stdout.

Terminal output (under MAME):

```
hello, mos
```

On a real NES this program is silent — writes to `$401B` are ignored
by the APU. Real-hardware output requires overriding `__putchar` with
a PPU-nametable or serial-cart implementation.

## Direct compiler

```sh
export PICOMOS=/opt/picomos           # wherever you installed picomos

mos-clang --config=$PICOMOS/share/picomos/configs/picomos-nes.cfg \
          main.c -o hello.nes

mame nes -window -skip_gameinfo -cart hello.nes \
    -plugins -autoboot_script \
    $PICOMOS/mos-elf/usr/share/picomos/machines/nes/runner-mame.lua \
    -seconds_to_run 10
```

## CMake

See [`CMakeLists.txt`](CMakeLists.txt) — uses `find_package(Picomos)`
and `picomos_run(hello)` / `picomos_add_test(hello ...)`.

```sh
cmake -B build -G Ninja \
    -DCMAKE_TOOLCHAIN_FILE=$PICOMOS/share/picomos/cmake/mos-toolchain.cmake \
    -DPicomos_DIR=$PICOMOS/share/picomos/cmake
cmake --build build                       # produces build/hello.nes
cmake --build build --target run-hello    # launches MAME on it
```

Override the MAME binary with `PICOMOS_MAME=/path/to/mame` in the
environment when configuring.
