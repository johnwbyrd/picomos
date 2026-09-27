# Machine-specific examples

Home for demos that only make sense on a single target — the ones that
can't live under [`../programs/`](../programs/) because they touch
hardware, memory maps, or emulator behavior specific to one machine.

## When something belongs here

If a demo only compiles for one machine, or only makes sense on one
machine, it belongs here. Rough signals:

- **c64** — raster interrupts, sprite / VIC-II tricks, SID audio,
  direct screen-RAM writes, CIA timers, KERNAL calls beyond CHROUT.
- **nes** — NROM / mapper-specific tricks, PPU nametable / sprite
  setup, APU audio, controller polling.
- **zbc** — semihost-specific behavior (`sys_exit` handling, clean
  emulator termination), or anything exercising the ZBC's bespoke I/O.

Anything that only needs `<stdio.h>` / `<stdlib.h>` / `<string.h>` and
prints via `puts()` / `printf()` belongs under [`../programs/`](../programs/)
instead — the stdio path is uniform across every machine, so one source
fans out for free.

## Layout

```text
examples/machines/
├── c64/
│   └── <demo>/          one standalone consumer project per demo
├── nes/
│   └── <demo>/
└── zbc/
    └── <demo>/
```

Each `<demo>/` is a standalone project (its own `CMakeLists.txt` with
`find_package(Picomos)`) — same shape as anything under
[`../programs/`](../programs/), just without the machine fanout.

Nothing lives here yet. When the first per-machine demo lands, drop it
under the appropriate `c64/` / `nes/` / `zbc/` subdirectory.
