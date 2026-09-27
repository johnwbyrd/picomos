# nes — Nintendo Entertainment System machine overlay

Builds picomos programs into iNES 2.0 (`.nes`) files that load in
MAME's `nes` driver (and any other emulator that reads iNES). Fixed
NROM-128 configuration for now: mapper 0, 16 KiB PRG-ROM at
`$C000-$FFFF`, 8 KiB CHR-RAM, horizontal mirroring.

## Runtime

- **Startup** — [`crt/startup.S`](crt/startup.S) is a from-scratch
  NES reset routine: disable interrupts, silence the PPU + APU, wait
  the canonical two VBlanks for the PPU to stabilise, clear internal
  RAM `$0000-$07FF`, initialise the llvm-mos soft stack, copy `.data`
  from PRG-ROM to internal RAM, and jump to `main()`. On `main()`
  return we spin — there is no clean shutdown on a real NES.
- **Load format** — `.nes` (iNES 2.0). The linker emits a 16-byte
  iNES header directly via ld.lld `BYTE()` directives followed by
  the full 16 KiB PRG-ROM via `FULL(prg_rom)`. No post-link objcopy
  step needed.
- **stdio** — no KERNAL, no monitor ROM. picolibc's `puts()` /
  `printf()` route through
  [`io/stdio_hook.c`](io/stdio_hook.c) → `nes_putc` →
  [`io/putchar.c`](io/putchar.c)'s `__putchar` → a store to the
  APU/IO MMIO register `$401B`. On real hardware that write is
  silently ignored; under an emulator, our runner picks it up via a
  memory tap.
- **stdin** — stubbed. NES has no default text input device.
  Programs that want stdin override `__getchar` with a controller-
  polling implementation.

## Memory map

| Range           | Use                                             |
|-----------------|-------------------------------------------------|
| `$0000-$001F`   | llvm-mos imaginary registers (`__rc0`-`__rc31`) |
| `$0020-$00FF`   | zero page globals                               |
| `$0100-$01FF`   | 6502 hardware stack                             |
| `$0200-$07FF`   | RAM: `.data`, `.bss`, llvm-mos soft stack       |
| `$2000-$2007`   | PPU registers (mirrored to `$3FFF`)             |
| `$4000-$4017`   | APU + I/O — includes `$401B` stdout side-channel |
| `$C000-$FFFF`   | PRG-ROM (16 KiB, NROM-128 mirrors `$8000-$BFFF`) |

`__stack = 0x0800`; llvm-mos soft stack grows downward.

Reset/NMI/IRQ vectors sit at `$FFFA-$FFFF`:

| Address | Vector |
|---------|--------|
| `$FFFA` | NMI (weak default `rti`, override with `nmi_handler`) |
| `$FFFC` | RESET (points at `_start`)                            |
| `$FFFE` | IRQ (weak default `rti`, override with `irq_handler`) |

## Testing

The runner's MAME lua plugin installs a memory write-tap on `$401B`
so every `__putchar` byte appears on the emulator subprocess's
stdout. `picomos_add_test(hello EXPECT "hello, mos")` matches
against that stream — no screen scraping, no font, no PPU parsing.

## Attribution

The iNES 2.0 header layout in [`linker/sections.ld`](linker/sections.ld)
and the `$401B` side-channel `__putchar` convention are structurally
cribbed from [llvm-mos-sdk](https://github.com/llvm-mos/llvm-mos-sdk)
(Apache-2.0 WITH LLVM-exception). No llvm-mos-sdk binary or source is
required at build or run time.

## Running

```sh
mos-clang --config=$PICOMOS/share/picomos/configs/picomos-nes.cfg \
          main.c -o hello.nes

mame nes -window -skip_gameinfo -cart hello.nes \
    -plugins -autoboot_script \
    $PICOMOS/mos-elf/usr/share/picomos/machines/nes/runner-mame.lua \
    -seconds_to_run 10
```

Or via CMake:

```cmake
picomos_add_executable(hello MACHINE nes SOURCES main.c)
picomos_run(hello TIMEOUT 10)
picomos_add_test(hello EXPECT "hello, mos" TIMEOUT 10)
```
