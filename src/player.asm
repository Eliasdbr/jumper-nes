;
; Jumper (player.asm)
; por Eliasdbr (eliasdbr@outlook.com)
; ***Escrito para ASM6 v1.6***
;  
; Player logic

; CONSTANTES
PLAYER_SPEED		.equ 2	;velocidad de movimiento (en píxeles/frame)
PLAYER_ACCEL		.equ 32 ;aceleración (en sub-píxeles/frame) (es decir: 0.25)
PLAYER_TVEL 		.equ 4	;velocidad máxima de caída (en píxeles/frame)
PLAYER_JUMPSPD	.equ -3 ;velocidad de salto (en píxeles)
PLAYER_WJUMPSPD .equ 3	;velocidad de walljump (en píxeles)
PLAYER_WJUMPCD	.equ 10 ;cooldown de walljump (en frames)
PLAYER_GRAVITY	.equ 32 ;aceleración de gravedad (en sub-píxeles/frame) (es decir: 0.125)
PLAYER_MAXJUMPS .equ 1	;saltos máximos (en el aire)
PLAYER_1_SPR = OAM_PAGE + 1*4 ; Sprite 1
PLAYER_2_SPR = OAM_PAGE + 2*4 ; Sprite 2

; Variables de uso intensivo	(desde $0000 a $00FF)
.enum ASM_ZEROPAGE

; para llevar la cuenta de cuántos bytes ocupan
; los datos de un jugador, creamos una constante.

ply_data_start = $				; '$' representa la dirección actual 
													; en la que se está ensamblando

player_jumps	.byte 0 		; 0x00 -.
player_x			.byte 0 		; 0x01  |
player_xsub 	.byte 0 		; 0x02  |
player_y			.byte 0 		; 0x03  |
player_ysub 	.byte 0 		; 0x04   > Player 1 position and movement
player_xv 		.byte 0 		; 0x05  |
player_xvsub	.byte 0 		; 0x06  |
player_yv 		.byte 0 		; 0x07  |
player_yvsub	.byte 0 		; 0x08  |
player_ground .byte 0 		; 0x09  |
player_wall 	.byte 0 		; 0x0A  | 
player_wjcd 	.byte 0 		; 0x0B -' ; Wall-jump cooldown

PLY_DATA_OFFSET = $ - ply_data_start

player2_jumps .byte 0 		
player2_x 		.byte 0 		
player2_xsub  .byte 0 		
player2_y 		.byte 0 		
player2_ysub	.byte 0 		
player2_xv		.byte 0 		
player2_xvsub .byte 0 		
player2_yv		.byte 0 		
player2_yvsub .byte 0 		
player2_ground .byte 0		
player2_wall	.byte 0 		
player2_wjcd 	.byte 0 		; Wall Jump Cooldown

; (20 bytes)

ASM_ZEROPAGE = $
.ende
; Variables normales			(desde $0300 a $0800)
; Nada aún

; --- MACROS ---
; Player Physics
.macro PLY_PhysicsUpdate player_data_offset
	; Mueve al jugador horizontalmente dependiendo del input
	; Si acaba de hacer un Wall Jump, no acepta input por unos frames
	ldx #player_data_offset 	; Jugador 1
	lda player_wjcd,x 				;
	bne + 										;
		jsr PLY_JoyAccelerateAxis
	+
	ldx #0	; Jugador 1
	MOVE_ApplyVelocityAxisSub player_x,player_xsub,player_xv,player_xvsub
	
	;Que no se pase del extremo izquierdo
	ldx #player_data_offset 	; Jugador 1
	lda player_x,x
	cmp #5
	bmi + 				; si player_x está entre 5 y 7:
	cmp #7
	bpl +
		lda #8			; pone al player en la posición 8 en X
		sta player_x,x
	+

	;Chequea colisión con mapa de tiles. Eje X
	ldx #player_data_offset 		; Jugador 1
	lda #0						; Resetea las flags de si está tocando las paredes
	sta player_wall,x 	;
	jsr PLY_CheckWallsX

	;Maneja la gravedad y el salto del jugador
	ldx #player_data_offset 		; Jugador 1
	jsr PLY_JumpFall	;
	
	; Chequea colisión con mapa de tiles. Eje Y
	ldx #player_data_offset						; Jugador 1
	jsr PLY_CheckWallsY
