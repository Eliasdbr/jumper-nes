
;	Jumper (main.asm)
;	por Eliasdbr (eliasdbr@outlook.com)
;	***Escrito para ASM6 v1.6***

; Definiciones del proyecto
.include "src/init.asm"

; Incluye el header del archivo
.include "lib/header_ines.asm"			; Formato iNES

.org ASM_PROGRAM										; Comienza a ensamblar código

; Incluir librerías
.include "lib/nes_ppu.asm"					; Manejo de gráficos
.include "lib/nes_interrupts.asm" 	; Interrupts RESET,NMI,IRQ
.include "lib/nes_io.asm" 					; Joypads
.include "lib/move.asm" 						; Movimiento y posición
.include "lib/collide.asm"					; Detección de colisiones

; Incluye dependencias del juego
.include "src/game.asm" 						; Lógica del juego en general
.include "src/player.asm" 					; Lógica del jugador

; Constantes del Juego
; ---

; Variables de uso intensivo	(desde $0000 a $00FF)
.enum ASM_ZEROPAGE
; (xxx bytes usados de librerías)
ASM_ZEROPAGE = $
.ende

; Variables normales			(desde $0300 a $0800)
; Nada aún


.base ASM_PROGRAM	; Continuamos escribiendo programa

	; # - - - - - - - - - - - - - - - - - - - - - - - - - - #
	; # - - - Arranque del Juego (luego del RESET)  - - - - #
	; # - - - - - - - - - - - - - - - - - - - - - - - - - - #
main_setup:
	
	; --- Inicializa el Juego ---
	
	; Carga el menú, establece el game_state a MENU
	jsr GAME_LoadMenu
	
	MemCopy #FALSE,two_players	; Modo Un jugador
	
	lda #0				; Resetea el scroll
	sta scroll_x
	sta scroll_y
	
	
	
	; # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
	; # - - - Loop principal del Juego	(cada frame, después del VBLANK)  - - - #
	; # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
main_loop:
	;obtiene los joypads 
	IO_JoyUpdate						; (Macro)
	
	; 
	; Chequea el estado del juego (game_state)
	; 
	
	lda game_state
	bne +
		jmp GameplayLogic
	+
	cmp #GAME_STATE_PAUSE
	bne +
		jmp PauseLogic
	+
	cmp #GAME_STATE_INTER
	bne +
		jmp InterLogic
	+
	jmp MenuLogic

	; Lógica del juego
	;
	GameplayLogic:
		; Logica del jugador 1
		; 
		
		PLY_PhysicsUpdate 0 				; Físicas del jugador 1
		
		; No deja que se pase de la parte superior del nivel
		;lda player_y
		;cmp #32 						;Y=32: parte superior del nivel, parte inferior del HUD
		;bpl + 							; si player_y es menor a 32,
		;cmp #24 						; y mayor a 24:
		;bmi + 							;
		;	lda #32 					; acomoda player_y en 32.
		;	sta player_y			;
		;	lda #0						;resetea la velocidad vertical.
		;	sta player_yv 		;
		;	sta player_yvsub	;
		;	sta player_ysub 	;
		;+
	
	; Cosas que se procesan aún cuando está pausado
	;
	PauseLogic:
		; Chequea si acaba de presionar el botón Start
		IO_CheckButton 1,JP_START,TRUE
		beq +
			lda game_state
			eor #GAME_STATE_PAUSE 		; Togglea el estado de pausa
			sta game_state
		+
		; antes de finalizar el frame
		; posicion del jugador 1
		ldx player_x
		ldy player_y
		dey 							; sube Y un píxel para acomodar la posición del sprite
		stx PLAYER_1_SPR+SPRINFO_X
		sty PLAYER_1_SPR+SPRINFO_Y
		; posicion del jugador 2
		lda two_players
		beq +
			ldx player2_x
			ldy player2_y
			dey 							; sube Y un píxel para acomodar la posición del sprite
			stx PLAYER_2_SPR+SPRINFO_X
			sty PLAYER_2_SPR+SPRINFO_Y
		+
	jmp FrameEnd
	
	
	; Lógica de intermission
	;
	InterLogic:
	; ...
	jmp FrameEnd
	
	
	; Logica del menú
	;
	MenuLogic:
	IO_CheckButton 1,JP_START,TRUE
	beq +
		; lda #GAME_STATE_GAMEPLAY
		; sta game_state 
		jsr GAME_LoadLevel
	  ; --- Inicializa jugador/es ---
	  ; Esto debe hacerse al iniciar un nivel
	  ; Player 1
	  ldx #0	; Variables del jug 1
	  jsr PLY_Spawn
	  ; Player 2 (sólo si el modo 2 players está activado)
	  ; lda two_players
	  ; beq +
	  ; 	ldx #PLY_DATA_OFFSET ; Variables del jug 2
	  ; 	jsr PLY_Spawn
	  ; +
	+
	
	; Final del frame
	;
	FrameEnd:
	
	; Una vez ejecutada toda la lógica durante el frame, esperamos a que la PPU se desocupe y nos
	; interrumpa para poder actualizar los gráficos.
	inc waiting_nmi
	@wait:
		lda waiting_nmi
		bne @wait 			;Entramos en un Loop infinito hasta que la PPU esté lista. Entonces saltaremos a "NMI:"
		; Cuando finalice la rutina de VBLANK (cuando finalice "NMI:"), volveremos aquí.
