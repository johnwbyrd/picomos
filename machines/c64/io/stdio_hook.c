/*
 * picolibc stdio hook for the Commodore 64.
 *
 * picolibc's TinyStdio calls a per-FILE `put` for each byte written
 * and `get` for each byte read. A single read/write FILE is installed
 * as stdout, stderr, and stdin; every byte routes through the C64
 * KERNAL:
 *
 *   writes  ->  CHROUT ($FFD2)   via c64_chrout()  (chrout.S)
 *   reads   ->  GETIN  ($FFE4)   via c64_chrin()   (chrin.S)
 *
 * PETSCII translation: the KERNAL speaks PETSCII, C source speaks
 * ASCII. For the ASCII printable range 0x20-0x7E the two encodings
 * overlap closely enough that a hello-world prints legibly. We do
 * translate the line terminator in both directions:
 *
 *   output:  '\n' (LF, 0x0A) -> $0D (PETSCII carriage return)
 *   input:   $0D             -> '\n'
 *
 * Lower-case ASCII letters map to PETSCII graphics glyphs until the
 * user switches to lower-case mode. That is a display concern, not a
 * correctness concern.
 */

#include <stdio.h>

char c64_chrin(void);       /* chrin.S  — KERNAL GETIN */
void c64_chrout(char ch);   /* chrout.S — KERNAL CHROUT */

static int
c64_putc(char c, FILE *stream)
{
    (void) stream;
    if (c == '\n')
        c64_chrout('\r');
    else
        c64_chrout(c);
    return (unsigned char) c;
}

static int
c64_getc(FILE *stream)
{
    (void) stream;
    char c = c64_chrin();
    if (c == '\r')
        return '\n';
    return (unsigned char) c;
}

static FILE __c64_stdio = FDEV_SETUP_STREAM(c64_putc,
                                            c64_getc,
                                            NULL,   /* no flush */
                                            _FDEV_SETUP_RW);

FILE *const stdout = &__c64_stdio;
FILE *const stderr = &__c64_stdio;
FILE *const stdin  = &__c64_stdio;
