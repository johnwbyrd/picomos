# Machines

Each subdirectory here is a **machine overlay** — the pieces of a MOS 6502
target that vary from one machine to the next. picolibc's `libc.a` and
`libm.a` are built once for the whole MOS architecture; a machine
directory contributes only what the C library can't know:

- Where memory lives (linker script)
- What runs before `main` (crt0)
- How I/O reaches the outside world (semihost, KERNAL, memory-mapped, ...)
- How to launch a build in an emulator

## Directory contract

```text
machines/<name>/
  manifest.toml       # metadata: display name, CPU, memory summary, emulator
  linker/             # linker script fragments -> assembled into <name>.ld
    memory.ld
    regs.ld
    sections.ld
  crt/                # startup sources -> compiled into crt0.o per machine
    init-stack.S
    vectors.S
  io/                 # machine-specific I/O implementation (optional)
    io.c
  run.sh              # emulator invocation: `run.sh <elf-path>`
  README.md           # user-facing notes: memory map, quirks, limits
```

The `manifest.toml` is the source of truth for CI and the picomos CLI;
everything else is referenced from there.

## Adding a new machine

1. Copy `_template/` (TBD) to `machines/<your-machine>/`.
2. Fill in `manifest.toml`.
3. Provide `linker/*.ld` for your memory map.
4. Provide `crt/*.S` if your machine needs special startup (most do).
5. Provide `io/*.c` if your machine talks to the outside world through
   something other than the default (semihost, none, etc.).
6. Provide `run.sh` that launches your emulator with the given ELF.
7. Add an example under `examples/<your-machine>/hello/` that builds and
   runs.
8. Open a PR.

CI will link the hello example against the shared picolibc + your machine
overlay and run it under your emulator on every push.
