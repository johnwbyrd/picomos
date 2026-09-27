/*
 * picolibc stdio hook for the NES.
 *
 * picolibc's TinyStdio calls a per-FILE `put` callback for each byte
 * written. Route every write through our __putchar (putchar.c),
 * which stores each byte to the $401B side-channel MMIO. No PETSCII
 * or screen-code translation is needed — the emulator's write-tap
 * sees raw ASCII bytes, and `\n` passes through unmodified.
 *
 * stdin is stubbed to always return EOF: the NES has no ordinary
 * text input device (controllers only). Programs that want stdin
 * on real hardware override __getchar with a controller-polling
 * implementation.
 */

#include <stdio.h>

extern void __putchar(char c);

static int
nes_putc(char c, FILE *stream)
{
    (void) stream;
    __putchar(c);
    return (unsigned char) c;
}

static int
nes_getc(FILE *stream)
{
    (void) stream;
    return EOF;
}

static FILE __nes_stdio = FDEV_SETUP_STREAM(nes_putc,
                                            nes_getc,
                                            NULL,   /* no flush */
                                            _FDEV_SETUP_RW);

FILE *const stdout = &__nes_stdio;
FILE *const stderr = &__nes_stdio;
FILE *const stdin  = &__nes_stdio;
