/*
 * Pull in picolibc's picocrt for MOS+semihost, built by picolibc's
 * meson using our cross file. libcrt0-semihost-zbc.a provides `_start`,
 * `__do_init_stack`, and the .init/.fini glue that picolibc_noflash.ld's
 * SECTIONS layout expects. GROUP() forces the archive to be searched
 * during allocation even without an explicit -l on the command line.
 */
GROUP(-lcrt0-semihost-zbc)

/*
 * Delegate the full SECTIONS + PHDRS layout to picolibc's generated
 * noflash script. The MEMORY defaults in that script are overridden by
 * the __flash/__ram symbols defined in memory.ld above, and the
 * `vectors` region referenced by its .vectors output section is
 * contributed via the cross file's extra_memory = mos-memory.ld.
 */
INCLUDE picolibc_noflash.ld
