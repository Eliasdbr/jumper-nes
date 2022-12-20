
;	Jumper (game.asm)
;	por Eliasdbr (eliasdbr@outlook.com)
;	***Escrito para ASM6 v1.6***

; 
; Lógica general del juego
; (Menu, gameplay, etc.)
;

;;	DEFINICIONES
GAME_STATE_GAMEPLAY 	.equ 0		; Estado del juego: Gameplay
GAME_STATE_PAUSE			.equ 1		; Estado del juego: Pausa
GAME_STATE_INTER			.equ 2		; Estado del juego: Intermission
GAME_STATE_MENU 			.equ 3		; Estado del juego: Menu

;;	VARIABLES DE PÁGINA CERO
.enum ASM_ZEROPAGE
game_state			.byte 0 		; Estado del juego.
														; 	0: Gameplay
														; 	1: Pausa
														; 	2: Intermission
														; 	3: Menu
two_players 		.byte 0 		; Modo de juego.
														; 	0: One player
														; 	1: two players
ASM_ZEROPAGE = $
.ende

;;	OTRAS VARIABLES


;;	MACROS


;;	SUB-RUTINAS
.base ASM_PROGRAM
; Carga el menú
GAME_LoadMenu:
	; Deshabilita las interrupciones
	sei
	; Desactiva los gráficos
	PPU_Disable 0 						; Es un macro.
	; Cambia el estado del juego a MENU
	MemCopy #GAME_STATE_MENU,game_state
	; Carga el background del menú
	ldx #<BG_MenuScreen 			; Byte bajo
	ldy #>BG_MenuScreen 			; Byte alto
	lda #0										; Nametable 0
	jsr PPU_loadScreen				; Carga la pantalla
	; Activar Vblank NMI, Sprites: $0000, Fondo: $1000
	ctrl_flags = PPUCTRL_NMI_ENABLE | PPUCTRL_BG_PATTERN
	; Muestra los sprites y el fondo
	mask_flags = PPUMASK_SHOW_SPR | PPUMASK_SHOW_BG
	; Reactiva los gráficos
	PPU_Enable ctrl_flags,mask_flags		;es un macro.
	; Vuelve a aceptar interrupciones
	cli
	; Termina la sub-rutina
	rts

; Carga un nivel
GAME_LoadLevel:
	; Deshabilita las interrupciones
	sei
	; Desactiva los gráficos
	PPU_Disable 0 						; Es un macro.
	; Cambia el estado del juego a GAMEPLAY
	MemCopy #GAME_STATE_GAMEPLAY,game_state
	; Carga la colisión (temporal)
	MemBulkCopy coll,COLL_level_data,120	; MemBulkCopy from,to,amount
	; Carga el background del menú
	ldx #<bg 			; Byte bajo
	ldy #>bg 			; Byte alto
	lda #0										; Nametable 0
	jsr PPU_loadScreen				; Carga la pantalla
	; Activar Vblank NMI, Sprites: $0000, Fondo: $1000
	ctrl_flags = PPUCTRL_NMI_ENABLE | PPUCTRL_BG_PATTERN
	; Muestra los sprites y el fondo
	mask_flags = PPUMASK_SHOW_SPR | PPUMASK_SHOW_BG
	; Reactiva los gráficos
	PPU_Enable ctrl_flags,mask_flags		;es un macro.
	; Vuelve a aceptar interrupciones
	cli
	; Termina la sub-rutina
	rts

ASM_PROGRAM = $

