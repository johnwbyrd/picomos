# ZBC

The ZBC ("Zero Byte Computer") is a minimal 6502 machine defined by the
MAME `zbcm6502` driver. picolibc uses it as the reference test target for
its MOS port because it exposes a simple semihost device suitable for
running the picolibc test suite.

## Memory map

| Range          | Size    | Purpose                           |
|----------------|---------|-----------------------------------|
| 0x0000-0x001F  | 32 B    | llvm-mos imaginary registers      |
| 0x0020-0x00FF  | 224 B   | Zero-page globals                 |
| 0x0100-0x01FF  | 256 B   | Hardware stack                    |
| 0x0200-0xFCDF  | ~63 KB  | Program (text+data+bss+softstack) |
| 0xFCE0-0xFCFF  | 32 B    | ZBC semihost device               |
| 0xFD00-0xFFF9  | ~758 B  | Reserved                          |
| 0xFFFA-0xFFFF  | 6 B     | NMI / RESET / IRQ vectors         |

## Running programs

Via a consumer CMake project:

```cmake
picomos_add_executable(hello MACHINE zbc SOURCES main.c)
picomos_run(hello TIMEOUT 5)
```

Then `cmake --build build --target run-hello` invokes MAME on the built
ELF. Override the MAME binary path with `PICOMOS_MAME=/path/to/mame`
in the environment.

Or invoke MAME directly:

```sh
mame zbcm6502 -window -skip_gameinfo \
    -elfload path/to/program.elf -seconds_to_run 5
```

Runner metadata (executable name, argv template) lives in
[runners.cmake](runners.cmake); no bash scripts.
