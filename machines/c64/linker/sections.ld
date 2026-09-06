/*
 * Pull in picolibc's machine-agnostic minimal crt0 (provides _start,
 * __do_init_stack, __call_indir; calls main after clearing BSS and
 * copying .data — no libc_init_array, no exit shim). picolibc's
 * shared_crt0 needs main, memcpy, memset, and the linker-supplied
 * __data_start / __data_source / __data_size / __bss_start / __bss_size
 * symbols; we provide those below.
 */
GROUP(-lcrt0-minimal)

/*
 * Machine I/O overlay: chrout wrapper + FDEV_SETUP_STREAM stdout hook
 * that routes picolibc's stdio putc through KERNAL's CHROUT.
 */
GROUP(-lio)

ENTRY(_start)

/*
 * llvm-mos imaginary registers PROVIDE()s. Kept inline here so this
 * linker script is self-contained: picolibc's mos-regs.ld is a
 * meson-time INCLUDE that gets baked into picolibc_noflash.ld — it is
 * NOT installed as a standalone file in the sysroot.
 *
 * __rc_base is defined (not PROVIDE) in memory.ld above.
 */
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
 * Emit a Commodore PRG file directly from the linker: first two bytes
 * of the output image are the load address (little-endian ORIGIN of
 * ram), followed by the trimmed image up to the last non-BSS byte.
 *
 * `SHORT` and `TRIM` are llvm-mos ld.lld extensions specifically for
 * bare-metal image production; both are part of llvm-mos itself, not
 * llvm-mos-sdk.
 */
OUTPUT_FORMAT {
    SHORT(ORIGIN(ram))
    TRIM(ram)
}

SECTIONS {
    /*
     * BASIC "SYS 20xx" one-liner at $0801. Must be the very first
     * bytes of the image so that MAME's -quik and the C64 LOAD/RUN
     * flow see a valid BASIC program that jumps to _start.
     */
    .basic_header ORIGIN(ram) : {
        KEEP(*(.basic_header))
    } > ram

    .text : {
        /* picolibc's _start lives in .text.init.enter — must be
         * findable, but its address ends up in whatever slot the
         * BASIC SYS stub encodes at link time via .mos_addr_asciz. */
        KEEP(*(.text.init.enter))
        *(.text .text.* .literal .literal.*)
    } > ram

    .rodata : {
        *(.rodata .rodata.* .srodata .srodata.*)
    } > ram

    .data : {
        __data_start = .;
        *(.data .data.* .sdata .sdata.*)
        __data_end = .;
    } > ram

    /*
     * The image is loaded as-is into RAM at $0801 — there is no
     * separate flash region, so .data's load address is the same as
     * its runtime address. Point __data_source at __data_start so
     * picolibc's shared_crt0 memcpy is a no-op (still safe to call).
     */
    __data_source = __data_start;
    __data_size   = __data_end - __data_start;

    .bss (NOLOAD) : {
        __bss_start = .;
        *(.bss .bss.* .sbss .sbss.*)
        *(COMMON)
        __bss_end = .;
    } > ram

    __bss_size = __bss_end - __bss_start;

    /*
     * picolibc's shared_crt0 does NOT call __libc_init_array in the
     * minimal variant, so nothing references .init_array. Drop debug
     * and other host-tooling metadata from the PRG image.
     */
    /DISCARD/ : {
        *(.init_array .init_array.*)
        *(.fini_array .fini_array.*)
        *(.eh_frame  .eh_frame.*)
        *(.comment)
        *(.note .note.*)
    }
}
