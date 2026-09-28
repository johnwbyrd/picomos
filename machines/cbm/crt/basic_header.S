; C64 BASIC one-line loader stub.
;
; When a PRG file is loaded at $0801 (the standard BASIC program area)
; and RUN, the BASIC interpreter walks a linked list of tokenised
; program lines starting there. We emit exactly one line:
;
;     10 SYS <__do_init_stack-as-4-decimal-digits>
;
; which transfers control to picolibc's __do_init_stack — NOT _start
; directly. __do_init_stack is in .init.100 in libcrt0-*, and its
; job is to load __stack into the __rc0/__rc1 soft-stack pointer,
; then jmp _start. Skipping this step leaves the soft stack pointing
; at whatever was in zero page at boot (usually garbage), and any
; picolibc function call — malloc, printf, even puts eventually —
; ends up storing through a corrupt indirect pointer.
; When main returns, RTS comes back to BASIC.
;
; Layout (12 bytes):
;   +0  .word next_line   ; pointer to next BASIC line ($0000 = end)
;   +2  .word 7773        ; BASIC line number (7773 = "LLVM" leetspeak)
;   +4  .byte $9E         ; token for the SYS keyword
;   +5  .asciz "20xx"     ; four ASCII decimal digits = _start address
;   +10 .word 0           ; terminator (end of program)
;
; The `.mos_addr_asciz _start, 4` directive is an llvm-mos MC extension
; that fills in the four-digit decimal string with the final linked
; address of _start.
;
; Cribbed structurally from llvm-mos-sdk/mos-platform/c64/basic-header.S
; (Apache-2.0 WITH LLVM-exception); this file is picomos-authored and
; carries picomos's licence.

	.section .basic_header,"aR",@progbits
	.short next_line       ; address of next BASIC line
	.short 7773            ; line number: "LLVM" in leetspeak (hint that
	                       ; this program was built with an llvm-mos SDK)
	.byte  0x9e            ; SYS token
	.mos_addr_asciz __do_init_stack, 4  ; 4-digit decimal address of
	                       ; picolibc's soft-stack initialiser
next_line:
	.short 0               ; end-of-program marker