.endm

; --- SUB-RUTINAS ---
.base ASM_PROGRAM

; Player Spawn
; Inicializa al jugador
; Parámetros:
; 	X: 0: Jugador 1
; 		 9: Jugador 2
PLY_Spawn:
	; Resetea las velocidades
	lda #0
	sta player_yv,x
	sta player_ysub,x
	sta player_yvsub,x
	sta player_xv,x
	sta player_xsub,x
	sta player_xvsub,x
	; Resetea el cooldown del walljump
	sta player_wjcd,x
	; Punto de entrada del nivel (proximamente será reemplazado por la info del nivel)
	lda #$40
	sta player_x,x
	lda #$80
	sta player_y,x
	; Resetea los saltos
	lda #PLAYER_MAXJUMPS
	sta player_jumps,x
	rts 	; Volver de Sub-Rutina

; Aceleración horizontal dependiendo del input
; Parámetros:
; 	X: Offset de datos del jugador (0 o PLY_DATA_OFFSET)
PLY_JoyAccelerateAxis:
	; Mira qué jugador está por procesar en el registro X
	txa
	bne + 							; Si es el jugador 2, saltea al otro joypad
		IO_CheckButton 1,JP_LEFT,FALSE
		tay 							; Almacena temporalmente el resultado.
		jmp ++						; Saltea el joypad 2
	+
		IO_CheckButton 2,JP_LEFT,FALSE
		tay 							; Almacena temporalmente el resultado.
	++
	tya 								; Recupera el estado del botón presionado (Libera Y)
	beq ++							; Si el botón < está siendo presionado:
		; Acelera hacia la izquierda.
		; recibe por el reg X la dirección del jugaor
		MOVE_ApplyVelocityAxisSub player_xv,player_xvsub,#-1,#-PLAYER_ACCEL
		; Si estaba yendo a la derecha, frena más rápido.
		lda player_xv,x
		bmi +
			MOVE_ApplyVelocityAxisSub player_xv,player_xvsub,#-1,#-PLAYER_ACCEL*2
		+
		lda player_xv,x 		; Chequea si superó la velocidad máxima:
		cmp #-PLAYER_SPEED	;
		bpl @maxv						; 
			; Desacelera hasta igualar la velocidad máxima
			MOVE_ApplyVelocityAxisSub player_xv,player_xvsub,#0,#PLAYER_ACCEL*2
			;lda #-PLAYER_SPEED 
			;sta player_xv,x 	; Hace clamp a la velocidad máxima
			;lda #0						;
			;sta player_xvsub,x
			;sta player_xsub,x
		@maxv: 							;
		rts 			; Fin de aceleración
	++
	txa 								; Mira de nuevo qué jugador estamos procesando
	bne + 							; Si es el jugador 2, saltea al otro joypad
		IO_CheckButton 1,JP_RIGHT,FALSE
		tay 							; Almacena temporalmente el resultado.
		jmp ++						; Saltea el joypad 2
	+
		IO_CheckButton 2,JP_RIGHT,FALSE
		tay 							; Almacena temporalmente el resultado.
	++
	tya 								; Recupera el estado del botón presionado (Libera Y)
	beq ++							; Si el botón > está siendo presionado:
		; Acelera hacia la derecha.
		MOVE_ApplyVelocityAxisSub player_xv,player_xvsub,#0,#PLAYER_ACCEL
		; Si estaba yendo a la izquierda, frena más rápido.
		lda player_xv,x
		bpl +
			MOVE_ApplyVelocityAxisSub player_xv,player_xvsub,#0,#PLAYER_ACCEL*2
		+
		lda player_xv,x 		; Chequea si superó la velocidad máxima:
		cmp #PLAYER_SPEED 	;
		bmi @minv						; De ser así:
			; Desacelera hasta igualar la velocidad máxima
			MOVE_ApplyVelocityAxisSub player_xv,player_xvsub,#-1,#-PLAYER_ACCEL*2
			;lda #PLAYER_SPEED ;
			;sta player_xv,x		; Hace clamp a la velocidad máxima
			;lda #0						;
			;sta player_xvsub,x
			;sta player_xsub,x
		@minv: 							;
		rts 								; Fin de la aceleración.
	++ 
		; - Desaceleración -
	lda player_xv,x			; Si ningún botón está siendo presionado:
	bne + 							; Y si la velocidad actual del jugador es 0:
		lda player_xvsub,x; Chequea si la velocidad sub-pixel es 0.
		beq end_input 		; Si es cero, termina la desaceleración.
	+ 
	lda player_xv,x 		; Chequea si la velocidad es negativa
	bmi + 							; 
	; Si es positiva, desacelera hacia la izquierda.
		MOVE_ApplyVelocityAxisSub player_xv,player_xvsub,#-1,#-PLAYER_ACCEL
		rts 							; Termina
	+ 
	; Si es negativa, desacelera hacia la derecha.
	MOVE_ApplyVelocityAxisSub player_xv,player_xvsub,#0,#PLAYER_ACCEL
