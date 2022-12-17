;
;	Interrupciones del Hardware
;	por Eliasdbr (eliasdbr@outlook.com)
;	Para la NES/Famicom 
;	***Escrito para ASM6 v1.6***

;;	CONSTANTES


;;	VARIABLES
.enum ASM_ZEROPAGE			;- - Variables de uso intensivo - -
; 1 byte
waiting_nmi		.byte 0		;flag para determinar si se debe esperar al NMI

ASM_ZEROPAGE = $			;
.ende						;- - Fin de reserva de variables - -

;;	MACROS


; # - - - - - - - - - - - - - - - - - - - - #
; # - - - Código ubicado en la ROM 	  - - - #
; # - - - - - - - - - - - - - - - - - - - - #
.base ASM_PROGRAM
;A partir de aquí escribiremos el programa que se ejecutará al Encender/Resetear la consola.
RESET:
    sei        ; ignore IRQs
    cld        ; disable decimal mode
    ldx #$40
    stx $4017  ; disable APU frame IRQ
    ldx #$ff
    txs        ; Set up stack
	
	; Desactiva los gráficos
    PPU_Disable	0	;es un macro.

    ; Optional (omitted):
    ; Set up mapper and jmp to further init code here.

    ; The vblank flag is in an unknown state after reset,
    ; so it is cleared here to make sure that @vblankwait1
    ; does not exit immediately.
    bit $2002

    ; First of two waits for vertical blank to make sure that the
    ; PPU has stabilized
@vblankwait1:  
    bit $2002
    bpl @vblankwait1

    ; We now have about 30,000 cycles to burn before the PPU stabilizes.
    ; One thing we can do with this time is put RAM in a known state.
    ; Here we fill it with $00, which matches what (say) a C compiler
    ; expects for BSS.  Conveniently, X is still 0.
    txa
@clrmem:
    sta $000,x
    sta $100,x
    sta $200,x
    sta $300,x
    sta $400,x
    sta $500,x
    sta $600,x
    sta $700,x
    inx
    bne @clrmem
	
    ; Other things you can do between vblank waits are set up audio
    ; or set up other mapper registers.
   
@vblankwait2:
    bit $2002
    bpl @vblankwait2

	PPU_InitOAM 	;Limpia la memoria de sprites (es un macro)
	
	; LO QUE VIENE ES SÓLO DE JUMPER
	; Carga el sprite de Ogmo
	ldx #<sprite_ogmo	;byte bajo
	ldy #>sprite_ogmo	;byte alto
	lda #1				;ID del Sprite 1
	jsr PPU_loadSprite
	
	; Carga el sprite de Ogmo Azul
	ldx #<sprite_ogmo	;byte bajo
	ldy #>sprite_ogmo	;byte alto
	lda #2				;ID del Sprite 2
	jsr PPU_loadSprite
	; Igual a Ogmo, sólo que con la paleta azul
	lda #3
	sta OAM_PAGE+2*4+2	; Sprite 2, atributos
	
	; Carga la paleta del fondo
	ldx #<palette	;dirección byte bajo
	ldy #>palette	;dirección byte alto
	lda #0			;A=0 -> Paleta del Fondo
	jsr PPU_loadPalette
	
	; Carga la paleta de sprites
	ldx #<(palette+16)	;dirección byte bajo
	ldy #>palette		;dirección byte alto
	lda #16				;A=16 -> Paleta de Sprites
	jsr PPU_loadPalette
	
	; FIN DEL CÓDIGO DE JUMPER
	
	; Activar Vblank NMI, Sprites: $0000, Fondo: $1000
	ctrl_flags = PPUCTRL_NMI_ENABLE | PPUCTRL_BG_PATTERN
	; Muestra los sprites y el fondo
	mask_flags = PPUMASK_SHOW_SPR | PPUMASK_SHOW_BG
	; Reactiva los gráficos
	PPU_Enable ctrl_flags,mask_flags		;es un macro.

	;Otra instrucción que requiere la consola, iría al finalizar la preparación del juego.
	cli		;Permitir IRQs
	
	; Fin de la inicialización
	jmp main_setup		;salta al arranque del juego

; # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
; # - - - VBLANK (ya se dibujó el frame anterior. preparar el que sigue   - - - #
; # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
; Nota: colocar aquí SÓLO la info para actualizar gráficos, ya que el tiempo que disponemos para 
;		hacerlo es relativamente corto, así que todo lo que tenga que ver con las mecánicas y la
;		lógica del juego debe ir más arriba(en la parte de loop principal del juego).
NMI:
	PushAXY		; Macro. Llevamos los registros del procesador a la pila (A,X,Y)
	; Le pasa al PPU la dirección de los sprites
	lda #>OAM_PAGE
	sta OAMDMA
	; Lo último que se debe hacer antes de terminar es actualizar el valor del Scroll
	PPU_ScrollUpdate	;Macro. obtiene las coordenadas del Scroll desde la memoria de página cero.
	; La PPU ya está lista y le dice al CPU que deje de esperar
	lda #$00
	sta waiting_nmi
	; Una vez finalizadas todas las tareas de dibujado, restauramos los registros y volvemos.
	PullAXY		; Macro. Saca los registros A,X,Y de la pila.
	rti

; En caso de haber un IRQ, saltará acá.
IRQ:
	;No pasará nada
	rti

ASM_PROGRAM = $
