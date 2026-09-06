# picomos

A batteries-included cross-development SDK for building software targeting
MOS 6502-family machines with the [llvm-mos](https://llvm-mos.org/)
toolchain and [picolibc](https://github.com/picolibc/picolibc).

**Status:** early scaffolding. Nothing here works yet.

## What this is

A real SDK, not a build wrapper. Once installed, picomos looks and behaves
like every other cross-toolchain SDK you have used (arm-none-eabi,
esp-idf, Zephyr SDK, STM32Cube):

- A **host toolchain** (llvm-mos: `mos-clang`, `mos-clang++`, `llvm-ar`, ...)
- A **sysroot** under `mos-elf/` containing picolibc headers and libraries
- **Machine overlays** under `mos-elf/usr/share/picomos/machines/<name>/`
  contributing the per-machine linker script, `crt0.o`, and I/O backend
- **Clang config files** so users invoke the compiler normally:

```sh
mos-clang --config=$PICOMOS/share/picomos/configs/picomos-zbc.cfg \
          main.c -o hello.elf
```

The compiler discovers headers, libraries, `crt0.o`, and the linker script
from the sysroot. No picomos-specific tools required.

## Installed layout

```text
picomos-<version>-<host>/
├── bin/                              host binaries (llvm-mos toolchain)
│   ├── mos-clang
│   ├── mos-clang++
│   ├── llvm-ar
│   └── ...
│
├── mos-elf/                          THE SYSROOT
│   └── usr/
│       ├── include/                  picolibc headers (stdio.h, stdlib.h, ...)
│       ├── lib/                      arch-shared: libc.a, libm.a
│       └── share/picomos/
│           └── machines/
│               ├── zbc/
│               │   ├── crt0.o
│               │   ├── link.ld
│               │   ├── libio.a
│               │   └── run.sh
│               ├── c64/              (planned)
│               └── ...
│
└── share/picomos/
    ├── configs/                      clang config files, one per machine
    │   ├── picomos-zbc.cfg
    │   ├── picomos-c64.cfg
    │   └── ...
    ├── cmake/
    │   └── PicomosConfig.cmake       for downstream find_package(Picomos)
    ├── examples/                     copyable example sources
    └── docs/
```

## User workflows

All three are first-class. Pick your build system, not ours.

### 1. Direct compiler invocation

```sh
mos-clang --config=$PICOMOS/share/picomos/configs/picomos-zbc.cfg \
          main.c -o hello.elf
$PICOMOS/mos-elf/usr/share/picomos/machines/zbc/run.sh hello.elf
```

### 2. Makefile

```make
PICOMOS ?= /opt/picomos
CC       = mos-clang
CFLAGS   = --config=$(PICOMOS)/share/picomos/configs/picomos-zbc.cfg

hello.elf: main.c
	$(CC) $(CFLAGS) $< -o $@
```

### 3. CMake

```cmake
find_package(Picomos REQUIRED)
picomos_add_executable(hello MACHINE zbc SOURCES main.c)
```

`picomos_add_executable` is a thin convenience — it expands to the same
`--config=picomos-<machine>.cfg` invocation as workflow 1.

## Everything runs through CMake at build time

CMake is the only build driver for producing picomos itself. It runs
identically on Linux, macOS, and Windows, so per-host shell scripts are
avoided. picolibc's meson build is invoked via `ExternalProject`; machine
overlays and config files are plain CMake subprojects. The only shell
scripts in the tree are the emulator launchers (`machines/*/run.sh`),
and even those will get Windows equivalents before we claim Windows
support.

## Build model

The C library is architecture-level, not machine-level. picolibc's
`libc.a` doesn't know or care whether it's ending up on a Commodore 64 or
a NES — that's decided at final link time by the machine's linker script
and `crt0.o`. picomos reflects this:

```text
                built once per release
  ┌────────────────────────────────────────────┐
  │  llvm-mos toolchain (per host OS)          │
  │  picolibc for MOS: libc.a, libm.a          │
  │    -> installed to mos-elf/usr/{include,lib}/
  └────────────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        ▼                 ▼                 ▼
    machines/c64      machines/nes      machines/zbc
    link.ld           link.ld           link.ld
    crt0.o            crt0.o            crt0.o
    libio.a           libio.a           libio.a
    vice runner       mesen runner      mame runner

    -> installed to mos-elf/usr/share/picomos/machines/<name>/
    -> plus share/picomos/configs/picomos-<name>.cfg pointing at them
```

## Bootstrapping — where llvm-mos and picolibc come from

picomos does not require you to have llvm-mos or picolibc pre-installed.
Both come in through the configure step.

### Three ways to acquire llvm-mos

Reproducibility-first, because the SDK build itself is a maintainer/CI
concern — end users just download and unzip a bundle, so build time on
this side doesn't affect them:

- **`-DPICOMOS_LLVM_MOS_REF=<git-ref>`** — check out and build llvm-mos
  from source at the given tag/branch/SHA. **This is the default for
  the release workflow.** ~40-60 min, ~10 GB scratch, ~8-16 GB RAM.
  Reproducible from source; no dependency on llvm-mos's release asset
  naming or cadence.
- **`-DPICOMOS_LLVM_MOS_DOWNLOAD=<tag>`** — fast local fast-path.
  Download a prebuilt release from the
  [llvm-mos releases page](https://github.com/llvm-mos/llvm-mos/releases)
  for this host. Handy when iterating on picomos itself, not used by
  the release workflow.
- **`-DPICOMOS_LLVM_MOS_ROOT=<path>`** — use an already-built tree on
  disk. Typical when you already have llvm-mos built locally for other
  reasons.

### Acquiring picolibc

picolibc does not publish prebuilt binaries for MOS — nobody upstream
builds them. picomos has to produce them itself:

- **`-DPICOMOS_PICOLIBC_SOURCE=<path>`** or
  **`-DPICOMOS_PICOLIBC_REF=<tag>`** — build from source with meson.
  Requires meson + ninja on the build host. **Supported on Linux only.**
  Trying to build from source on Windows fails fast with a clear error
  pointing at the alternative below. macOS may work but is untested.

- **`-DPICOMOS_PICOLIBC_PREBUILT=<file-or-url>`** — extract an already-
  built `picolibc-mos.tar.xz`. Nothing on the host needs meson. The
  tarball has to come from somewhere:

  - **In CI:** stage 1 of [our release workflow](.github/workflows/release.yml)
    builds it on Linux and hands it to the macOS/Windows matrix jobs as
    an `actions/upload-artifact`. No external URL involved.
  - **On a dev machine:** until picomos itself has released once, the
    only source is a `.tar.xz` you (or someone) built on Linux and
    copied over. From picomos v1 onward we publish
    `picolibc-mos.tar.xz` alongside the host bundles as a release
    asset, and macOS/Windows devs can point `PICOMOS_PICOLIBC_PREBUILT`
    at that URL.

This is a genuine chicken-and-egg for the first release. It only bites
macOS/Windows developers who want to build picomos itself from source
before we've cut a release. macOS/Windows end users of picomos never
build anything — they download and unzip a host bundle.

## Quick start — developer (building everything from source, Linux)

```sh
cmake -B build \
    -DPICOMOS_LLVM_MOS_ROOT=$HOME/git/llvm-mos/build/install \
    -DPICOMOS_MACHINES="zbc;c64" \
    -DCMAKE_INSTALL_PREFIX=$HOME/opt/picomos
cmake --build build
cmake --install build
```

## Packaging a release (CI-only)

The release workflow in [.github/workflows/release.yml](.github/workflows/release.yml)
runs the two-stage build on GitHub Actions. In practice you don't run
this by hand — you push a tag and the workflow does it. Both stages
build llvm-mos from source at a pinned ref; the whole pipeline takes
2-3 hours on GitHub-hosted runners. That's fine — releases are
infrequent and the output is what everyone downloads. Documented here
so the shape is visible:

```sh
# Stage 1 (Linux only): build llvm-mos + picolibc from source, produce
# picolibc-mos.tar.xz for reuse by the matrix hosts.
cmake -B build \
    -DPICOMOS_LLVM_MOS_REF=<pinned-sha> \
    -DPICOMOS_PICOLIBC_REF=1.8.12 \
    -DPICOMOS_MACHINES="zbc"
cmake --build build --target picolibc-mos-tarball

# Stage 2 (each host runner in the matrix): build llvm-mos NATIVELY for
# this host (binaries can't be shared across hosts), reuse the picolibc
# tarball, assemble the sysroot. No meson runs here.
cmake -B build \
    -DPICOMOS_LLVM_MOS_REF=<pinned-sha> \
    -DPICOMOS_PICOLIBC_PREBUILT=$PWD/build/picolibc-mos.tar.xz \
    -DPICOMOS_INSTALL_TOOLCHAIN=ON \
    -DCMAKE_INSTALL_PREFIX=$PWD/dist/picomos-linux-x86_64
cmake --build build
cmake --install build
```

## Supported host OSes

- Linux (x86_64, aarch64) — full build-from-source support
- macOS (arm64, x86_64) — prebuilt picolibc only (meson untested)
- Windows (x86_64) — prebuilt picolibc only (meson unsupported by picolibc)

Host binaries are produced by a matrix build on GitHub Actions: one
Linux job produces `picolibc-mos.tar.xz`; three matrix jobs (Linux,
macOS, Windows) each consume it and produce the corresponding host
bundle.

## Repo layout

```text
CMakeLists.txt         top-level driver

cmake/
  PicomosLlvmMos.cmake       locates mos-clang + libclang_rt.builtins
  PicomosPicolibc.cmake      builds picolibc ONCE via ExternalProject,
                             installs into <install>/mos-elf/usr/{include,lib}
  PicomosMachine.cmake       picomos_machine() helper — compiles per-machine
                             crt0/io, assembles linker script, installs into
                             mos-elf/usr/share/picomos/machines/<name>/
  PicomosConfigWrite.cmake   generates share/picomos/configs/picomos-<mach>.cfg
                             (clang config file: --sysroot, -T, crt0.o, ...)
  PicomosConfig.cmake.in     installed as share/picomos/cmake/PicomosConfig.cmake
                             for downstream find_package(Picomos)

machines/                    per-machine overlays
  zbc/
    CMakeLists.txt           picomos_machine(zbc ...)
    manifest.toml            display name, cpu, emulator
    linker/                  memory.ld, sections.ld
    crt/                     startup sources
    io/                      machine-specific I/O
    run.sh                   emulator invocation

examples/                    (built out-of-tree against installed SDK)
  zbc/hello/{CMakeLists.txt,main.c}

.github/workflows/           matrix CI producing per-host release bundles
```

## License

TBD. Likely BSD-3-Clause to match picolibc.
