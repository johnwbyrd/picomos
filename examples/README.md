# picomos examples

Each subdirectory here is a **standalone project** that consumes an
already-installed picomos SDK. They are copied into
`<install>/share/picomos/examples/` at `cmake --install` time so users can
copy one out, tweak it, and build it.

They are **not** built as part of picomos's own build — that would defeat
the purpose of exercising the SDK from the outside.

## Two tiers

```text
examples/
├── programs/           portable — one source, fans out over every machine
│   ├── hello/          minimal puts(); ctest asserts "hello, mos"
│   └── malloc_free/    exercises picolibc malloc + free
└── <machine>/          (per-machine) — kept for now; slated to move under
                        examples/machines/<name>/ for target-only demos
                        (raster tricks, bank switching, semihost specifics).
```

The **programs/** tier is what a new user should copy — one `main.c`,
one `CMakeLists.txt`, and it builds `<name>-zbc`, `<name>-c64`,
`<name>-nes`, ... in a single configure. Restrict to a subset by
overriding e.g. `-D<NAME>_MACHINES=c64` at configure time.

Anything that genuinely can't be portable — a c64 sprite demo, an
NES bank-switching walkthrough, a zbc semihost `sys_exit` proof —
belongs in the per-machine tier instead.

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
cmake -B build -G Ninja -DPicomos_DIR=$PICOMOS/share/picomos/cmake
cmake --build build                              # builds every machine
cmake --build build --target run-hello-c64       # runs one under its emulator
ctest --test-dir build --output-on-failure       # runs every registered test
```

(each example ships a `CMakeLists.txt` using `find_package(Picomos)`).
