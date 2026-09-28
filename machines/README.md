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
  machine.cmake       # single source of truth — picomos_machine() +
                      # picomos_emulator() declarations
  linker/             # linker script fragments -> assembled into link.ld
    memory.ld
    sections.ld
  crt/                # startup sources -> compiled into crt0.o (optional)
    startup.S
  io/                 # machine-specific I/O implementation (optional)
    stdio_hook.c
  runner-mame.lua     # optional MAME Lua plugin, referenced from
                      # picomos_emulator() via PLUGIN_SCRIPT
  README.md           # user-facing notes: memory map, quirks, limits
```

`machine.cmake` is the only file with load-bearing content; `crt/`,
`io/`, `linker/` are **auto-discovered** by `picomos_machine()` — drop
`*.c` / `*.S` under `crt/` or `io/` and they build. `linker/*.ld` gets
concatenated into the machine's link script in filename order.

## Inheritance

A machine can inherit from another via `INHERITS <parent>` in its
`picomos_machine()` call. The parent is typically an **abstract** base —
a machine dir whose `machine.cmake` uses the `ABSTRACT` keyword and is
never built on its own — that provides shared sources for a family.

Working example: [`cbm/`](cbm/) is an abstract Commodore 8-bit base
that ships `basic_header.S`, KERNAL wrappers (`chrout.S`, `chrin.S`),
picolibc PETSCII stdio hook, and MAME's auto-RUN Lua plugin. [`c64/`](c64/)
inherits from it and contributes only c64-specific linker scripts and
its `picomos_emulator(c64 mame ...)` declaration.

Inheritance rules:

- Sources under the child's `crt/`, `io/`, `linker/` are combined with
  those of every ancestor; child files override same-basename ancestor
  files.
- Metadata (`CPU`, `ENDIANNESS`) is inherited if unset in the child.
- `EXCLUDE_SOURCES <basename>...` on the child drops specific ancestor
  files from the merged set.
- Emulator declarations are **not** auto-inherited — each concrete
  machine declares its own `picomos_emulator()` calls.

## Adding a new machine

1. Create `machines/<your-machine>/machine.cmake`. Start from
   [`zbc/machine.cmake`](zbc/machine.cmake) (standalone) or
   [`c64/machine.cmake`](c64/machine.cmake) (inherits `cbm`).
2. Fill in `picomos_machine(<name> DISPLAY_NAME ... MEMORY_MAP ...)`.
3. Provide `linker/*.ld` for your memory map.
4. Provide `crt/*.S` if your machine needs special startup (most do).
5. Provide `io/*.c` / `io/*.S` if your machine talks to the outside
   world through something other than the default (semihost, none, etc.).
6. Declare one or more emulators with
   `picomos_emulator(<name> <emul> ARGS ...)`. The `ARGS` list uses
   `{PROGRAM}`, `{TIMEOUT}`, `{PLUGIN_SCRIPT}` tokens that
   `picomos_run()` substitutes at build time.
7. No per-machine hello is required — the portable
   [`examples/programs/hello/`](../examples/programs/hello/) fans out
   over every machine the SDK ships (via `PICOMOS_MACHINES` in
   `PicomosConfig.cmake`). Add a machine-specific demo under
   [`examples/machines/<your-machine>/`](../examples/machines/) only
   if it needs something a portable `puts()` can't express (raster
   interrupts, mapper tricks, semihost-specific behavior).
8. Open a PR.

CI links the portable examples against the shared picolibc + your machine
overlay and runs them under your emulator on every push — no per-machine
example needed for hello-world coverage.
