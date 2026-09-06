/*
 * ZBC (MAME zbcm6502) memory map.
 *
 *   0x0000-0x01FF   6502 zero page + hardware stack (reserved)
 *   0x0200-0xFCDF   RAM: code, data, bss, soft stack, heap  (63 KB)
 *   0xFCE0-0xFCFF   ZBC semihost MMIO device                (32 bytes)
 *   0xFFFA-0xFFFF   6502 NMI / RESET / IRQ vectors          (6 bytes)
 *
 * MAME loads the ELF directly via -elfload and jumps to ENTRY(_start),
 * so no reset-vector image is required in this build.
 *
 * These symbols override the PROVIDE()d placeholder defaults inside
 * picolibc_noflash.ld's MEMORY block. picolibc keeps a single MEMORY
 * region name `flash` for code+rodata and `ram` for data+bss+heap; on
 * MOS both live in the same physical RAM region.
 */

__flash      = 0x0200;
__flash_size = 0xFAE0;
__ram        = 0x0200;
__ram_size   = 0xFAE0;
