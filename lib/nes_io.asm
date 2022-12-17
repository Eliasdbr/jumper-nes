;
;	Librería de interfaz de usuario (joysticks)
;	por Eliasdbr (eliasdbr@outlook.com)
;	Para la NES/Famicom 

 
;
;	***Escrito para ASM6 v1.6***

;; CONSTANTES
;;	REGISTROS DEL HARDWARE
JOYPAD1= $4016			;Joypad 1
JOYPAD2= $4017			;Joypad 2


;;	FLAGS 
JP_A=		%10000000		;Botón Joypad 'A'
JP_B=		%01000000		;Botón Joypad 'B'
JP_SELECT= 	%00100000		;Botón Joypad 'Select'
JP_START=	%00010000		;Botón Joypad 'Start'
JP_UP=		%00001000		;Botón Joypad 'Up'
JP_DOWN=	%00000100		;Botón Joypad 'Down'
JP_LEFT=	%00000010		;Botón Joypad 'Left'
JP_RIGHT=	%00000001		;Botón Joypad 'Right'


;;	VARIABLES PÁGINA CERO
.enum ASM_ZEROPAGE
; 4 bytes
joypad1 			.byte 0		;estados de los botones del jugador 1
joypad1_prev	.byte 0		;estado de los botones del jugador 1 en el frame anterior.
joypad2 			.byte 0		;estados de los botones del jugador 2
joypad2_prev	.byte 0		;estado de los botones del jugador 2 en el frame anterior. 

ASM_ZEROPAGE = $
.ende

;;	SEGMENTO DE DATOS
; Nada aún.

;;	MACROS

; Chequea si el botón determinado está presionado o no. (Usa A)
; 	player: (1,2) qué jugador chequea
; 	button: (flag) qué botón chequea
; 	justpressed: (bool) chequea si comenzó a presionarse en el frame actual
.macro IO_CheckButton player,button,justpressed
	lda joypad1 + (player - 1)*2
	and #button
	beq @end
	IF justpressed
		eor joypad1_prev + (player - 1)*2
		and #button
	ENDIF
	@end:
	cmp #0
	; Regresa el estado de la flag "Zero"
	; También deja el estado del botón en A.
	; (A == 0: Falso -- A != 0: Verdadero)
.endm
;OBTENER DATOS DE LOS CONTROLES
.macro IO_JoyUpdate
	; Actualiza los botones previos
	ldx joypad1
	ldy joypad2
	stx joypad1_prev
	sty joypad2_prev
	; Actualiza los botones actuales
	lda #$01
	sta joypad1 	;le ponemos 1 a joypad1 para indicar cuándo llega a mirar los 8 botones.
	sta joypad2 	; repetir con el joystick 2
	sta JOYPAD1 	;decirle a los controles(joysticks) #1 y #2 que miren qué botones se están apretando.
	sta JOYPAD2 	; repetir con el joystick 2
	lda #$00
	sta JOYPAD1 	;decirle al control(joystick) #1 que guarde lo botones que miró.
	sta JOYPAD2 	; repetir con el joystick 2
	; Ahora le pediremos al joystick si los botones estaban presionados o no, uno por uno.
	clc
	-
	lda JOYPAD1 	;preguntamos el estado del botón actual
	lsr 					;mete el estado del botón actual en el carry flag.
	rol joypad1 	;pone el bit7 en el Carry y lo que estaba en el Carry lo manda al bit0
	bcc - 				;si se obtienen los 8 botones, el carry estará en 1, si no, volvemos a pedir un boton.
	clc 					;
	-
	lda JOYPAD2 	; repetir con el joystick 2
	lsr 					;
	rol joypad2 	;
	bcc - 				;
.endm

; # - - - - - - - - - - - - - - - - - - - - #
; # - - - Sub-Rutinas (Funciones) 	  - - - #
; # - - - - - - - - - - - - - - - - - - - - #

;; Agregar obtención de controles en modo seguro (DCPM)


;; FINALIZA DE DEFNIR SUB-RUTINAS
