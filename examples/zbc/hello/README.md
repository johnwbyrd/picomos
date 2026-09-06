# hello (zbc)

Smallest complete picomos example — prints one line via the ZBC semihost
device and exits.

Two equivalent build workflows are shown below. Each one produces the
same `hello.elf`; pick whichever fits your project.

## Direct compiler

```sh
export PICOMOS=/opt/picomos           # wherever you installed picomos
mos-clang --config=$PICOMOS/share/picomos/configs/picomos-zbc.cfg \
          main.c -o hello.elf
$PICOMOS/mos-elf/usr/share/picomos/machines/zbc/run.sh hello.elf
```

Expected output: `hello, mos`

## CMake

See [`CMakeLists.txt`](CMakeLists.txt) — uses `find_package(Picomos)`.

```sh
cmake -B build -DPicomos_DIR=/opt/picomos/share/picomos/cmake
cmake --build build
```
