# c64 — Commodore 64 machine overlay

Builds picomos programs into `.prg` files loadable by MAME's `c64`
driver, VICE, or a real Commodore 64.

## Runtime

- **Startup** — picolibc's machine-agnostic `libcrt0-minimal.a`:
  sets the llvm-mos soft stack, zeroes BSS, copies `.data`, calls
  `main()`. When `main()` returns, `_start`'s `rts` transfers control
  back to the BASIC interpreter.
- **Load format** — the linker emits a Commodore PRG image directly
  via `OUTPUT_FORMAT { SHORT(ORIGIN(ram)) TRIM(ram) }` (llvm-mos
  extensions). First two bytes are the load address ($0801); the rest
  is the trimmed image. No post-link objcopy needed.
- **Boot stub** — [crt/basic_header.S](crt/basic_header.S) is a
  BASIC line `10 SYS <_start>` at $0801 so a plain `RUN` transfers
  control to picolibc's `_start`.
- **I/O** — [io/chrout.S](io/chrout.S) wraps KERNAL CHROUT ($FFD2),
  [io/chrin.S](io/chrin.S) wraps KERNAL GETIN ($FFE4), and
  [io/stdio_hook.c](io/stdio_hook.c) installs both as the `put` and
  `get` hooks of picolibc's stdout/stderr/stdin. BASIC and KERNAL ROMs
  stay mapped so those KERNAL entries remain live.

## Memory map

| Range           | Use                                           |
|-----------------|-----------------------------------------------|
| `$0000-$0001`   | 6510 CPU port (memory-banking control)        |
| `$0002-$001F`   | llvm-mos imaginary registers (`__rc0`-`__rc30`) |
| `$0100-$01FF`   | 6502 hardware stack                           |
| `$0400-$07FF`   | VIC-II default screen memory                  |
| `$0801-$9FFF`   | **program image** — code, rodata, data, bss   |
| `$A000-$BFFF`   | BASIC ROM (mapped)                            |
| `$D000-$DFFF`   | VIC-II / SID / CIA I/O                        |
| `$E000-$FFFF`   | KERNAL ROM (contains CHROUT at `$FFD2`)       |

`__stack = 0xA000`; llvm-mos software stack grows downward from there.

## Attribution

The BASIC-header structure ([crt/basic_header.S](crt/basic_header.S)) is
structurally cribbed from the corresponding file in
[llvm-mos-sdk](https://github.com/llvm-mos/llvm-mos-sdk)
(Apache-2.0 WITH LLVM-exception). No llvm-mos-sdk binary or source is
required at build or run time.

## Running

Via a consumer CMake project (see the portable
[`examples/programs/hello`](../../examples/programs/hello/), which fans
out over every machine including c64):

```cmake
picomos_add_executable(hello-c64 MACHINE c64 SOURCES main.c)
picomos_run(hello-c64 TIMEOUT 10)
```

`cmake --build build --target run-hello-c64` invokes MAME on the built PRG.
The bundled [runner-mame.lua](runner-mame.lua) plugin auto-types RUN
into the C64 keyboard buffer after boot, so the program starts without
user intervention.

Or invoke MAME directly:

```sh
mos-clang --config=$PICOMOS/share/picomos/configs/picomos-c64.cfg \
          main.c -o hello.prg
mame c64 -window -skip_gameinfo -quik hello.prg \
    -plugins -autoboot_script \
    $PICOMOS/mos-elf/usr/share/picomos/machines/c64/runner-mame.lua \
    -seconds_to_run 10
```

Runner metadata (executable name, argv template, plugin script) lives
in [runners.cmake](runners.cmake); no bash scripts.
