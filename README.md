# picomos

A batteries-included cross-development SDK for MOS 6502-family targets.
One directory contains a full [llvm-mos](https://llvm-mos.org/) toolchain,
a [picolibc](https://github.com/picolibc/picolibc) sysroot, per-machine
overlays (linker script, startup, I/O), and clang config files. You invoke
the compiler normally:

```sh
mos-clang --config=$PICOMOS/share/picomos/configs/picomos-c64.cfg \
          hello.c -o hello.prg
```

No picomos-specific tools. No shell wrappers around clang. Nothing on your
PATH except what you extracted from the tarball.

> **Status: pre-release.** No downloadable tarballs are published yet. The
> release workflow that produces them lives in
> [.github/workflows/release.yml](.github/workflows/release.yml); until the
> first release lands, [build one yourself](#building-the-sdk-yourself).

## Supported hosts and targets

| Host                    | Bundle format         |
|-------------------------|-----------------------|
| Linux x86_64 / aarch64  | `.tar.xz`             |
| macOS arm64 / x86_64    | `.tar.xz`             |
| Windows x86_64          | `.zip`                |

| Target machine       | Emulator (runner)              | Output |
|----------------------|--------------------------------|--------|
| `zbc`                | MAME driver `zbcm6502`         | ELF    |
| `c64` — Commodore 64 | MAME driver `c64` (needs ROMs) | PRG    |

Each bundle is host-specific (compiler binaries) but contains all target
machines — one download builds for every machine picomos supports.

## Quick start

```sh
# 1. Download and extract the bundle for your host
curl -LO https://github.com/johnwbyrd/picomos/releases/download/vX.Y.Z/picomos-X.Y.Z-linux-x86_64.tar.xz
tar xf picomos-X.Y.Z-linux-x86_64.tar.xz
export PICOMOS=$PWD/picomos-X.Y.Z-linux-x86_64
export PATH=$PICOMOS/bin:$PATH

# 2. Write hello world
cat > hello.c <<'EOF'
#include <stdio.h>
int main(void) { puts("hello, mos"); return 0; }
EOF

# 3. Build for a machine (pick zbc or c64)
mos-clang --config=$PICOMOS/share/picomos/configs/picomos-zbc.cfg \
          hello.c -o hello.elf

# 4. Run under the machine's emulator (MAME must be installed separately)
mame zbcm6502 -window -skip_gameinfo \
    -elfload hello.elf -seconds_to_run 5
```

For zbc, output arrives on the host's stdout via the ZBC semihost device.
For c64, output shows in the MAME window — see [machines/c64/README.md](machines/c64/README.md)
for the exact MAME command (uses `-quik` plus a bundled lua plugin that
auto-types RUN once the KERNAL reaches READY).

If you're using CMake, the [CMake workflow](#cmake) below gives you a
`run-hello` build target that invokes MAME for you — no bash script, no
hand-typed emulator flags.

## What's in the SDK

```text
picomos-X.Y.Z-<host>/
├── bin/                       host toolchain — mos-clang, mos-clang++,
│                              clang, ld.lld, llvm-ar, llvm-nm, ...
├── lib/                       compiler-rt for mos-unknown-unknown +
│                              LLVM shared/dev libraries
├── mos-elf/                   THE SYSROOT
│   └── usr/
│       ├── include/           picolibc headers (stdio.h, stdlib.h, ...)
│       ├── lib/               picolibc libc.a, libm.a, crt0 variants
│       └── share/picomos/
│           └── machines/      per-machine overlay
│               ├── zbc/       link.ld, runners.cmake, manifest.toml
│               └── c64/       link.ld, crt0.o, libio.a, runners.cmake,
│                              runner-mame.lua, manifest.toml
└── share/picomos/
    ├── configs/               clang config files (--config= consumes)
    │   ├── picomos-zbc.cfg
    │   └── picomos-c64.cfg
    ├── cmake/                 PicomosConfig.cmake + mos-toolchain.cmake
    │                          for find_package(Picomos) / cross-compile
    └── examples/              copyable example projects (zbc/hello, c64/hello)
```

Every path in the `.cfg` files is relative to the config file's location
(via clang's `<CFGDIR>` macro), so you can extract the tarball to any path
— including USB sticks, network drives, or per-project directories — and
things still resolve.

## Building your program

Two workflows, both portable across Linux, macOS, Windows.

### Direct compiler

```sh
mos-clang --config=$PICOMOS/share/picomos/configs/picomos-<machine>.cfg \
          main.c -o hello.<ext>
```

Output extension depends on the machine: `.elf` for ZBC (bare ELF for the
semihost host loader), `.prg` for C64 (Commodore PRG with a BASIC `SYS`
launcher; the linker script emits raw PRG format directly — no `objcopy`
step needed).

### CMake

```cmake
cmake_minimum_required(VERSION 3.24)
project(hello LANGUAGES C)

find_package(Picomos REQUIRED)

picomos_add_executable(hello
    MACHINE c64            # or zbc
    SOURCES main.c)

# Optional: adds a `run-hello` target that launches MAME on the built
# binary. Cross-platform (pure CMake, no shell script). Override the
# emulator binary via the PICOMOS_MAME environment variable.
picomos_run(hello TIMEOUT 10)

# Automated check: `ctest` runs the same emulator invocation and
# passes if "hello, mos" appears in the captured output stream.
# Under c64, that stream is CHROUT bytes intercepted via a memory
# tap on $FFD2; under zbc, it's the semihost writes MAME's zbcm6502
# driver already routes to stdout. Either way, one API.
enable_testing()
picomos_add_test(hello EXPECT "hello, mos" TIMEOUT 10)
```

Configure with picomos's own toolchain file so CMake probes with
`mos-clang` instead of the host cc:

```sh
cmake -B build -G Ninja \
    -DCMAKE_TOOLCHAIN_FILE=$PICOMOS/share/picomos/cmake/mos-toolchain.cmake \
    -DPicomos_DIR=$PICOMOS/share/picomos/cmake
cmake --build build                       # builds hello.prg (or hello.elf)
cmake --build build --target run-hello    # launches MAME on it
```

`picomos_add_executable` expands to the same `--config=picomos-<machine>.cfg`
invocation as the direct-compiler workflow — the CMake path is purely
ergonomic (dependency tracking, cross-platform, and `run-hello` targets
without touching a shell).

Complete copyable projects live under `share/picomos/examples/`.

## Running under an emulator

The SDK does **not** bundle MAME — install it separately (`apt install mame`,
`brew install mame`, or your platform's equivalent).

- **ZBC (`zbcm6502` driver)** — no external ROMs required; the driver is
  self-contained. semihost stdio prints to the host terminal. Clean exit
  via `sys_exit`.
- **Commodore 64 (`c64` driver)** — requires Commodore's original
  BASIC/KERNAL/character ROMs in your MAME romset. MAME will report the
  exact filenames it looked for if any are missing. Output appears on the
  emulated C64 screen (not the host terminal).

Override the MAME binary with the `PICOMOS_MAME` environment variable
when using the CMake `picomos_run` target, or invoke MAME directly with
its full path if you prefer. Which emulator each machine supports is
declared in [`machines/<name>/runners.cmake`](machines/); the design
allows plural emulators per machine (`picomos_run(hello EMULATOR vice)`
is intended to work once vice runners land — currently only MAME is
verified).

## How it fits together

- **llvm-mos** — the compiler + linker. `mos-clang` is llvm-mos's clang
  driver with the `mos-unknown-unknown` triple baked in.
- **picolibc** — the C library. picomos uses the
  [johnwbyrd/picolibc](https://github.com/johnwbyrd/picolibc) fork on
  branch `feature/upstream-rebase-2026-09`; MOS support is not yet in
  upstream picolibc.
- **Machine overlays** — small per-machine bundles that plug into the
  picolibc-based sysroot. Each contributes some subset of a linker script,
  startup code, and I/O backend. See `mos-elf/usr/share/picomos/machines/<name>/README.md`
  for the anatomy of a specific overlay.
- **Clang config files** — one per machine. They set `--sysroot`,
  `-isystem`, `-L`, and any per-machine extras so end users just say
  `--config=picomos-<machine>.cfg`.

## Building the SDK yourself

Only interesting if you want to produce a new bundle or hack on picomos
itself. Requirements: CMake ≥ 3.24, Ninja, git, meson (for the picolibc
step; Linux only). Bring some patience — llvm-mos-from-source dominates
the build time.

```sh
git clone https://github.com/johnwbyrd/picomos
cd picomos
cmake -B build -G Ninja \
    -DPICOMOS_LLVM_MOS_REF=main \
    -DPICOMOS_INSTALL_TOOLCHAIN=ON
cmake --build build                              # ~1 hour on 16 cores
cmake --build build --target package             # produces picomos-*.tar.xz / .zip
```

Fast local iteration (skip llvm-mos build, reuse an existing tree):

```sh
cmake -B build -G Ninja \
    -DPICOMOS_LLVM_MOS_ROOT=/path/to/existing/llvm-mos/install \
    -DPICOMOS_MACHINES="zbc;c64"
cmake --build build
cmake --install build --prefix ./stage
```

Full CMake option reference lives at the top of
[CMakeLists.txt](CMakeLists.txt). The CI matrix that produces the shipped
bundles is [.github/workflows/release.yml](.github/workflows/release.yml).

### Adding a new machine

Copy `machines/zbc/` or `machines/c64/` as a starting point and adjust:

- `manifest.toml` — display name, CPU, emulator.
- `linker/memory.ld` + `linker/sections.ld` — memory map and any bespoke
  section layout.
- `crt/*.S` — machine startup (only if picolibc's shipped crt0 variants
  don't fit).
- `io/*.c` + `*.S` — machine I/O backend (only if you need one beyond
  picolibc's semihost).
- `run.sh` — emulator invocation.
- `CMakeLists.txt` — one call to `picomos_machine(<name> ...)`.

Add the machine to `PICOMOS_MACHINES` at configure time and it lands in
the SDK bundle alongside the existing targets.

## License

TBD. Likely BSD-3-Clause to match picolibc.
