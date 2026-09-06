/*
 * Commodore 64 memory map (BASIC + KERNAL ROMs left mapped so KERNAL
 * routines like CHROUT $FFD2 remain callable):
 *
 *   0x0000-0x0001   CPU port (memory-banking control — DO NOT clobber)
 *   0x0002-0x008F   free zero page (BASIC uses some, we reuse for llvm-mos regs)
 *   0x0100-0x01FF   6502 hardware stack (JSR/RTS/interrupts)
 *   0x0200-0x03FF   KERNAL/BASIC scratch
 *   0x0400-0x07FF   default VIC-II screen memory (25 rows x 40 cols)
 *   0x0801-0x9FFF   BASIC program area — where PRG files load        (~38 KB)
 *   0xA000-0xBFFF   BASIC ROM
 *   0xC000-0xCFFF   RAM (uncontested by ROMs)                        (4 KB)
 *   0xD000-0xDFFF   VIC-II / SID / CIA I/O
 *   0xE000-0xFFFF   KERNAL ROM (contains CHROUT at $FFD2)
 *
 * Program image lives entirely in the BASIC area 0x0801-0x9FFF. Soft
 * stack (llvm-mos software stack) grows down from just below the BASIC
 * ROM at 0xA000.
 */

/*
 * llvm-mos imaginary (zero-page) registers. Skip 0x0000-0x0001 — the
 * C64 CPU port. Registers occupy 32 bytes starting at 0x02. This
 * defeats the default __rc_base = 0x00 defined by picolibc's mos-regs.ld
 * PROVIDE. Assigning (not PROVIDE) here makes the assignment
 * unconditional.
 */
__rc_base = 0x02;

MEMORY {
    ram (rwx) : ORIGIN = 0x0801, LENGTH = 0x97FF
}

/* Soft stack grows downward from just below BASIC ROM. picolibc's
 * machine_mos_init-stack.S copies this into __rc0/__rc1 at _start. */
__stack = 0xA000;
