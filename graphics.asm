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
    DB $80,$80,$80,$80,$80,$80,$80,$80
    DB $80,$80,$80,$80,$80,$80,$80,$80
InvaderTilesEnd: