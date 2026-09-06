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

```
./run.sh path/to/program.elf
```

Uses `mame zbcm6502 -elfload <elf> -seconds_to_run 5`. All programs are
expected to complete within 5 seconds of emulated wall time.