jmp main_loop 			;volveremos a procesar toda la lógica para el siguiente frame.


; # - - - - - - - - - - - - - - - - - - - - - - - - - - #
; # - - - Sub-Rutinas del Juego (Funciones) - - - - - - #
; # - - - - - - - - - - - - - - - - - - - - - - - - - - #



; # - - - - - - - - - - - - - - - - - - - - #
; # - - -     Binarios externos     - - - - #
; # - - - - - - - - - - - - - - - - - - - - #
.align 256
; Información de fondo + atributos de color
bg:
.incbin "res\pantalla.nam"	;(tamaño: 1024 Bytes)
BG_MenuScreen:
.incbin "res\menu.nam"	; (1024 bytes)

metatiles:
.include "res\metatiles.asm"	; (1024 bytes)

.align 256

coll: 		;informacion de colision del nivel (116 bytes)
.byte %00000000, %00000000, %00000000, %00000000
.byte %00000000, %00000000, %00000000, %00000000
.byte %00000000, %00000000, %00000000, %00000000
.byte %00000000, %00000000, %00000000, %00000000
.byte %00000000, %00000000, %00000000, %00000000
.byte %00000000, %00000000, %00000000, %00000000
.byte %00000000, %00000000, %00000000, %00000000
.byte %00000000, %00000000, %00000000, %00000000
.byte %00111111, %11111111, %11111111, %11111000
.byte %00100000, %00000000, %00000000, %00001000
.byte %00100000, %00000000, %00000000, %11101000
.byte %00100000, %00000000, %00000000, %00101000
.byte %00100000, %00000000, %00000000, %00101000
.byte %00100000, %00000000, %00000000, %00101000
.byte %00100000, %00000000, %00000000, %00101111
.byte %00100000, %00000000, %00000000, %00000000
.byte %00100000, %00000000, %00000000, %00000000
.byte %00100000, %00000000, %00000000, %00000000
.byte %00111111, %11100000, %11111111, %11111111
.byte %00000000, %00100000, %10000000, %00000000
.byte %00000000, %00100000, %10000000, %00000000
.byte %00000000, %00100000, %10000000, %00000000
.byte %00000000, %00100000, %11111111, %11111110
.byte %00000000, %00100000, %00000000, %00000010
.byte %00000000, %00100000, %00000000, %00000010
.byte %00000000, %00100000, %00000000, %00000010
.byte %00000000, %00100000, %11111000, %00000010
.byte %00000000, %00100000, %10001000, %00000010
.byte %00000000, %00100000, %10001111, %11111110
.byte %00000000, %00100000, %10000000, %00000000 

.align 16
; paletas de fondo y de sprites respectivamente
palette:
.incbin "res\paleta_s1b.pal"			;Colores para el fondo del sector 1.	(16 bytes)
.incbin "res\paleta_sprites.pal"	;Colores para los diferentes objetos móviles(sprites). (16 bytes)

; Datos del sprite de ogmo
sprite_ogmo:
	.byte $00,$01,$00,$00

; # - - - - - - - - - - - - - - - - - - - - #
; # - - -         Vectores            - - - #
; # - - - - - - - - - - - - - - - - - - - - #

; Define los vectores del procesador apuntando a las respectivas etiquetas.
.pad $FFFA

.word NMI, RESET, IRQ
;indicamos al procesador a qué dirección tiene que saltar en caso de un Interrupt o Reset

; ( Fin de la PRG-ROM )

; # - - - - - - - - - - - - - - - - - - - - #
; # - - -     CHR-ROM(Gráficos)       - - - #
; # - - - - - - - - - - - - - - - - - - - - #

; Importar binario con los Gráficos de la CHR-ROM
.incbin "res\caracteres.chr"		;(tamaño: 8192 Bytes)

; ( Fin de la CHR-ROM )
