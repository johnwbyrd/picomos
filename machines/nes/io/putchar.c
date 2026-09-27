/*
 * NES __putchar for picomos: byte side-channel through an unused MMIO
 * address ($401B). MAME's runner-mame.lua for this machine installs a
 * memory write-tap on that address and mirrors each byte to the
 * emulator subprocess's stdout — the same pattern picomos_add_test
 * consumes via CTest's PASS_REGULAR_EXPRESSION.
 *
 * The $401B convention is inherited from llvm-mos-sdk's NES platform
 * (Apache-2.0 WITH LLVM-exception): it's an APU/IO register that no
 * standard NES program uses, so writes there are unambiguous as
 * "debug output" from the emulator side.
 *
 * On real hardware this __putchar is a no-op (writes to $401B are
 * silently ignored by the APU). Real-hardware NES programs override
 * __putchar with a PPU-nametable or serial-cart implementation —
 * this file is intentionally `weak` so the user can supply their own.
 */

#include <stdio.h>

#define NES_STDOUT (*(volatile unsigned char *)0x401B)

__attribute__((weak)) void
__putchar(char c)
{
    NES_STDOUT = (unsigned char) c;
}
