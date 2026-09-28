; Thin wrapper around the C64 KERNAL CHROUT routine at $FFD2.
;
;   void c64_chrout(char ch);
;
; llvm-mos calling convention for a single-byte argument passes it in
; the accumulator. CHROUT itself is also A=character-in, and preserves
; X/Y. We just fall through to the KERNAL routine.

	.text
	.globl c64_chrout
	.type  c64_chrout,@function
c64_chrout:
	jsr $FFD2      ; KERNAL CHROUT: writes A to current output device
	rts
