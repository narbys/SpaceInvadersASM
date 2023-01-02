; Credit to ISSOtm for his tutorial

INCLUDE "hardware.inc"
INCLUDE "graphics.inc"

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

; Invader start positions
_INV_START_X EQU 2
_INV_START_Y EQU 2

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
    ld bc, 16; Size of a tile
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


    ; Init global variables
    ld a, 0
    ld [wFrameCounter], a
    ld [wInvaderSlide], a; Slide = 0
    ld [wInvadersMovedDown], a
    ld [wInvaderDir], a; 0=right, 1=left
    ld a, _INV_START_X
    ld [wFirstInvaderX], a
    ld a, _INV_START_Y
    ld [wFirstInvaderY], a

    ; Draw a single invader on the background, as a test
    ; ld hl, _SCRN0; Load $9800 into hl again
    ; ld [hl], $01; Tile 1 (the invader tile)

    ld hl, _SCRN0+SCRN_VX_B*_INV_START_Y+_INV_START_X; Load $9800 into hl, + 32*Y+X for startpos in tiles
    ld b, 40; 40 invaders to draw
    ld c, 8; Amount of invaders per row
    call DrawInvadersInit

; DrawInvadersInit:
;     ld a, $01
;     ld [hli], a; Draw invader (tile ID 1) onto screen
;     ld a, $00; add whitespace
;     ld [hli], a
;     dec c
;     jp nz, NextInvaderRowSkipInit; If we still haven't got 8 in our row, don't go to next row
;     ld a, b; Store b for now
;     ld bc, 16; load the amount of tiles we need to add to go to next row into bc
;     add hl, bc; Go to next row
;     ld c, 8; Reset C
;     ld b, a; Put the original value of b back into b
; NextInvaderRowSkipInit:    
;     dec b; Decrement the amount we need to draw
;     jp nz, DrawInvadersInit; If this amount isn't 0, continue loop

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
UpdateInvaders:
    ; Move on a timer
    ld a, [wFrameCounter]
    inc a; Increment wframecounter
    ld [wFrameCounter], a
    cp a, 30; Every N frames run following code
    jp nz, EndUpdateInvaders

    ld a, 0; Reset wFrameCounter back to 0
    ld [wFrameCounter], a

    ; ld d, $01; Our tile ID
    ; ld e, $00; Next tile ID

CheckInvaderDir:
    call SetHLToFirstInvaderXY
    ld a, [wInvaderSlide]
    cp a, 0 ; If slide == 0
    jp z, SlideZero;
    ; Otherwise, Check in which direction we are going
    ld a, [wInvaderDir]
    cp a, 0 ; Check if we are going right
    jp z, InvaderDirRight
    cp a, 1 ; Check if we are going left instead
    jp z, InvaderDirLeft
InvaderDirRight:
    ; Tile 1
    ld a, [wInvaderSlide]
    ld d, a 
    ld a, $11; Tile ID + 16
    sub a, d ; - invaderSlide
    ld d, a
    ; Tile 2
    ld a, [wInvaderSlide] 
    ld e, a
    ld a, $09
    sub a, e ; - invaderSlide
    ld e, a 
    jp MoveInvaders

InvaderDirLeft:
    ; Tile 1
    ld a, [wInvaderSlide]
    ld d, a 
    ld a, $01;
    add a, d ; + invaderSlide
    ld d, a
    ; Tile 2
    ld a, [wInvaderSlide] 
    ld e, a
    ld a, $09
    add a, e ; + invaderSlide
    ld e, a 
    jp MoveInvadersLeft

SlideZero:
    ld d, $01; Our tile ID
    ld e, $00; Next tile ID
    jp SlideZeroMove
MoveInvaders:
    ld b, 40; 40 invaders
    ld c, 8; 8 invaders per row
    call DrawInvaderTiles
    jp ClearTopInvaderRow
MoveInvadersLeft:
    dec hl; Start from the tile left of our position
    ; swap D and E
    ld a, d;
    ld b, a; store d into b
    ld a, e;
    ld d, a; load e into d
    ld a, b;
    ld e, a; load the previous d into e

    ld b, 40
    ld c, 8
    call DrawInvaderTiles
    jp ClearTopInvaderRow

SlideZeroMove:
    ld b, 40
    ld c, 8
    call DrawInvadersInit

    ; Check if we hit the left edge
    ld a, %0001_1111
    call SetHLToFirstInvaderXY
    and a, l; get the lower 5 bits of L to know our X position
    cp a, 0; Look if this X is 0
    jp z, ChangeDirToRight
    ld a, l; Get our L again
    add $0E; add 15 to it, to get the position of the last invader in the row
    ld d, a; Store this value in D
    ld a, %0001_1111
    and a, d; Get the lower 5 bits of D for the X position 
    cp a, 19; Check if this X is 19, the last tile on our screen
    jp z, ChangeDirToLeft
    jp ClearTopInvaderRow

ChangeDirToLeft:
    ld a, 1
    ld [wInvaderDir], a
    jp MoveRowDown
ChangeDirToRight:
    ld a, 0
    ld [wInvaderDir], a
MoveRowDown:
    ld a, [wFirstInvaderY]
    inc a
    ld [wFirstInvaderY], a; Increase our Y position
    ld a, 1
    ld [wInvadersMovedDown], a; Set InvaderMovedDown to 1
    jp IncreaseSlide

