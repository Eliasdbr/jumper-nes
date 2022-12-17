;
;	Jumper (init.asm)
;	Establece definiciones del proyecto
;	por Eliasdbr (eliasdbr@outlook.com)
;	Para la NES/Famicom
;	***Escrito para ASM6 v1.6***

;	Consumo de recursos
;	RAM: 8 bytes
;	ROM: -

;;	DEFINICIONES
TRUE		EQU 1
FALSE 	EQU 0
NULL		EQU 0

NTSC		EQU 0
PAL 		EQU 1

SYS_REGION = NTSC 	; Región del sistema.

; PLACEHOLDERS PARA EL ENSAMBLADOR
; Estas variables del ensamblador guardarán las direcciones 
; actuales de cada área para poder definir variables continuamente
; entre diferentes archivos de ASM.
ASM_ZEROPAGE= 		$0000 	;Página Cero (Zero Page)
ASM_DATASEGMENT=	$0300 	;Segmento de Datos (Data Segment) (Empieza la RAM)
ASM_PROGRAM=			$8000 	;Programa (PRG-ROM)

; Variables de uso intensivo (8 bytes)
.enum ASM_ZEROPAGE
temp0 		.byte 0 	;Variables temporales
temp1 		.byte 0 	;(generalmente usadas para las funciones)
temp2 		.byte 0 	
temp3 		.byte 0 	
temp4 		.byte 0 	
temp5 		.byte 0 	
temp6 		.byte 0 	
temp7 		.byte 0 	
ASM_ZEROPAGE = $
.ende

;;	MACROS
; MANIPULACIÓN DE DATOS.
.macro LoadAXY ra,rx,ry 	; Carga los registros A,X,Y 	(Especificar address mode)
	lda ra
	ldx rx
	ldy ry
.endm
	
.macro LoadXY rx,ry 	; Carga los registros X,Y (Especificar address mode)
	ldx rx
	ldy ry
.endm

.macro MemCopy from,to		; Copia un byte desde una posición de memoria a otra. (Especificar address mode)
	lda from
	sta to
.endm

.macro MemCopy2 from1,from2,to1,to2 	; Copia 2 bytes. Cada origen con su destino. (Especificar address mode)
	ldx from1
	ldy from2
	stx to1
	sty to2
.endm

.macro PushAXY		; Empuja los registros A,X,Y a la pila.
	pha
	txa
	pha
	tya
	pha
.endm

.macro PullAXY		; Saca los registros A,X,Y de la pila.
	pla
	tay
	pla
	tax
	pla
.endm

; PROCESAMIENTO DE DATOS.
.macro Sign number	; Obtiene el signo de un número. (<0 = -1; 0 = 0, >0 = 1)	(Especificar address mode)
	lda number					; carga en A un número
	beq @end						; Si es 0, devuelve 0 en A.
	bmi @negative 			; Si es negativo, devuelve -1.
	lda #1							; si es positivo, devuelve 1.
	bpl @end						; termina.
	@negative:					; 
	lda #-1 						; 
	@end: 							; fin del macro
.endm

.macro Opposite number	; Devuelve en A el complemento a 2 de un número.
	lda number
	eor #$FF
	tax
	inx
	txa
.endm

.macro Abs number	; Devuelve en A el valor absoluto de un número.
	lda number
	bpl @end
	Opposite number
	@end:
.endm

.macro Max n1,n2	; Devuelve en A el Máximo de 2 números. 	(Especificar address mode)
	lda n1
	cmp n2
	bpl @end
	lda n2
	@end:
.endm

.macro Min n1,n2	; Devuelve en A el Mínimo de 2 números. 	(Especificar address mode)
	lda n1
	cmp n2
	bmi @end
	lda n2
	@end:
.endm

.macro ToFixed8 number	; Convierte un número con signo de 8 bits en un número de punto fijo de 8 bits (SIIIFFFF)
	;Si el numero es <(-8) o >(+7), devuelve error. ($FF en X)
	lda number
	cmp #-8
	bmi @error
	cmp #7
	bpl @error
	asl
	asl			;Corre el número 4 bits a la izquierda (A*16)
	asl
	asl
	jmp @end
	@error:
	ldx #$FF
	@end:
.endm
