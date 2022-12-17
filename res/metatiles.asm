; Lista de metatiles

; BLOCK Type (0 - 7)
.byte $00, $00, $00, $00	; Tile $00
.byte $FF, $00, $00, $00	; Tile $01
.byte $FF, $FF, $00, $00	; Tile $02
.byte $FF, $00, $FF, $00	; Tile $03
.byte $FF, $FF, $FF, $00	; Tile $04
.byte $00, $00, $FF, $FF	; Tile $05
.byte $00, $FF, $00, $FF	; Tile $06
.byte $FF, $FF, $FF, $FF	; Tile $07

; Background Type (8 - 255)
.byte $72, $73, $74, $00	; Tile $08 - Lab wall
.byte $79, $7A, $7D, $7E	; Tile $09 - Tube Base
.byte $77, $78, $79, $7A	; Tile $0A - Tube Top
.byte $71, $76, $75, $00	; Tile $0B - Pipe Joint
.byte $76, $76, $00, $00	; Tile $0C - Pipe Horiz
.byte $75, $00, $75, $00	; Tile $0D - Pipe Vert
.byte $00, $00, $7B, $0C	; Tile $0E - Tube Top Broken
.byte $7D, $7E, $7D, $7E	; Tile $0F - Tank..? (two tube bases stacked)
