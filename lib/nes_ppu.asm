;
;	Librería que maneja la PPU (nes_ppu.asm)
;	por Eliasdbr (eliasdbr@outlook.com)
;	Para la NES/Famicom 
;	***Escrito para ASM6 v1.6***

	; # - - - - - - - - - - - - - - - - - - - #
	; # - - - Constantes del Assembler  - - - #
	; # - - - - - - - - - - - - - - - - - - - #

;;	REGRISTROS DE LA PPU
PPUCTRL= $2000			;PPU Control Register
PPUMASK= $2001			;PPU Mask Register
PPUSTAT= $2002			;PPU Status Register
OAMADDR= $2003			;PPU OAM Address
OAMDATA= $2004			;PPU OAM Data
PPUSCRL= $2005			;PPU Fine Scroll (two writes= X, Y)
PPUADDR= $2006			;PPU Address
PPUDATA= $2007			;PPU Data
OAMDMA=  $4014			;OAM DMA Page (parte alta)

;;	DIRECCIONES DENTRO DE LA PPU
PPUNAM0 = $2000		;PPU Name Table 0
PPUNAM1 = $2400		;PPU Name Table 1
PPUNAM2 = $2800		;PPU Name Table 2
PPUNAM3 = $2C00		;PPU Name Table 3
PPUPAL	= $3F00		;PPU Palettes

;;	DIRECCIONES GENERALES
OAM_PAGE= $0200		;dirección donde empieza la tabla de objetos(sprites)

;;	FLAGS
;PPU Control ($2000) write
PPUCTRL_NMI_ENABLE 	= $80	; Permite a la PPU activar el interrupt NMI
PPUCTRL_MASTER	   	= $40	; Siempre poner en 0. Inútil si la consola no está hackeada.
PPUCTRL_8X16_SPR	= $20	; 0: utiliza sprites de 8x8. 1: Utiliza sprites de 8x16
PPUCTRL_BG_PATTERN	= $10	; Ubicación de los tiles de fondo en CHR-ROM. 0: $0000. 1: $1000.
PPUCTRL_SPR_PATTERN	= $08	; Ubicación de los tiles de sprites en CHR-ROM. 0: $0000. 1: $1000.
PPUCTRL_ADDR_INC	= $04	; Cantidad que incrementa PPUADDR por cada lectura/escritura del CPU. 0: +1. 1: +32
;PPU Mask ($2001) write
PPUMASK_EMPHASIZE_BLUE 	= $80			; Enfatiza el color azul
if SYS_REGION==NTSC						; Dependiendo de la Región(NTSC o PAL), se define las flags de red y green
	PPUMASK_EMPHASIZE_GREEN = $40		;  Enfatiza el color verde
	PPUMASK_EMPHASIZE_RED	= $20		;  Enfatiza el color rojo
else
	PPUMASK_EMPHASIZE_RED 	= $40
	PPUMASK_EMPHASIZE_GREEN	= $20
endif
PPUMASK_SHOW_SPR		= $10			; Mostrar sprites.
PPUMASK_SHOW_BG 		= $08			; Mostrar Fondo.
PPUMASK_LEFTMOST_SPR	= $04			; Mostrar los primeros 8 píxeles desde la izquierda (sprites).
PPUMASK_LEFTMOST_BG 	= $02			; Mostrar los primeros 8 píxeles desde la izquierda (fondo).
PPUMASK_GRAYSCALE		= $01			; Modo blanco y negro.
;PPU Status ($2002) read
PPUSTAT_VBLANK = $80		; VBlank ha comenzado
PPUSTAT_SPR0_HIT = $40		; Sprite 0 Hit. Se usa para interrupts a mitad del frame
PPUSTAT_SPR_LIMIT = $20		; Sprite Overflow. Inestable, no tiene utilidad.

;Sprite Attributes
SPRATTR_VFLIP= %10000000		;Atributo del sprite: Voltear verticalmente
SPRATTR_HFLIP= %01000000		;Atributo del sprite: Voltear horizontalmente
SPRATTR_BEHIND= %00100000		;Atributo del sprite: Detrás del Fondo

;Sprite Info Offsets
SPRINFO_Y = 0 		; Posición Y
SPRINFO_TILE = 1	; Tile del Sprite
SPRINFO_ATTR = 2	; Atributos del sprite
SPRINFO_X = 3 		; Posición X

;;	VARIABLES
.enum ASM_ZEROPAGE				;- - Variables de uso intensivo - -
; 2 bytes
scroll_x		.byte 0		;Posición x de la cámara
scroll_y		.byte 0		;Posición y de la cámara

ASM_ZEROPAGE = $					;
.ende						;- - Fin de reserva de variables - -

; # - - - - - - - - - - - - - - #
; # - - - 	MACROS	 	  - - - #
; # - - - - - - - - - - - - - - #
;;	Activar el PPU con los parámetros establecidos
.macro PPU_Enable control,mask
	lda #control
	sta PPUCTRL
	lda #mask
	sta PPUMASK
.endm

;;	Desactivar el PPU
.macro PPU_Disable
	lda #0
    sta PPUCTRL  ; disable NMI
    sta PPUMASK  ; disable rendering
.endm

