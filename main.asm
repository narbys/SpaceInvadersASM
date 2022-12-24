; Credit to ISSOtm for his tutorial

INCLUDE "hardware.inc"
INCLUDE "graphics.asm"

; Player sprite left part
_SPR0_Y		EQU		_OAMRAM	; sprite Y 0 is the beginning of the sprite mem
_SPR0_X		EQU		_OAMRAM+1
_SPR0_NUM	EQU		_OAMRAM+2
_SPR0_ATT	EQU		_OAMRAM+3
; Player sprite right part
_SPR1_Y     EQU     _OAMRAM+4
_SPR1_X     EQU    	_OAMRAM+5
_SPR1_NUM   EQU    	_OAMRAM+6
_SPR1_ATT   EQU    	_OAMRAM+7
; Bullet sprite
_SPR2_Y     EQU     _OAMRAM+8
_SPR2_X     EQU    	_OAMRAM+9
_SPR2_NUM   EQU    	_OAMRAM+10
_SPR2_ATT   EQU    	_OAMRAM+11

SECTION "Header", ROM0[$100]
    jp EntryPoint

    ds $150 - @, 0; Make rooom for the header

EntryPoint:
    ; Don't turn LCD off outside of VBlank
WaitVBlank:
    ld a, [rLY]
    cp 144
    jp c, WaitVBlank

    ; Turn LCD off
    ld a, 0
    ld [rLCDC], a

    ; First, put an empty tile at the start of our background tiles
    ld de, EmptyTile
    ld hl, $9000
    ld bc, EmptyTileEnd -EmptyTile
    call Memcopy
    ; Copy tile data for the invaders (background layer)
    ld de, InvaderTiles
    ; hl should be at the correct address from previous memcopy
    ld bc, InvaderTilesEnd - InvaderTiles
    call Memcopy

    ; Clear the background ($9800-$9BFF)
    ld hl, _SCRN0; Load $9800 into hl
    ld bc, 32*32; Number of tiles in the background map
ClearBkg:
    ld a, 0; Load 0 into a
    ld [hli], a
    dec bc
    ld a, b; load b into a
    or a, c; or b and c, through a
    jp nz, ClearBkg


    ;  Copy the tiledata for player
    ld de, PlayerTiles; Where the data will be copied from
    ld hl, $8000; Where the data will be copied to
    ld bc, PlayerTilesEnd - PlayerTiles; How many bytes we need to copy
    call Memcopy; Call our memory copy function

    ; Copy the tiledata for the bullet
    ld de, BulletTiles
    ; hl should be at the correct location from last memcopy
    ld bc, BulletTilesEnd - BulletTiles
    call Memcopy

    ; Clear the OAM
    ld a, 0 ; Load 0 into a
    ld b, 160 ; Load the amount of memory to clear into b 
    ld hl, _OAMRAM
ClearOam:
    ld [hli], a; Put a (0) into OAM RAM location and increase the memory address afterwards
    dec b; Decrease the amount we need to clear
    jp nz, ClearOam; If this amount is not 0, jump back to keep looping

    ; Draw object (player)
    ld hl, _OAMRAM
    ld a, 130; Y
    ld [hli], a; load Y into OAM and increment address
    ld a, 80 ; X
    ld [hli], a; load X into OAM and increment address
    ld a, 0; Tile ID is 0. Attributes are null
    ld [hli], a; Set sprite ID to 0
    ld [hli], a; Set attributes to null
    ; Second part of ship
    ld a, 130; Y
    ld [hli], a
    ld a, 80+8; X, increased by 8 to fit next to 1st part
    ld [hli], a
    ld a, 1; Tile ID
    ld [hli], a; Set sprite ID to 1
    ld a, 0; Attributes are null
    ld [hli], a;
    ; Bullet
    ld a, 0; Y
    ld [hli], a
    ld a, 0; X
    ld [hli], a
    ld a, 2; Sprite ID is 2
    ld [hli], a
    ld a, 0; Attributes are null
    ld [hl], a

    ; Turn LCD On
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON
    LD [rLCDC], A; Turn LCD on and allow background and objects to be drawn

    ; During the first (blank) frame, initialize display registers
    ld a, $E4
    ld [rBGP], a
    ld a, $E4
    ld [rOBP0], a

    ; Init global variable
    ld a, 0
    ld [wFrameCounter], a

; Main gameloop
Main:
    ; Wait until it is not VBlank
    ld a, [rLY]
    cp 144
    jp nc, Main
WaitVBlank2:
    ld a, [rLY]
    cp 144
    jp c, WaitVBlank2

    ; Check the current keys every frame
    call Input

    ; Update
Update:
    ; Update the player bullet
