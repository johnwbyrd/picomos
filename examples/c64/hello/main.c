/*
 * Minimal picomos hello for the Commodore 64.
 * Prints via KERNAL CHROUT ($FFD2) — routed through picolibc stdio by
 * the c64 machine overlay's stdio_hook.c. main() returns to _start's
 * rts, which returns to the BASIC READY prompt.
 */

#include <stdio.h>

int
main(void)
{
    puts("HELLO, PICOMOS!");
    return 0;
}
