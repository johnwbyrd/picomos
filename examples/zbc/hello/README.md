# hello (zbc)

The smallest complete picomos example: prints one line via the ZBC
semihost device and exits.

## Build

Once the picomos CLI exists:

```sh
picomos build zbc hello
```

Under the hood, this links `main.c` against:

- `dist/picolibc/lib/libc.a`             (shared across all MOS machines)
- `dist/machines/zbc/crt0.o`             (ZBC-specific startup)
- `dist/machines/zbc/io.a`               (ZBC semihost backend)
- `dist/machines/zbc/link.ld`            (ZBC memory map)

## Run

```sh
../../../machines/zbc/run.sh hello.elf
```

Expected output: `hello, mos`