UpdatePlayerBullet:
    ; If wBulletAlive 
    ld a, [wBulletAlive] 
    and a, 1
    jp z, EndUpdate

    ; Increase the bullet Y
    ld a, [_SPR2_Y]
    sub a, 3; Y goes down, move by 3 pixels
    ; Check if we hit the edge
    cp a, 8
    jp c, DeactivatePlayerBullet; if a < 8
    ld [_SPR2_Y], a
    jp EndUpdate
DeactivatePlayerBullet:
    ld a, 0
    ld [wBulletAlive], a; Set bullet to no longer alive
    ld [_SPR2_Y], a; Set bullet Y to 0
    ld [_SPR2_X], a; Set bullet X to 0
    ; End of update
EndUpdate:

    ; Check if A is pressed
CheckAButton:
    ld a, [wCurKeys]
    and a, PADF_A
    jp z, CheckLeft; If A is not pressed, go to the next check
AButton:
    ; Check if there is already a bullet
    ld a, [wBulletAlive]
    and a, 1
    jp nz, CheckLeft
    ; If not, create new bullet
    ld a, 1
    ld [wBulletAlive], a; set bullet to alive
    ld a, [_SPR1_X]
    ld [_SPR2_X], a; Set X to the same position as the right side of the player sprite
    ld a, [_SPR1_Y]
    sub a, 8
    ld [_SPR2_Y], a; Set Y to 1 tile above the position of the right side of the player sprite

    ; Check if left button is pressed
CheckLeft:
    ld a, [wCurKeys]
    and a, PADF_LEFT
    jp z, CheckRight ; If left isn't pressed, check for right (this is like an else_if)
Left:
    ; Move player to the left
    ld a, [_SPR0_X]
    dec a
    ; Check if we hit the edge of the screen
    cp a, 8
    jp z, Main
    ld [_SPR0_X], a
    ; Make other side of the player sprite follow along
    ld a, [_SPR1_X]
    dec a
    ld [_SPR1_X], a
    jp Main

; Check the right button
CheckRight:
    ld a, [wCurKeys]
    and a, PADF_RIGHT
    jp z, Main
Right:
    ; Move player to the right
    ld a, [_SPR1_X] ; Right side first, to later check the right edge
    inc a
    ; If we hit the right edge don't move
    cp a, 160
    jp z, Main
    ld [_SPR1_X], a
    ; Same for the left side
    ld a, [_SPR0_X]
    inc a
    ld [_SPR0_X], a
    
    jp Main; loop back

;;;;;;;;;;;;;
; Functions ;
;;;;;;;;;;;;;

Memcopy:
    ld a, [de]; load data to be copied into a
    ld [hli], a; set the value of hl to a and increase hl after
    inc de; increment the address of the data we need to copy, so go to the next one
    dec bc; decrement the amount of bytes we have to copy, as we just did one
    ld a, b; load b into a
    or a, c; or b and c together, through a
    jp nz, Memcopy; if previous or is not zero, we are not done copying. redo the loop
    ret

; Taken from ISSOtm's tutorial
Input:
    ; Poll half the controller
    ld a, P1F_GET_BTN
    call .onenibble
    ld b, a ; B7-4=1; B3-0=unpressed buttons

    ; Poll the other half
    ld a, P1F_GET_DPAD
    call .onenibble
    swap a ; A3-0 = unpressed directions; A7-4 = 1
    xor a, b ; A = pressed buttons + directions
    ld b, a ; B = pressed buttons + directions

    ; And release the controller
    ld a, P1F_GET_NONE
    ldh [rP1], a

    ; Combine with previous wCurkeys to make wNewKeys
    ld a, [wCurKeys]
    xor a, b ; A = keys that changed state
    and a, b ; A= keys that changed to pressed
    ld [wNewKeys], a
    ld a, b
    ld [wCurKeys], a
    ret

.onenibble
    ldh [rP1], a; switch the key matrix
    call .knownret ; burn 10 cycles calling a known ret
    ldh a, [rP1] ; ignore value while waiting for the key matrix to settle
    ldh a, [rP1] 
    ldh a, [rP1] ; this read counts
    or a, $F0 ; A7-4=1; A3-0 = unpressed keys
.knownret
    ret

; ;;;;;;;;;;;;
; ; Graphics ;
; ;;;;;;;;;;;;

; PlayerTiles:
;     DB $00,$00,$01,$01,$01,$01,$0F,$0F
;     DB $1F,$1F,$1F,$1F,$1F,$1F,$1F,$1F
;     DB $80,$80,$C0,$C0,$C0,$C0,$F8,$F8
;     DB $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC
; PlayerTilesEnd:

; BulletTiles:
;     DB $80,$80,$80,$80,$80,$80,$80,$80
;     DB $80,$80,$80,$80,$80,$80,$00,$00
; BulletTilesEnd:

;;;;;;;;;;;
; Globals ;
;;;;;;;;;;;

SECTION "Counter", wram0
wFrameCounter : db
SECTION "Keys", wram0
wCurKeys : db
wNewKeys : db

SECTION "PlayerBullet", wram0
wBulletAlive : db