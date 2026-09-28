/*
 * Portable picomos printf-formatter surface test.
 *
 * Exercises the integer-side of picolibc's tinystdio at the level
 * picomos ships (see PicomosPicolibc.cmake: format-default=i,
 * io-long-long=false). Each line prints a labeled result so a human
 * can eyeball which conversions render correctly; the ctest EXPECT
 * asserts "done." at the end, which is only reached if none of the
 * printf calls trap the CPU.
 *
 * Deliberately out of scope for this build's picolibc profile:
 *   %f %e %g   — no float printf (format-default=i)
 *   %lld       — no long-long printf (io-long-long=false)
 *   %p         — currently renders as "0x0" (bug worth fixing separately)
 */

#include <stdio.h>

int
main(void)
{
    puts("printf");

    /* Integer conversions. mos-clang uses 16-bit int, 32-bit long. */
    printf("d:  %d %d\n",     42, -42);
    printf("u:  %u %u\n",     42u, 65535u);
    printf("x:  %x %x\n",     0x2a, 0xff);
    printf("X:  %X %X\n",     0x2a, 0xff);
    printf("o:  %o %o\n",     052, 0377);

    /* String / char. */
    printf("s:  %s\n",        "abc");
    printf("c:  %c %c\n",     '!', 'Z');

    /* Long — 32-bit on this target. */
    printf("ld: %ld %ld\n",   1000000L, -1000000L);

    /* Width, left-align, zero-pad. */
    printf("w:  |%5d|%-5d|%05d|\n", 42, -42, 42);

    /* Precision. */
    printf("p:  |%.3s|%.2s|\n", "abcdef", "abcdef");

    /* Multiple args in one call + literal %. */
    printf("m:  %d/%s/%x %%\n", 7, "of", 9);

    puts("done.");
    return 0;
}
