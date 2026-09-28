# cbm — Commodore 8-bit base machine

Abstract base inherited by every Commodore 8-bit machine (c64, and
future vic20 / plus4 / c128). Not built directly — it exists to be
inherited from and share code across the family.

## What lives here

All bits that CBM machines reuse verbatim:

- [`crt/basic_header.S`](crt/basic_header.S) — BASIC line-10 SYS launcher.
  The launcher fills in the SYS target address (`__do_init_stack`) at
  link time via `.mos_addr_asciz`, so the same source compiles for every
  CBM. Placement (`$0801` on c64, `$1001` on vic20 with default RAM, ...)
  is a per-machine linker-script concern.
- [`io/chrout.S`](io/chrout.S), [`io/chrin.S`](io/chrin.S) — thin
  `jsr $FFD2` / `jsr $FFE4` KERNAL wrappers. The KERNAL jump table
  addresses are stable across the family.
- [`io/stdio_hook.c`](io/stdio_hook.c) — picolibc `FDEV_SETUP_STREAM`
  installing CHROUT/GETIN as `stdin` / `stdout` / `stderr`, with the
  standard ASCII↔PETSCII line-terminator translation (`\n` → `\r` on
  output, `\r` → `\n` on input).
- [`runner-mame.lua`](runner-mame.lua) — MAME plugin: auto-types `RUN`
  into the KERNAL keyboard buffer (`$0277`, count at `$C6`) once BASIC
  reaches READY, and mirrors the byte written to `$FFD2` on every
  CHROUT invocation to the emulator subprocess's stdout so CTest can
  match on it.

## What a concrete CBM machine contributes

- `linker/memory.ld` — machine-specific memory map (BASIC ROM band,
  KERNAL band, RAM ranges).
- `linker/sections.ld` — section layout that places `.basic_header` at
  the machine's BASIC start address.
- `machine.cmake` — `picomos_machine(<name> INHERITS cbm ...)` +
  one `picomos_emulator(<name> mame ...)` declaration per supported
  emulator (mame, vice, ...).

If a concrete machine needs to override the shared runner-mame.lua or
stdio_hook.c, drop a same-basename file into its own dir — the
per-machine copy wins over the inherited one via `picomos_machine()`'s
child-overrides-parent auto-discovery rule.
