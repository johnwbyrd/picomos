/*
 * Portable picomos hello — one source, every machine.
 *
 * All picomos machines route picolibc stdio to a per-machine backend:
 *
 *   zbc  → semihost device               (host stdout)
 *   c64  → KERNAL CHROUT ($FFD2)         (mirrored by runner-mame.lua)
 *   nes  → $401B side-channel MMIO       (mirrored by runner-mame.lua)
 *
 * The bytes puts() emits are the same on all three; only the transport
 * differs. That is what makes this example portable — no #ifdef.
 */

#include <stdio.h>

int
main(void)
{
    puts("hello, mos");
    return 0;
}
