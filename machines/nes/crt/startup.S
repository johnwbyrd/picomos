; picomos NES startup / reset handler.
;
; Reset vector at $FFFC points here (see sections.ld). Job list:
;
;   1. Disable IRQs + clear decimal mode.
;   2. Initialize the 6502 hardware stack.
;   3. Silence the PPU + APU so no stray NMI or DMC IRQ fires.
;   4. Wait two VBlanks — canonical NES power-on delay.
;   5. Zero all internal RAM ($0000-$07FF).
;   6. Initialize the llvm-mos soft stack (__rc0/__rc1 <- __stack).
;   7. Copy .data from its LMA in PRG-ROM to its VMA in RAM.
;   8. Call main().
;   9. On return, spin.

.set PPU_CTRL,   $2000
.set PPU_MASK,   $2001
.set PPU_STATUS, $2002
.set APU_DMC_CTL, $4010
.set APU_FRAME,   $4017

; Zero-page scratch used only during startup, before user code runs.
; These are outside the llvm-mos reserved range ($00-$1F) and outside
; typical user zp; we clobber $02-$07 during the .data copy and never
; touch them again.
.set SRC_LO,  $02
.set SRC_HI,  $03
.set DST_LO,  $04
.set DST_HI,  $05
.set CNT_LO,  $06
.set CNT_HI,  $07

	.section .text.init.enter,"ax",@progbits
	.globl _start
_start:
	sei
	cld
	ldx #$ff
	txs                     ; hardware stack -> $01FF

	; ---- Silence PPU + APU so nothing interrupts us -----------------
	lda #$00
	sta PPU_CTRL            ; disable NMI, pattern table 0
	sta PPU_MASK            ; disable rendering
	sta APU_DMC_CTL         ; disable DMC IRQ
	lda #$40
	sta APU_FRAME           ; disable frame counter IRQ

	bit PPU_STATUS          ; clear vblank flag left over from reset

	; ---- Wait VBlank #1 --------------------------------------------
1:	bit PPU_STATUS
	bpl 1b

	; ---- Clear internal RAM $0000-$07FF ----------------------------
	ldx #$00
	lda #$00
clr:
	sta $0000, x
	sta $0100, x
	sta $0200, x
	sta $0300, x
	sta $0400, x
	sta $0500, x
	sta $0600, x
	sta $0700, x
	inx
	bne clr

	; ---- Wait VBlank #2 (PPU fully stable) --------------------------
2:	bit PPU_STATUS
	bpl 2b

	; ---- Init llvm-mos soft stack ----------------------------------
	lda #<__stack
	sta __rc0
	lda #>__stack
	sta __rc1

	; ---- Copy .data from PRG-ROM LMA to RAM VMA --------------------
	; Skip entirely if __data_size is zero (common for hello world).
	lda #<__data_size
	ora #>__data_size
	beq skip_data

	lda #<__data_source
	sta SRC_LO
	lda #>__data_source
	sta SRC_HI
	lda #<__data_start
	sta DST_LO
	lda #>__data_start
	sta DST_HI
	lda #<__data_size
	sta CNT_LO
	lda #>__data_size
	sta CNT_HI

	ldy #0
copy:
	lda (SRC_LO), y
	sta (DST_LO), y

	; ++src
	inc SRC_LO
	bne src_ok
	inc SRC_HI
src_ok:
	; ++dst
	inc DST_LO
	bne dst_ok
	inc DST_HI
dst_ok:
	; --count (16-bit)
	lda CNT_LO
	bne dec_lo_ok
	dec CNT_HI
dec_lo_ok:
	dec CNT_LO

	; loop while count != 0
	lda CNT_LO
	ora CNT_HI
	bne copy

skip_data:
	; ---- Call main() -----------------------------------------------
	.extern main
	jsr main

	; ---- Halt ------------------------------------------------------
hang:
	jmp hang

; ---- Weak default NMI + IRQ handlers ----------------------------------
	.text
	.weak nmi_handler
	.weak irq_handler
nmi_handler:
irq_handler:
	rti
