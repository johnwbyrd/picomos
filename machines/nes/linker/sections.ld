/*
 * Pull in picolibc's machine-agnostic minimal crt0 (provides _start,
 * __do_init_stack, __call_indir) and this machine's I/O overlay
 * (putchar + stdio_hook). The NES startup file overrides _start with
 * an NES-specific reset routine — since our _start is a strong
 * definition, picolibc's shared_crt0 is left out of the link, and we
 * only pull in the pieces we actually reference.
 */
GROUP(-lcrt0-minimal)
GROUP(-lio)

ENTRY(_start)

/* llvm-mos imaginary registers. __rc_base defined in memory.ld. */
__rc0  = __rc_base;
__rc1  = __rc0  + 1;   __rc2  = __rc1  + 1;   __rc3  = __rc2  + 1;
__rc4  = __rc3  + 1;   __rc5  = __rc4  + 1;   __rc6  = __rc5  + 1;
__rc7  = __rc6  + 1;   __rc8  = __rc7  + 1;   __rc9  = __rc8  + 1;
__rc10 = __rc9  + 1;   __rc11 = __rc10 + 1;   __rc12 = __rc11 + 1;
__rc13 = __rc12 + 1;   __rc14 = __rc13 + 1;   __rc15 = __rc14 + 1;
__rc16 = __rc15 + 1;   __rc17 = __rc16 + 1;   __rc18 = __rc17 + 1;
__rc19 = __rc18 + 1;   __rc20 = __rc19 + 1;   __rc21 = __rc20 + 1;
__rc22 = __rc21 + 1;   __rc23 = __rc22 + 1;   __rc24 = __rc23 + 1;
__rc25 = __rc24 + 1;   __rc26 = __rc25 + 1;   __rc27 = __rc26 + 1;
__rc28 = __rc27 + 1;   __rc29 = __rc28 + 1;   __rc30 = __rc29 + 1;
__rc31 = __rc30 + 1;

/*
 * Emit an iNES 2.0 header (16 bytes) followed by exactly 16 KiB of
 * PRG-ROM. `BYTE()` and `FULL()` are llvm-mos ld.lld extensions —
 * FULL emits the full memory region (zero-padded), which the iNES
 * format requires (unlike c64's PRG which uses TRIM).
 *
 * Header layout cribbed structurally from
 * llvm-mos-sdk/mos-platform/nes/ines-header.ld
 * (Apache-2.0 WITH LLVM-exception). Fields hardcoded for our fixed
 * NROM-128 / CHR-RAM configuration.
 */
OUTPUT_FORMAT {
    /* Magic: "NES" + MS-DOS EOF. */
    BYTE(0x4E) BYTE(0x45) BYTE(0x53) BYTE(0x1A)
    /* PRG-ROM size in 16 KiB units. */
    BYTE(0x01)
    /* CHR-ROM size in 8 KiB units. Zero means "use CHR-RAM". */
    BYTE(0x00)
    /* Flags 6: horizontal mirroring, no battery, no trainer, mapper 0 low. */
    BYTE(0x00)
    /* Flags 7: iNES 2.0 signature (bits 3-2 = 10), console type 0, mapper 0 hi. */
    BYTE(0x08)
    /* Flags 8: mapper MSB (0), submapper (0). */
    BYTE(0x00)
    /* Flags 9: PRG/CHR ROM size MSBs (0). */
    BYTE(0x00)
    /* Flags 10: PRG-RAM / PRG-NVRAM sizes (none). */
    BYTE(0x00)
    /* Flags 11: CHR-RAM in low nibble, CHR-NVRAM in high.
     * CHR-RAM = 8 KiB => log2(8192)-6 = 7. */
    BYTE(0x07)
    /* Flags 12: CPU/PPU timing (0 = NTSC). */
    BYTE(0x00)
    /* Flags 13: system type (0). */
    BYTE(0x00)
    /* Flags 14: misc ROMs count (0). */
    BYTE(0x00)
    /* Flags 15: default expansion device (0 = unspecified). */
    BYTE(0x00)

    FULL(prg_rom)
}

SECTIONS {
    .text : {
        KEEP(*(.text.init.enter))
        *(.text .text.* .literal .literal.*)
    } > prg_rom

    .rodata : {
        *(.rodata .rodata.* .srodata .srodata.*)
    } > prg_rom

    /*
     * NROM has no PRG-RAM, so initialized .data has to be copied from
     * PRG-ROM to internal RAM at startup. LMA in PRG-ROM, VMA in ram.
     */
    .data : {
        __data_start = .;
        *(.data .data.* .sdata .sdata.*)
        __data_end = .;
    } > ram AT> prg_rom
    __data_source = LOADADDR(.data);
    __data_size   = __data_end - __data_start;

    .bss (NOLOAD) : {
        __bss_start = .;
        *(.bss .bss.* .sbss .sbss.*)
        *(COMMON)
        __bss_end = .;
    } > ram
    __bss_size = __bss_end - __bss_start;

    /*
     * Reset/NMI/IRQ vectors at $FFFA. NMI first, then RESET points at
     * our own _start, then IRQ. `nmi_handler` and `irq_handler` are
     * weak-defined by startup.S as bare `rti`s; user code can override.
     */
    .vectors 0xFFFA : {
        SHORT(nmi_handler)
        SHORT(_start)
        SHORT(irq_handler)
    } > prg_rom

    /DISCARD/ : {
        *(.init_array .init_array.*)
        *(.fini_array .fini_array.*)
        *(.eh_frame  .eh_frame.*)
        *(.comment)
        *(.note .note.*)
    }
}
