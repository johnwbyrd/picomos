; Thin wrapper around the C64 KERNAL GETIN routine at $FFE4.
;
;   char c64_chrin(void);
;
; Blocking single-character read from the current input device
; (keyboard by default). GETIN returns A=0 when no key is pending; we
; spin until a non-zero byte arrives, so callers get blocking semantics
; like stdio's getc. GETIN clobbers A/X/Y, but the llvm-mos calling
; convention treats X/Y as caller-saved, so no save/restore is needed.
;
; The single-byte return value is in the accumulator.

	.text
	.globl c64_chrin
	.type  c64_chrin,@function
c64_chrin:
1:	jsr $FFE4      ; KERNAL GETIN: read one byte from current input device
	beq 1b         ; A == 0 means "no key" — poll again
	rts
