/*
 * Portable picomos malloc/free demonstration.
 *
 * Exercises picolibc's malloc against the heap region each machine
 * defines with __heap_start / __heap_end in its linker script. sbrk
 * is resolved to picolibc's libos fallback (weak sbrk symbol overridden
 * by __fallback_sbrk).
 *
 * Ends with the token "done." — that is what the CTest test asserts;
 * reaching it means both allocations succeeded, contents round-tripped,
 * and free() didn't corrupt heap metadata.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int
main(void)
{
    puts("malloc/free");

    /* Two live allocations. */
    char *a = malloc(64);
    char *b = malloc(32);
    if (!a || !b) { puts("malloc failed"); return 1; }

    strcpy(a, "hello from heap");
    memset(b, 'x', 31);
    b[31] = '\0';
    puts(a);
    puts(b);

    /* Free-then-reallocate: the block re-enters the free list. */
    free(a);
    char *c = malloc(64);
    if (!c) { puts("malloc reuse failed"); return 1; }
    strcpy(c, "reused after free");
    puts(c);

    free(b);
    free(c);

    puts("done.");
    return 0;
}
