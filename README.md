# picomos

A batteries-included SDK for building software targeting MOS 6502-family
machines with the [llvm-mos](https://llvm-mos.org/) toolchain and
[picolibc](https://github.com/picolibc/picolibc).

**Status:** early scaffolding. Nothing here works yet.

## What this is

picomos bundles, per host OS:

- **llvm-mos** — clang/lld built with the MOS backend
- **picolibc** — C library, prebuilt **once** for the MOS architecture
  (`libc.a`, `libm.a`, arch-specific startup fragments — shared by every
  supported machine)
- **Machine overlays** — the bits that actually differ per target machine:
  linker script, `crt0.o`, machine-specific I/O backend, emulator glue
  (Commodore 64, NES, Apple II, ZBC/MAME, ...)
- **Examples** — a working hello-world per machine

The goal is: install picomos, pick a machine, `picomos build hello`, run it
in an emulator. No hand-configuring cross files, no chasing toolchain
revisions, no assembling the linker script yourself.

## Build model

The C library is architecture-level, not machine-level. picolibc's
`libc.a` doesn't know or care whether it's ending up on a Commodore 64 or
a NES — that's decided at final link time by the machine's linker script
and `crt0.o`. picomos reflects this:

```text
                  built once per release
  ┌────────────────────────────────────────────┐
  │  llvm-mos toolchain (per host OS)          │
  │  picolibc for MOS: libc.a, libm.a,         │
  │    arch-specific startup fragments         │
  └────────────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        ▼                 ▼                 ▼
    machines/c64      machines/nes      machines/zbc
    linker.ld         linker.ld         linker.ld
    crt0.o            crt0.o            crt0.o
    kernal_io.o       null_io.o         zbc_io.o
    vice runner       mesen runner      mame runner
```

## What this is NOT

- **A replacement for llvm-mos or picolibc.** Upstream fixes go upstream.
  picomos just ships known-good combinations.
- **A build environment.** picomos runs your compiled programs; it does not
  compile itself in-place. Prebuilt artifacts are published per release.

## Supported host OSes

- Linux (x86_64, aarch64)
- macOS (arm64, x86_64)
- Windows (x86_64)

Host binaries are produced by a matrix build on GitHub Actions, one runner
per host. The MOS-target artifacts (picolibc, examples) are host-independent
and built once on Linux.

## Layout

```text
picolibc/       # pinned picolibc source (submodule or fetched at build time)

machines/       # per-machine overlays
  zbc/          # ZBC (MAME zbcm6502)
    manifest.toml
    linker/     # memory.ld, sections.ld, ...
    crt/        # startup sources compiled into crt0.o per machine
    io/         # machine-specific I/O backend (semihost, KERNAL, ...)
    run.sh      # emulator invocation
  c64/          # (planned)
  nes/          # (planned)
  apple2/       # (planned)

examples/       # example programs per machine
  zbc/hello/
  ...

scripts/
  build-picolibc.sh    # builds picolibc ONCE for MOS -> dist/picolibc/
  build-machine.sh     # per-machine: linker + crt0 + io  -> dist/machines/<m>/
  build-example.sh     # links user program against picolibc + machine overlay
  bootstrap.sh         # end-user installer (fetches release artifact)

docs/           # quickstart, machine notes, contribution guide

.github/workflows/  # matrix CI producing per-host release bundles
```

## License

TBD. Likely BSD-3-Clause to match picolibc.
