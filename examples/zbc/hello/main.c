/*
 * Minimal picomos hello for ZBC.
 * Prints via the ZBC semihost device (routed through picolibc stdio),
 * then exits cleanly so MAME terminates.
 */

#include <stdio.h>
#include <stdlib.h>

int
main(void)
{
    puts("hello, mos");
    return 0;
}
