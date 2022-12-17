;
;	ines_header.asm
;	por Eliasdbr (eliasdbr@outlook.com)
;	Para la NES/Famicom
;	***Escrito para ASM6 v1.6***

;	NOTAS:
;	-Está todo hardcodeado, hay que generalizar junto con "init.asm"

	; # - - - - - - - - - - - - #
	; # - - - iNES header - - - #
	; # - - - - - - - - - - - - #

; iNES identifier
.byte "NES",$1a

; Cantidad de Bloques de Programa (PRG-ROM x 16kB)(byte 4)
.byte $02		;2x16kB = 32kB total

; Cantidad de Bloques Gráficos (CHR-ROM x 8kB)(byte 5)
.byte $01

; Información de control del ROM (bytes 6-7)
.byte %00000001 , $00
;< MMMMvtbm , MMMM---- >
;	M = 8 bits para determinar qué Mapper se usa. 0 = NROM (sin Mapper)
;	v =	No reflejar las "nametables", usar VRAM incorporada para almacenar 4 "nametables" diferentes.
;	t = Usar un "Trainer" de 512 bytes antes del PRG-ROM. (Tiene algo que ver con los Mappers)
;	b = Usar RAM alimentada con Batería(PRG-RAM).
;	m = Reflejar las 2 "nametables" verticalmente? 0 = Horizontalmente, 1 = Verticalmente
;	- = Otros flags para control de ROM que yo dejo en 0 (para más info buscar "iNES Header")

; Tamaño de la RAM alimentada por batería (PRG-RAM) (byte 8)
.byte $00	;yo no lo uso, así que 0.

; Región de TV (byte 9)
.byte $00	;0 = NTSC(América del norte, Japon, Oeste de Sudamérica) 
			;1 = PAL(Europa, Este de Sudamérica)
			; ***Algunos emuladores usan el bit 1 del BYTE 10 para esto

; Relleno (bytes 10-15)
.byte $00,$00,$00,$00,$00,$00

