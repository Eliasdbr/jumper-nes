;
;	Librería de Movimiento de sprites (move.asm)
;	por Eliasdbr (eliasdbr@outlook.com)
;	Para la NES/Famicom 
;	***Escrito para ASM6 v1.6***
;	

;;	DEFINICIONES


;;	VARIABLES DE PÁGINA CERO


;;	OTRAS VARIABLES


;;	MACROS

; Suma la velocidad en un eje a la posición especificada (especificar addressing mode)
.macro MOVE_ApplyVelocityAxis pos,vel
	clc
	lda pos
	adc vel
	sta pos
.endm

; Suma la velocidad en un eje a la posición especificada (incluye sub-pixel) (especificar addressing mode)	
.macro MOVE_ApplyVelocityAxisSub pos,pos_sub,vel,vel_sub
	clc 						;
	lda pos_sub,x 	;
	adc vel_sub 		;
	sta pos_sub,x 	;
	lda pos,x 			;
	adc vel 				;
	sta pos,x 			;
.endm

.base ASM_PROGRAM
;;	SUB-RUTINAS

; Establece la velocidad en UN sólo eje (X/Y) tomando el input del Joypad (<>/^V)
; Parámetros:
;	A: Velocidad a establecer.
;	X: Estado de los botones del Joypad.
;	Y: 0: Botones < >, Botones ^ v.
;	temp0: byte bajo de la dirección de la posición a mover.
;	temp1: byte alto de la dirección de la posición a mover.
; Ocupa:
;	temp2-5: 4 bytes para tabla de velocidades (0,vel,-vel,0)
MOVE_joyVelAxis:
	target = temp0
	table = temp2	
	sta table+1		; Guarda la velocidad positiva en la tabla
	eor #$FF		; (convierte la velocidad en su negativo usando el complemento a 2)
	sta table+2		; Guarda la velocidad negativa en la tabla
	inc table+2		; Registro A queda liberado.	
	lda #0			
	sta table		; Pone el primer y último byte de table en 0.
	sta table+3		; 
	
	txa				; A = Botones del d-pad
	cpy #0			; Pregunta si se está tomando los botones arriba/abajo (%00001100 del joypad)
	beq +			; De ser así...
	lsr				; los corre 2 veces a la derecha (%00000011)
	lsr				;
+	and #3			; En cualquier caso, sólo nos interesa los 2 bits menos significativos.
	tax				; almacena el resultado en X, se usará como puntero para la Tabla.
	
	ldy #0			; Y = 0.
	lda table,x		; Obtiene la velocidad correspondiente dependiendo de lo que se estaba presionando.
	sta (target),y 	; Guarda la velocidad en su variable
	
	rts				; Fin de sub-rutina

; Movimiento básico sobre UN sólo eje (X/Y) tomando el input del Joypad (<>/^V)
; Parámetros:
;	A: Velocidad a mover.
;	X: Estado de los botones del Joypad.
;	Y: 0: Botones < >, Botones ^ v.
;	temp0: byte bajo de la dirección de la posición a mover.
;	temp1: byte alto de la dirección de la posición a mover.
; Ocupa:
;	temp2-5: 4 bytes para tabla de velocidades (0,vel,-vel,0)
MOVE_joyBasicAxis:
	target = temp0
	table = temp2	
	sta table+1		; Guarda la velocidad positiva en la tabla
	eor #$FF		; (convierte la velocidad en su negativo usando el complemento a 2)
	sta table+2		; Guarda la velocidad negativa en la tabla
	inc table+2		; Registro A queda liberado.	
	lda #0			
	sta table		; Pone el primer y último byte de table en 0.
	sta table+3		; 
	
	txa				; A = Botones del d-pad
	cpy #0			; Pregunta si se está tomando los botones arriba/abajo (%00001100 del joypad)
	beq +			; De ser así...
	lsr				; los corre 2 veces a la derecha (%00000011)
	lsr				;
+	and #3			; En cualquier caso, sólo nos interesa los 2 bits menos significativos.
	tax				; almacena el resultado en X, se usará como puntero para la Tabla.
	
	ldy #0			; Y = 0.
	clc				; Carry Bit = 0.
	lda (target),y	; A = Posición actual del objeto a procesar pero sólo en un eje (X/Y).
	adc table,x		; Le suma su velocidad correspondiente dependiendo de lo que se estaba presionando.
	sta (target),y 	; Guarda la posición ya modificada.
	
	rts				; Fin de sub-rutina
; FIN DE SUB-RUTINA
	
ASM_PROGRAM = $