end_input: 
	rts
	; FIN DE SUB-RUTINA

; Colisión del jugador en el eje X
; Recibe en el reg X qué jugador procesa
PLY_CheckWallsX:
	; (Macro)
	; Chequea la colisión en sus anchas
	; -1,0 --- 8,0
	;   |       |
	;   |       |
	; -1,7 --- 8,7
	; 
	COLL_SquareInTile8 player_x,player_y,coll,-1,0,8,0,-1,7,8,7
	ldx #0 ; TEST Jugador 1
	sta player_wall,x ; Guarda la info de colisión
	tay 							; Copia las colisiones al reg Y
	and #%00001010		; Chequea las dos esquinas de la izquierda
	beq + 						; si no hay colisión, chequea el siguiente lado
		lda player_x,x	; Pero si hay colision:
		clc 						;
		adc #7					; Acomoda al jugador en el tile de la derecha.
		and #%11111000	;
		sta player_x,x	;
		lda player_xv,x ; Si se estaba moviendo...
		beq + 					;
			lda #0					; resetea la velocidad horizontal.
			sta player_xv,x 
			sta player_xvsub,x
			sta player_xsub,x
	+ 
	tya 							; Recupera las colisiones
	and #%00000101		; Chequea las dos esquinas del lado de la derecha
	beq + 						; si no hay colisión, termina, no pasa más nada
		lda player_x,x	; Pero si hay colision:
		and #%11111000	; Acomoda el jugador en el tile de la izquierda
		sta player_x,x	;
		lda player_xv,x ; Si se estaba moviendo...
		beq + 					;
			lda #0					; resetea la velocidad horizontal.
			sta player_xv,x 
			sta player_xvsub,x
			sta player_xsub,x
	+
	rts

; Chequea colisión con las paredes en el eje Y
PLY_CheckWallsY:
	; (Macro)
	; Chequea la colisión en sus altas
	; 0,0 --- 7,0
	;  |       |
	;  |       |
	; 0,8 --- 7,8
	; 
	COLL_SquareInTile8 player_x,player_y,coll,0,0,7,0,0,8,7,8
	ldx #0	; Jugador 1
	tay 											; Copia las colisiones
	and #%00001100						; Chequea las dos esquinas de arriba
	beq + 										; si no hay colisión, chequea el siguiente lado
		lda player_y,x					; Pero si hay colision:
		clc 										;
		adc #7									; Acomoda al jugador en el tile de abajo.
		and #%11111000					;
		sta player_y,x					;
		lda #0									; Si está saltando, lo detiene
		sta player_yv,x 				;
		sta player_yvsub,x			;
		sta player_ysub,x 			;
	+
	tya 											; Recupera las colisiones
	and #%00000011						; Chequea las dos esquinas de abajo
	beq + 										; si no hay colisión, está en el aire
		; A veces no entra acá siendo que si está tocando el suelo...
		lda player_y,x					; Pero si hay colision:
		and #%11111000					; Acomoda el jugador en el tile de arriba
		sta player_y,x					;
		lda #0									; Si está cayendo, lo detiene.
		sta player_yv,x 				; Ha tocado el suelo
		sta player_yvsub,x			;
		sta player_ysub,x 			;
		lda #PLAYER_MAXJUMPS		; Resetea los saltos disponibles.
		sta player_jumps,x			; 
		lda #1									; Indica que está tocando el suelo.
		sta player_ground,x 		;
		jmp ++									; termina
	+ 												; Si no toca el suelo, está en el aire
		lda #0									;
		sta player_ground,x 		;
	++
	rts

