/*
 * Minimal picomos hello for the Nintendo Entertainment System.
 * Uses picolibc's puts() — routed by the nes machine overlay's
 * stdio hook through __putchar, which writes each byte to the
 * $401B side-channel MMIO. MAME's runner-mame.lua taps that address
 * and streams the bytes to the emulator subprocess's stdout.
 *
 * On real NES hardware nothing visible would happen — writes to
 * $401B are silently ignored by the APU. Override __putchar to
 * plumb output to the PPU (nametable + font) or a serial cart.
 */

#include <stdio.h>

int
main(void)
{
    puts("hello, mos");
    return 0;
}