ClearTopInvaderRow:
    ; Check if we should clear
    ld a, [wInvadersMovedDown]
    cp 1; if invadersmoveddown==1
    jp nz, IncreaseSlide
    ; Reset our InvadersMovedDown
    ld a, 0
    ld [wInvadersMovedDown], a
    ; Clear the row above us
    call SetHLToFirstInvaderXY
    ld a, l
    sub a, 32; Get tile above us
    and a, %1110_0000; Set last 5 bits (X position) to 0
    ld l, a
    ; hl should now contain the correct position
    ld b, 20; Tiles to clear
    ld a, $00
ClearTiles:
    ld [hli], a
    dec b
    jp nz, ClearTiles

IncreaseSlide:
    ; After moving, Increase our Slide
    ld a, [wInvaderSlide]
    inc a
    ld [wInvaderSlide], a
    ; If we shifted 8 times, reset
    cp a, 8
    jp nz, EndUpdateInvaders ; Skip reset slide and moving the X pos, skip to end of update
    ; Reset Slide
    ld a, 0
    ld [wInvaderSlide], a
    ; Increase/Decrease the X pos of our initial invader
    ; Check if we are going right, otherwise decrease
    ld a, [wInvaderDir]
    cp a, 0 ; If direction == 0
    jp nz, DecreaseFirstInvaderX

    ld a, [wFirstInvaderX]
    inc a ; X++
    ld [wFirstInvaderX], a ; Put the value back in the variable
    jp EndUpdateInvaders

DecreaseFirstInvaderX:
    ld a, [wFirstInvaderX]
    dec a ; X--
    ld [wFirstInvaderX], a ; Put the value back in the variable

EndUpdateInvaders:
UpdatePlayerBullet:
    ; If wBulletAlive 
    ld a, [wBulletAlive] 
    and a, 1
    jp z, EndUpdatePlayerBullet

    ; Increase the bullet Y
    ld a, [_SPR2_Y]
    sub a, 3; Y goes down, move by 3 pixels
    ; Check if we hit the edge
    cp a, 8
    jp c, DeactivatePlayerBullet; if a < 8
    ld [_SPR2_Y], a
    jp EndUpdatePlayerBullet
DeactivatePlayerBullet:
    ld a, 0
    ld [wBulletAlive], a; Set bullet to no longer alive
    ld [_SPR2_Y], a; Set bullet Y to 0
    ld [_SPR2_X], a; Set bullet X to 0
EndUpdatePlayerBullet:
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


DrawInvadersInit:
    ld a, $01
    ld [hld], a; Draw invader (tile ID 1) onto screen
    ld a, $00; add whitespace to previous tile
    ld [hli], a
    inc hl
    ld [hli], a; add whitespace to next tile
    dec c
    jp nz, .NextInvaderRowSkipInit; If we still haven't got 8 in our row, don't go to next row
    ld a, b; Store b for now
    ld bc, 16; load the amount of tiles we need to add to go to next row into bc
    add hl, bc; Go to next row
    ld c, 8; Reset C
    ld b, a; Put the original value of b back into b
.NextInvaderRowSkipInit    
    dec b; Decrement the amount we need to draw
    jp nz, DrawInvadersInit; If this amount isn't 0, continue loop
    ret

; hl: Position of first invader
; b: Amount(40) of invaders
; c: Amount(8) of invaders per row
; d: Tile you come from, the one your current X is on
; e: Tile going into the next position, the one being slided
DrawInvaderTiles:
    ld a, d
    ld [hli], a; Draw invader's current tile onto screen
    ld a, e; add the slide tile
    ld [hli], a
    dec c
    jp nz, .NextInvaderRowSkip; If we still haven't got 8 in our row, don't go to next row
    ld a, b; Store b for now
    ld bc, 16; load the amount of tiles we need to add to go to next row into bc
    add hl, bc; Go to next row
    ld c, 8; Reset C
    ld b, a; Put the original value of b back into b
.NextInvaderRowSkip 
    dec b; Decrement the amount we need to draw
    jp nz, DrawInvaderTiles; If this amount isn't 0, continue loop
    ret

SetHLToFirstInvaderXY:
    ; first set HL to SCRN_VX_B*[Y]
    ld h, 0
    ld a, [wFirstInvaderY]
    ld l, a
    ld a, [wFirstInvaderY]
    ld h, 0
    ld l, a
    rept 5; a*32
    add hl, hl
    endr
    ; set BC to [X], then add to HL
    ld b, 0
    ld a, [wFirstInvaderX]
    ld c, a
    add hl, bc
    ; set BC to _SCRN0, then add to HL
    ld bc, _SCRN0
    add hl, bc
    ret


;;;;;;;;;;;
; Globals ;
;;;;;;;;;;;

SECTION "Counter", wram0
wFrameCounter : DB

SECTION "Keys", wram0
wCurKeys : DB
wNewKeys : DB

SECTION "PlayerBullet", wram0
wBulletAlive : DB

SECTION "Invaders", wram0
wInvaderSlide : db
wInvaderDir: db ; 0= right, 1= left
wInvadersMovedDown: db
wFirstInvaderX: db
wFirstInvaderY: db

