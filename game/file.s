PPUCTRL   = $2000
PPUMASK   = $2001
PPUSTATUS = $2002
PPUADDR   = $2006 ; address of ppu data
PPUDATA   = $2007 ; data for ppu
OAMADDR    = $2003
OAMDMA    = $4014

.segment "HEADER"
	.byte "NES"		;identification string
	.byte $1A
	.byte $02		;amount of PRG ROM in 16K units
	.byte $01		;amount of CHR ROM in 8K units
	.byte $00		;mapper and mirroing
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00

.segment "ZEROPAGE"
player_x: .res 1
player_y: .res 1
player_dir: .res 1
attributes: .res 1

.segment "CODE"
.proc main

	LDX PPUSTATUS
	LDX #$3F	;$3F00
	STX PPUADDR
	LDX #$00
	STX PPUADDR
LOADPALETTES:
	LDA PALETTEDATA, X
	STA PPUDATA
	INX
	CPX #$20
	BNE LOADPALETTES

; ;LOADING SPRITES
; 	LDX #$00
; LOADSPRITES:
; 	LDA SPRITEDATA, X
; 	STA $0200, X
; 	INX
; 	CPX #$10	;4 bytes per sprite
; 	BNE LOADSPRITES

;LOADING BACKGROUND - nametables

	LDA PPUSTATUS		; First dot
	; Load $2000
	LDA #$20
	STA PPUADDR
	LDA #$00
	STA PPUADDR
	LDX #$00
LOADBACK:
	LDA background, X
	STA PPUDATA
	INX
	CPX #$00
	BNE LOADBACK
LOADBACK2:
	LDA background+256, X
	STA PPUDATA
	INX
	CPX #$00
	BNE LOADBACK2
LOADBACK3:
	LDA background+512, X
	STA PPUDATA
	INX
	CPX #$00
	BNE LOADBACK3
LOADBACK4:
	LDA background+768, X
	STA PPUDATA
	INX
	CPX #$00
	BNE LOADBACK4

vblankwait:
	BIT PPUSTATUS
	BPL vblankwait

	LDA #%10010000 ; turn on MNIs, sprits use first pattern table
	STA PPUCTRL
	LDA #%00011110		; turn on screen
	STA PPUMASK
	gameloop:
		JMP gameloop
.endproc


.proc irq_handler
  RTI
.endproc

.proc nmi_handler
	LDA #$00
	STA OAMADDR
	;LOAD SPRITE RANGE
	LDA #$02	 ; 0200
	STA OAMDMA

	JSR update_player ; Update location
	JSR draw_player ; draw the location

	;RESET SCROLL
	LDA #$00
	STA $2005 ; set x scroll

	LDA #$00
	STA $2005 ; set y scroll

	RTI 

.endproc

.proc reset_handler
	SEI 		;disables interupts
	CLD			;turn off decimal mode

	; Clear PPU registers
	LDX #$00
	STX PPUCTRL
	STX PPUMASK

	LDX #$00
	LDA #$ff
CLEARMEMORY:
	STA $0200, X
	INX
	INX
	INX
	INX
	CPX #$00
	BNE CLEARMEMORY

waitvblank:
	BIT PPUSTATUS
	BPL waitvblank

	LDA #$80
	STA player_x
	LDA #$a0
	STA player_y


	JMP main

.endproc

.proc update_player
	PHP
	PHA
	TXA
	PHA
	TYA
	PHA

	;; Update player logic

	LDA player_x
	CMP #$e0 ; 224
	BCC not_at_right_edge

	LDA #%00000000 ; start moving left
	STA attributes ; direction

	; If we are at right edge
	LDA #$00 ; start moving left
	STA player_dir ; direction
	JMP direction_set


not_at_right_edge:
	LDA player_x
	CMP #$10
	BCS direction_set

	LDA #%01000000 ; set attributes
	STA attributes ; direction
	LDA #01
	STA player_dir ; moving right

direction_set:
	LDA player_dir
	CMP #$01
	BEQ move_right

	DEC player_x
	JMP exit_sub

move_right:
	INC player_x
	

exit_sub:
	PLA
	TAY
	PLA
	TAX
	PLA
	PLP
	RTS
.endproc

;; Draw players location on screen
.proc draw_player
	PHP
	PHA
	TXA
	PHA
	TYA
	PHA

	; Top left

	; Y , X
	LDA player_y
	STA $0200

	; Sprite num
	LDA #$00
	STA $0201

	; attributes
	LDA attributes
	STA $0202

	LDA player_x
	STA $0203

	;; Bottom left of tringle

	; Y , X
	LDA player_y ; Y + 8
	CLC
	ADC #$08
	STA $0204

	; Sprite num
	LDA #$10
	STA $0205

	; attributes
	LDA attributes
	STA $0206

	LDA player_x ; X
	STA $0207

	PLA
	TAY
	PLA
	TAX
	PLA
	PLP
	RTS
.endproc

.segment "RODATA"

PALETTEDATA:
.byte $31, $1C, $2B, $39 ; background
.byte $31, $06, $15, $36 ; background
.byte $31, $09, $19, $2A ; background
.byte $31, $16, $27, $18 ; background

.byte $31, $14, $23, $11
.byte $31, $1C, $2B, $39
.byte $31, $06, $15, $39
.byte $31, $13, $23, $33
	
.include "background.asm"

.segment "VECTORS"
	.addr nmi_handler, reset_handler, irq_handler
	; specialized hardware interurpts

.segment "CHR"
	.incbin "rom.chr"