# picomos examples

Each subdirectory here is a **standalone project** that consumes an
already-installed picomos SDK. They are copied into
`<install>/share/picomos/examples/` at `cmake --install` time so users can
copy one out, tweak it, and build it.

They are **not** built as part of picomos's own build — that would defeat
the purpose of exercising the SDK from the outside.

## Building any example (once picomos is installed)

Either of these works — pick the one that fits your workflow. Both are
portable to Linux, macOS, and Windows.

### Direct compiler

```sh
mos-clang --config=$PICOMOS/share/picomos/configs/picomos-zbc.cfg \
          main.c -o hello.elf
```

### CMake

```sh
cmake -B build -DPicomos_DIR=$PICOMOS/share/picomos/cmake
cmake --build build
```

(each example ships a `CMakeLists.txt` using `find_package(Picomos)`).
