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
$PICOMOS/mos-elf/usr/share/picomos/machines/c64/run.sh hello.prg
```

## CMake

See [`CMakeLists.txt`](CMakeLists.txt) — uses `find_package(Picomos)`.

```sh
cmake -B build -G Ninja -DPicomos_DIR=/opt/picomos/share/picomos/cmake
cmake --build build
```