;;	Inicializa la tabla de sprites
.macro PPU_InitOAM
	lda #$FF
	ldx #$00
-	sta OAM_PAGE,x
	inx
	bne -
.endm

;;	Actualiza el Scroll del Fondo
.macro PPU_ScrollUpdate
	ldx scroll_x
	ldy scroll_y
	stx PPUSCRL
	sty PPUSCRL
.endm

; # - - - - - - - - - - - - - - - - - - - - #
; # - - - Sub-Rutinas (Funciones) 	  - - - #
; # - - - - - - - - - - - - - - - - - - - - #
.base ASM_PROGRAM
	
;	CARGA UN SPRITE EN LA TABLA OAM		Parámetros: ypos,tile,attributes,xpos
;	Parámetros:
;		A: Sprite ID (0-63)
;		X: puntero del sprite a copiar (byte bajo)
;		Y: puntero del sprite a copiar (byte alto)
;	Ocupa:
;		temp0: puntero del sprite a copiar (byte bajo)
;		temp1: puntero del sprite a copiar (byte alto)
PPU_loadSprite:
	spr_data = temp0	; Utiliza las variables temp0 y temp1 para almacenar la dirección del sprite.

	stx spr_data		; transfiere la dirección del sprite de origen
	sty spr_data+1		; a la página cero liberando así los registros X,Y.
	
	asl					; 
	asl					; X = A * 4		// Transforma el ID del Sprite en un offset de la Tabla de sprites
	tax					; 	
	ldy #0				; Y = 0			// Usará Y como puntero de propiedades del sprite
	
-	lda (spr_data),y	; Copia la propiedad del sprite de origen
	sta OAM_PAGE,x	; La pega en el offset de la Tabla de sprites
	inx					;
	iny					; Pasa a la siguiente propiedad
	cpy #4				; 
	bne -				; Hacer lo mismo con las 4 propiedades
	
	rts					; fin de sub-rutina

;	CARGA UNA PALETA (16 colores)
;	Parámetros:
;		A: Offset de dirección de paleta (0 = Background; 16 = Sprites)
;		X: puntero de la paleta a copiar (byte bajo)
;		Y: puntero de la paleta a copiar (byte alto)
;	Ocupa:
;		temp0: puntero de la paleta a copiar (byte bajo)
;		temp1: puntero de la paleta a copiar (byte alto)
PPU_loadPalette:
	pal_data = temp0 	; Utiliza las variables temp0 y temp1 para almacenar la dirección de la paleta.
	
	stx pal_data		; transfiere la dirección de la paleta de origen
	sty pal_data+1		; a la página cero, liberando así los registros X,Y
	
	ldx #>PPUPAL		; Dirección de las paletas dentro de la memoria de la PPU.
	stx PPUADDR			; El CPU le avisa a la PPU que le va a enviar
	sta PPUADDR			; datos a esa dirección de su memoria (PPUPAL) (byte alto, byte bajo)
	
	ldy #0				; Y = 0.
-	lda (pal_data),y	; Copia esos datos desde pal_data
	sta PPUDATA			; Los envía uno por uno
	iny					; pasa al siguiente
	cpy #$10			; 
	bne -				; Si llegó a los 16 colores, termina.
	
	rts					; Fin de la sub-rutina.

;	CARGA UNA PANTALLA EN EL NAMETABLE DETERMINADO (0-3)
;	Parámetros:
;		A: Nametable (0 - 3)
;		X: puntero de la pantalla a copiar (byte bajo)
;		Y: puntero de la pantalla a copiar (byte alto)
;	Ocupa:
;		temp0: puntero de la pantalla a copiar (byte bajo)
;		temp1: puntero de la pantalla a copiar (byte alto)
PPU_loadScreen:
	scr_data = temp0	; puntero de la pantalla a copiar
	stx scr_data			; Escribe la dirección de la pantalla a copiar
	sty scr_data+1		; en temp0 (parte baja) y temp1 (parte alta) Libera X, Y.
	
	asl 					; A *= 4	// Convierte el N° de nametable en su offset				A | PPUADDR
	asl 					; 				// correspondiente dentro de la memoria de la ppu. ---+---------
	clc 					; 																														0 | $2000
	adc #>PPUNAM0		; Agrega el offset a la dirección de la nametable.					1 | $2400
	ldx #0				; X = 0.																											2 | $2800
	sta PPUADDR			; El CPU le avisa a la PPU que le va a enviar 							3 | $2C00
	stx PPUADDR			; datos a esa dirección de su memoria (PPUNAMx)
	
	ldy #0				; Y = 0
	ldx #4				; X = 4	// X cuenta las páginas que quedan copiar de la pantalla (4 * 256 = 1024 bytes)
-	lda (scr_data),y	; Copia esos datos desde scr_data
	sta PPUDATA			; Los envía uno por uno.
	iny					; Pasa al siguiente.
	bne -				; Si no completó una página, vuelve a enviar otro byte. 
	inc scr_data+1		; Pasa a la siguiente página de 256 bytes.
	dex					;
	bne -				; Si el contador X no llegó a 0, quedan páginas por copiar.
	
	rts					; Fin de la sub-rutina.

; Fin del código
ASM_PROGRAM = $
