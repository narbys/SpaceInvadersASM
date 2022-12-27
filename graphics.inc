;;;;;;;;;;;;
; Graphics ;
;;;;;;;;;;;;
SECTION "Graphics", rom0
PlayerTiles:
    DB $00,$00,$01,$01,$01,$01,$0F,$0F
    DB $1F,$1F,$1F,$1F,$1F,$1F,$1F,$1F
    DB $80,$80,$C0,$C0,$C0,$C0,$F8,$F8
    DB $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC
PlayerTilesEnd:

BulletTiles:
    DB $80,$80,$80,$80,$80,$80,$80,$80
    DB $80,$80,$80,$80,$80,$80,$00,$00
BulletTilesEnd:

EmptyTile:
    DB $00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00
EmptyTileEnd:

InvaderTiles:
    DB $18,$18,$3C,$3C,$7E,$7E,$DB,$DB
    DB $FF,$FF,$5A,$5A,$81,$81,$42,$42
    DB $30,$30,$78,$78,$FC,$FC,$B6,$B6
    DB $FE,$FE,$B4,$B4,$02,$02,$84,$84
    DB $60,$60,$F0,$F0,$F8,$F8,$6C,$6C
    DB $FC,$FC,$68,$68,$04,$04,$08,$08
    DB $C0,$C0,$E0,$E0,$F0,$F0,$D8,$D8
    DB $F8,$F8,$D0,$D0,$08,$08,$10,$10
    DB $80,$80,$C0,$C0,$E0,$E0,$B0,$B0
    DB $F0,$F0,$A0,$A0,$10,$10,$20,$20
    DB $00,$00,$80,$80,$C0,$C0,$60,$60
    DB $E0,$E0,$40,$40,$20,$20,$40,$40
    DB $00,$00,$00,$00,$80,$80,$C0,$C0
    DB $C0,$C0,$80,$80,$40,$40,$80,$80
    DB $00,$00,$00,$00,$00,$00,$80,$80
    DB $80,$80,$00,$00,$80,$80,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$01,$01
    DB $01,$01,$00,$00,$01,$01,$00,$00
    DB $00,$00,$00,$00,$01,$01,$03,$03
    DB $03,$03,$01,$01,$02,$02,$01,$01
    DB $00,$00,$01,$01,$03,$03,$06,$06
    DB $07,$07,$02,$02,$04,$04,$02,$02
    DB $01,$01,$03,$03,$07,$07,$0D,$0D
    DB $0F,$0F,$05,$05,$08,$08,$04,$04
    DB $03,$03,$07,$07,$0F,$0F,$1B,$1B
    DB $1F,$1F,$0B,$0B,$10,$10,$08,$08
    DB $06,$06,$0F,$0F,$1F,$1F,$36,$36
    DB $3F,$3F,$16,$16,$20,$20,$10,$10
    DB $0C,$0C,$1E,$1E,$3F,$3F,$6D,$6D
    DB $7F,$7F,$2D,$2D,$40,$40,$21,$21
    DB $18,$18,$3C,$3C,$7E,$7E,$DB,$DB
    DB $FF,$FF,$5A,$5A,$81,$81,$42,$42
    DB $00,$00,$01,$01,$01,$01,$0F,$0F
    DB $1F,$1F,$1F,$1F,$1F,$1F,$1F,$1F
    DB $80,$80,$C0,$C0,$C0,$C0,$F8,$F8
    DB $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC    
InvaderTilesEnd: