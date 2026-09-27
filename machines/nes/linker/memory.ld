/*
 * NES (NROM-128, mapper 0) memory map.
 *
 * CPU address space:
 *   $0000-$001F  llvm-mos imaginary registers (soft registers)
 *   $0020-$00FF  zero page globals (224 bytes)
 *   $0100-$01FF  6502 hardware stack
 *   $0200-$07FF  general RAM (1.5 KB): data, bss, llvm-mos soft stack
 *   $2000-$2007  PPU registers (mirrored to $3FFF)
 *   $4000-$401F  APU / I/O registers ($401B is our __putchar side-channel)
 *   $C000-$FFFF  PRG-ROM (16 KB, mirrored to $8000-$BFFF by the mapper)
 *
 * PPU address space (not directly accessible; go through $2006/$2007):
 *   $0000-$1FFF  pattern tables (CHR-RAM on NROM-128 with CHR size = 0)
 *   $2000-$2FFF  nametables
 *   $3F00-$3F1F  palette
 *
 * Vectors sit at the top of PRG-ROM at $FFFA-$FFFF (NMI, RESET, IRQ).
 * The iNES header is emitted before PRG-ROM in the output file by
 * sections.ld's OUTPUT_FORMAT block — it is not visible at runtime.
 */

/*
 * llvm-mos imaginary registers at $0000. Unlike the c64, the NES has
 * no CPU-port banking to avoid, so we can start at zero.
 */
__rc_base = 0x00;

MEMORY {
    zp      (rw) : ORIGIN = 0x0020, LENGTH = 0x00E0
    ram     (rw) : ORIGIN = 0x0200, LENGTH = 0x0600
    prg_rom (rx) : ORIGIN = 0xC000, LENGTH = 0x4000
}

/*
 * llvm-mos soft stack grows downward from the top of internal RAM.
 * (The hardware stack lives in page 1 and is managed by the CPU.)
 */
__stack = 0x0800;
