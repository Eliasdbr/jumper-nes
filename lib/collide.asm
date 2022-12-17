;
;	Librería para colisiones
;	por Eliasdbr (eliasdbr@outlook.com)
;	Para la NES/Famicom 
;	***Escrito para ASM6 v1.6***

;;	DEFINICIONES


;;	VARIABLES DE PÁGINA CERO


;;	OTRAS VARIABLES


;;	MACROS
;	Detecta colisión entre dos rectángulos		(Especificar addressing mode)
;	Ocupa temp0-4, A,X,Y
.macro COLL_Rect rx1,ry1,rw1,rh1,rx2,ry2,rw2,rh2
	;Chequea colisiones en eje X
	MemCopy2 rx1,rw1,temp0,temp1
	MemCopy2 rx2,rw2,temp2,temp3
	jsr COLL_rectAxis
	beq + 										; Si no hay colisión en un eje, no habrá colisión.
	;Chequea colisiones en eje Y
	MemCopy2 ry1,rh1,temp0,temp1
	MemCopy2 ry2,rh2,temp2,temp3
	jsr COLL_rectAxis
+
.endm

; Consulta si un punto en X y Y colisiona con un tile en el mapa de tiles (se puede agregar offset)
; ATENCIÓN, se debe especificar en temp0 y temp1 la dirección del mapa de tiles. parte baja y alta respectivamente.
; Se le puede agregar un offset de dirección en el registro X. Dejar en 0 si no se quiere usar
.macro COLL_PointInBitmap8 xpos,ypos,xoffset,yoffset
	stx temp6 		; Guarda qué jugador está procesando temporalmente
	;posición x
	lda xpos,x
	clc
	adc #xoffset
	lsr
	lsr
	lsr
	sta temp7 		; Guarda la posicion X en temp7
	;posición y
	lda ypos,x
	clc
	adc #yoffset
	lsr
	lsr
	lsr
	tay					; posicion tile Y
	ldx temp7		; posicion tile X
	jsr COLL_TileBitmap8
	ldx temp6 	; recupera el jugador que estaba procesando
.endm

; Consulta si Un rectángulo está colisionando con un tile del mapa de tiles.
; tlx,tly --- trx,try
;    |           |
;    |           |
;    |           |
;    |           |
; blx,bly --- brx,bry
.macro COLL_SquareInTile8 xpos,ypos,coll_addr,tlx,tly,trx,try,blx,bly,brx,bry
	; temp3 = coll_flags
	
	MemCopy #0,temp3		;resetea las colisiones en las 4 esquinas
	MemCopy2 #<coll_addr,#>coll_addr,temp0,temp1
	COLL_PointInBitmap8 xpos,ypos,tlx,tly
	rol temp3
	COLL_PointInBitmap8 xpos,ypos,trx,try
	rol temp3
	COLL_PointInBitmap8 xpos,ypos,blx,bly
	rol temp3
	COLL_PointInBitmap8 xpos,ypos,brx,bry
	rol temp3
	; Develve en A los resultados de las colisiones en las 4 esquinas. 
	lda temp3
.endm

;; SUB-RUTINAS
.base ASM_PROGRAM
;	Colisión simple X/Y.	
;	Ejemplo con el eje X: (x1+w1 > x2) && (x2+w2 > x1)
;	Observar que se puede usar la misma función para el eje Y.
;	por lo tanto, para obtener la colisión de un rectángulo/cuadrado,
;	basta con llamar la misma sub-rutina una vez para el eje X, y otra para el eje Y.
;	Parámetros:
;		temp0: Posición X/Y del objeto 1.
;		temp1: Ancho/Alto del objeto 1.
;		temp2: Posición X/Y del objeto 2.
;		temp3: Ancho/Alto del objeto 2.
;	Devuelve:
;		A: 0 si no hubo colisión, 1 si hubo colisión
COLL_rectAxis:
	x1 = temp0
	w1 = temp1
	x2 = temp2
	w2 = temp3
	
	lda x1			; Carga la posición X/Y del obj #1
	clc				;
	adc w1			; Le suma su ancho/alto
	cmp x2			; Si es más grande que la posición X/Y:
	bmi @no_coll	; Sigue ejecutando. Si no, 
	lda x2			; 
	clc				;
	adc w2			; *repite lo mismo de arriba con el objeto #2
	cmp x1			;
	bmi @no_coll	; En caso de haber colisión, devuelve 1 en A
	lda #1			; Devuelve 1 en A
	rts			; Volver de sub-rutina
@no_coll:
	lda #0			; Devuelve 0 en A.
	rts				; Volver de sub-rutina

; ; Obtiene en A la posición en un eje de un tile(8,16,32,64)	(especificar addressing mode para TARGET_POS)
; COLL_GetTilePosAxis
	; clc
	; lda pos_addr
	; adc #offset
	; lsr
	; lsr
	; lsr
	
	; rts				; Volver de sub-rutina


; Consulta si un tile tiene colisión partir de una coordenada de tile X y Y. (Tiles de 8x8 píxeles)
; Nota:
; 	Ésta sería la fórmula para obtener el byte: Y*4 + X/8
;	y ésta fórmula es para obtener la posición del bit: X%8
; Parámetros:
;	X: Posición X del Tile (0-31)
;	Y: Posición Y del Tile (0-29)
;	temp0: ubicación del mapa de bits de colisión (byte bajo)
;	temp1: ubicación del mapa de bits de colisión (byte alto)
; Ocupa:
;	Reg A
;	temp2: Registro temporal
; Devuelve:
;	Carry Flag Set: hay colisión
;	Carry Flag Clear: no hay colisión
COLL_TileBitmap8:
	coll_bitmap = temp0
	;convierte las coordenadas de tile en ubicación del byte a chequear del mapa de colisiones
	tya			;
	asl			; A = Y*4
	asl			;
	sta temp2	; temp2 = A; Liberamos Y
	txa			;
	lsr			; A = X/8
	lsr			;
	lsr			;
	clc			;
	adc temp2	; A += temp2
	tay			; Y = A;	Usaremos Y como puntero del byte.
	;ya tenemos la ubicación del byte, ahora sólo nos queda obtener la posición del bit
	txa			;
	and #7		; X %= 8;	Usaremos X como puntero del bit.
	tax			;
	inx			;	Incrementa X para que quede un rango de 1 - 8 (necesario para lo que se viene)
	;ahora sólo queda buscar el byte determinado por Y comenzando desde la posición en coll_bitmap
	;y así rotar los bits cuantas veces diga X.
	lda (coll_bitmap),y
-	rol			; Pasa el Carry <- 7 <- 6 <- 5 <- 4 <- 3 <- 2 <- 1 <- 0 <- Carry
	dex			; decrementar X no afecta al Carry Flag (menos mal)
	bne -		; Si X != 0, repite el proceso
	rts			; Volver de sub-rutina.


	
ASM_PROGRAM = $