; Salto y gravedad del jugador
PLY_JumpFall:
	; Wall Jump
	lda player_wjcd,x 	; Decrementa el timer
	beq + 							; del cooldown del walljump
		dec player_wjcd,x ; hasta llegar a 0.
	+
	; Salto de Ogmo
	IO_CheckButton 1,JP_A,TRUE	; Si acaba de presionar el botón A:
	beq +++ 										;
	lda player_ground,x 				; Si no está tocando el suelo:
	bne ++											;
		; Chequea si está presionando <
		IO_CheckButton 1,JP_LEFT,FALSE
		beq +
		lda player_wall,x 					; y si está tocando la pared izquierda
		and #%00001010							;
		beq + 											;
			lda #PLAYER_WJUMPSPD			; Hace un walljump hacia la derecha
			sta player_xv,x 					; 
			lda #PLAYER_JUMPSPD 			; Salta un poco hacia arriba también
			sta player_yv,x 					;
			lda #-128									; -2.5
			sta player_yvsub,x				;
			lda #0										; (redondea las velocidades)
			sta player_xvsub,x				;
			lda #PLAYER_WJUMPCD 			; resetea el contador de cooldown
			sta player_wjcd,x 				; del walljump
			jmp +++										; Termina
		+
		; Chequea si está presionando >
		IO_CheckButton 1,JP_RIGHT,FALSE
		beq ++
		lda player_wall,x 					; y si está tocando la pared derecha
		and #%00000101							;
		beq ++											;
			lda #-PLAYER_WJUMPSPD 		; Hace un walljump hacia la izquierda
			sta player_xv,x 					; 
			lda #PLAYER_JUMPSPD 			; Salta un poco hacia arriba también
			sta player_yv,x 					;
			lda #-128									; -2.5
			sta player_yvsub,x				;
			lda #0										; (redondea las velocidades)
			sta player_xvsub,x					;
			lda #PLAYER_WJUMPCD 			; resetea el contador de cooldown
			sta player_wjcd,x 				; del walljump
			jmp +++ 									; Termina
	++
	lda player_jumps,x					; Y si quedan saltos disponibles:
	beq +++ 										;
		lda #PLAYER_JUMPSPD				; Salta
		sta player_yv,x 					;
		lda #0										; (pone la velocidad vertical a 4.0)
		sta player_yvsub,x				;
		lda player_ground,x 			; Si no está tocando el suelo:
		bne +++ 									;
			dec player_jumps,x			; quita un salto disponible.
	+++
	;Gravedad
	lda player_yv,x 						; Si la velocidad vertical actual
	cmp #PLAYER_TVEL						; no supera la velocidad terminal:
	bpl + 											;
	lda player_ground,x 				; Si no está tocando el suelo:
	bne + 											;
		; Agrega gravedad.
		MOVE_ApplyVelocityAxisSub player_yv,player_yvsub,#0,#PLAYER_GRAVITY
		jmp ++											; pasa directamente a aplicar la velocidad
	+ 
	lda #0											; Si alcanzó la velocidad terminal:
	sta player_yvsub,x					; Resetea la velocidad sub-pixel.
	sta player_ysub,x 					; Resetea la posición sub-pixel.
	
	++
	; Mueve al jugador en el eje Y.
	MOVE_ApplyVelocityAxisSub player_y,player_ysub,player_yv,player_yvsub
	rts


ASM_PROGRAM = $

