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

; Invader drawloop
DEF INVADER_AMOUNT equ 40
DEF INVADERS_PER_ROW equ 8

SECTION "Header", ROM0[$100]
    jp EntryPoint

    ds $150 - @, 0; Make rooom for the header

EntryPoint:
    ; Don't turn LCD off outside of VBlank
; WaitVBlank:
;     ld a, [rLY]
;     cp 144
;     jp c, WaitVBlank
    call WaitVBlank

    ; Turn LCD off
    xor a;ld a, 0
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
    xor a; ld a, 0; Load 0 into a
    ld [hli], a
    dec bc
    ld a, b; load b into a
    or a, c; or b and c, through a
    jp nz, ClearBkg

    ; Init global variables
    xor a;ld a, 0
    ld [wCurKeys], a
    ld [wFrameCounter], a
    ld [wBulletAlive], a
    ld [wPlayerBulletX], a
    ld [wPlayerBulletY], a
    ld [wInvaderSlide], a; Slide = 0
    ld [wInvadersMovedDown], a
    ld [wInvaderDir], a; 0=right, 1=left
    ld a, _INV_START_X
    ld [wFirstInvaderX], a
    ld a, _INV_START_Y
    ld [wFirstInvaderY], a

    ld a , 1
    ld [wCurrMainTile], a
    xor a;ld a, 0
    ld [wCurrSlideTile], a

    ; Draw a single invader on the background, as a test
    ; ld hl, _SCRN0; Load $9800 into hl again
    ; ld [hl], $01; Tile 1 (the invader tile)

    ld hl, _SCRN0+SCRN_VX_B*_INV_START_Y+_INV_START_X; Load $9800 into hl, + 32*Y+X for startpos in tiles
    ;ld b, 40; 40 invaders to draw
    ;ld c, 8; Amount of invaders per row
    ld de, aInvaderData; Load invaderdata address into DE
    call DrawInvadersInit

    ;Initialise the isAlive data of the array\
    ; ld hl, aInvaderData; Load initial address of invaderdata in D
    ; ld a, $01
    ; rept 40
    ; ld [hli], a; they are alive at the start, set all to 1
    ; endr


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
    xor a;ld a, 0 ; Load 0 into a
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
    xor a;ld a, 0; Tile ID is 0. Attributes are null
    ld [hli], a; Set sprite ID to 0
    ld [hli], a; Set attributes to null
    ; Second part of ship
    ld a, 130; Y
    ld [hli], a
    ld a, 80+8; X, increased by 8 to fit next to 1st part
    ld [hli], a
    ld a, 1; Tile ID
    ld [hli], a; Set sprite ID to 1
    xor a;ld a, 0; Attributes are null
    ld [hli], a;
    ; Bullet
    xor a;ld a, 0; Y
    ld [hli], a
    xor a;ld a, 0; X
    ld [hli], a
    ld a, 2; Sprite ID is 2
    ld [hli], a
    xor a;ld a, 0; Attributes are null
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

    ; ; Check the current keys every frame
    ; call Input

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

    xor a;ld a, 0; Reset wFrameCounter back to 0
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
    ;ld b, 40; 40 invaders
    ;ld c, 8; 8 invaders per row
    call DrawInvaderTiles2
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

    ;ld b, 40
    ;ld c, 8
    call DrawInvaderTiles2
    jp ClearTopInvaderRow

SlideZeroMove:
    ;ld b, 40
    ;ld c, 8
    call DrawInvadersZeroSlide

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
    xor a;ld a, 0
    ld [wInvaderDir], a
MoveRowDown:
    ld a, [wFirstInvaderY]
    inc a
    ld [wFirstInvaderY], a; Increase our Y position
    ld a, 1
    ld [wInvadersMovedDown], a; Set InvaderMovedDown to 1

    ld de, aInvaderData
    rept 40
    ld a, [de]
    ld h, a
    inc de
    ld a, [de]
    ld l, a
    ld bc, 32
    add hl, bc
    ; we now increased our HL by 32 (moved down a row)
    ld a, l
    ld [de], a; put in our L
    dec de; go back
    ld a, h
    ld [de], a; put in our H
    ; Go to address for next one
    inc de
    inc de
    inc de
    endr

    jp IncreaseSlide

ClearTopInvaderRow:
    ; Check if we should clear
    ld a, [wInvadersMovedDown]
    cp 1; if invadersmoveddown==1
    jp nz, IncreaseSlide
    ; Reset our InvadersMovedDown
    xor a;ld a, 0
    ld [wInvadersMovedDown], a
    ; Clear the row above us
    call SetHLToFirstInvaderXY
    ; Go up one row.
    ld a, l ; Load out L into A
    sub SCRN_VX_B; L - 32
    jr nc, :+; See if there is a carry (if L is 00). if not just continue
    dec h; if so, decrease our H
    :
    ; Set the X "component" to 0.
    and %1110_0000
    ld l, a; put our position back into L to get the correct address at HL

    ; hl should now contain the correct position
    ld b, 20; Tiles to clear
    ld a, $00
ClearTiles:
    call WaitForVRamMode
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
    xor a;ld a, 0
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

    ;End of invader update
EndUpdateInvaders:

UpdatePlayerBullet:
    ; If wBulletAlive 
    ld a, [wBulletAlive] 
    cp 0
    jp z, EndUpdatePlayerBullet
    
    call WaitVBlank ; ONLY change OAM during VBlank!!
    ; Increase the bullet Y
    ld a, [_SPR2_Y]
    sub a, 3; Y goes down, move by 3 pixels
    ; Check if we hit the edge
    cp a, 8
    jp c, DeactivatePlayerBullet; if a < 8
    ld [_SPR2_Y], a
    ; Load our bullet XY into variables so we dont have to access OAM in our loop
    ld [wPlayerBulletY], a
    ld a, [_SPR2_X]
    ld [wPlayerBulletX], a

    ;jp EndUpdatePlayerBullet

    ; Check if we hit an invader

    ;Method 1: if we store invader pos in array
    ; We can make an array with 3 bytes per invader: X, Y, isAlive. 
    ; foreach: convert pos to pixel XY instead of tile
    ; Check if bullet pos is within boundaries
    ; if so, set invader to unalive and destroy bullet

    ; Convert each invader VRAM tile to sprite XY
    ld de, aInvaderData; put de to initial invader data
    ld c, INVADER_AMOUNT+1; Invader Data array size / 3 (+1 because we dec C at the start)
    jr InvaderDataLoop
SkipInvaderDataLoop:
    inc de; go to next address
InvaderDataLoop:
    ; check if not the end of InvaderData
    dec c
    ;ld a, c
    ; sub 3; Substract 3 from our size, as every invader exists of 3 elements
    ;cp 0; Check if we reached end of array
    jp z, EndInvaderDataLoop; If so: stop looping
    ;ld c, a;
    ld a, [de]
    ld h, a
    inc de
    ld a, [de]
    ld l, a
    ; HL should now contain our tile address
    inc de
    ld a, [de]
    cp 0; Check if we are not alive
    jp z, SkipInvaderDataLoop; Loop to the next if so
    inc de; Be sure we are already on the correct starting position of our next data for the next loop
ConvertBkgPosToPixelPos:
    ; InvaderX = x*8+8+slide-2*slidedir(-/+)
    ; InvaderY=Y*8+16

    ; Convert VRAM address to pixel XY
    ; (thank you evie)
    ;ld hl, ADDRESS
    ld a, l
    and a, 31 ; mod 32
    ld b, a ; X coord in B
    ld a, l
    rept 5 ; Divides by 32
    rr h
    rra
    endr
    and a, 31 ; mod 32 
    ld l, a ; Y coord back into L
    ld a, b
    ld h, a; X coord back into H


    ; HL is now our tile XY
    ; Convert to pixel XY
    ; X
    ld a, h; x*8
    rept 3
    add a, a
    endr
    add 8; +8
    ld h, a; put X into H
    ; Y
    ld a, l; y*8
    rept 3
    add a, a
    endr
    add 16; +16
    ld l, a
    ; HL now holds our pixel XY
    ; add or dec slide from X
    ld a, [wInvaderDir]
    cp 0
    jp nz, ConvertLeft; if we are not going right, jump to the left conversion
ConvertRight:
    ld a, [wInvaderSlide]
    add h; h(x) + slide
    sub a, 2; -2
    jp StoreInvaderX; We are done converting, store it and move on
ConvertLeft:
    ld a, [wInvaderSlide]
    ld b, a; put slide into b
    ld a, h; put h (x) into a
    sub b; - slide
    add a, 2; +2
StoreInvaderX:
    ld h, a; Store X back into H

    ;H now holds the pixel X and L the pixel Y of the invader
    ;Now we need to check if our bullet XY is within the boundaries of the invader
    ; First, check X

    ; if bulletX >= invader X
    ; && bulletX <= invader X + 8
    ld a, [wPlayerBulletX]; put our bullet X into A
    cp a, h; compare B(invader X) with A
    jr c, InvaderDataLoop; if not >=, it is false so go to next
    ld a, h; put invader X in A
    add a, 8; invader X + 8
    ld h, a; put X back into B
    ld a, [wPlayerBulletX]; put our bullet X into A
    cp a, h; compare X+8 with A
    jr nc, InvaderDataLoop; if not <, it is false and go to next
    ; Our B now no longer holds X, but X+8. But we won't use it anymore so who cares

    ;check Y
    ; if bulletY >= invader Y
    ; if bulletY <= invader Y+8
    ld a, [wPlayerBulletY]; put bullet Y into A
    cp a, l; compare it with our invader Y
    jr c, InvaderDataLoop; if not >=, go to next
    ld a, l; put invader Y in A
    add a, 8; invader Y + 8
    ld l, a; put Y back into L
    ld a, [wPlayerBulletY]; put our bullet Y into A
    cp a, l; compare Y + 8 with A
    jr nc, InvaderDataLoop; if not <, it is false and go to next

    ; If we get here, it hits
    dec de; go back to the last value (which is isalive) of our previous element
    xor a;ld a, 0
    ld [de], a; put isalive to 0
    inc de; Go back to our next element
    jr DeactivatePlayerBullet; our bullet will be deavtivated when hitting an invader
EndInvaderDataLoop:

    jr EndUpdatePlayerBullet
DeactivatePlayerBullet:
    call WaitVBlank
    xor a;ld a, 0
    ld [wBulletAlive], a; Set bullet to no longer alive
    ld [_SPR2_Y], a; Set bullet Y to 0
    ld [_SPR2_X], a; Set bullet X to 0

EndUpdatePlayerBullet:

    ; End of update
EndUpdate:
   
    ; Check the current keys every frame
    call Input
    ; Check if A is pressed
CheckAButton:
    ld a, [wCurKeys]
    and a, PADF_A
    jr z, CheckLeft; If A is not pressed, go to the next check
AButton:
    call WaitVBlank; ONLY change OAM during VBlank!!
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
    call WaitVBlank; ONLY change OAM during VBlank!!
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
    call WaitVBlank; ONLY change OAM during VBlank!!
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

; Initialise invaders, only to be called at the start of the game
; b= amount to draw(40), c=rows(8)
; de= address of invader data
DrawInvadersInit:
    ld b, INVADER_AMOUNT
    ld c, INVADERS_PER_ROW
.drawInvaders
    call WaitForVRamMode
    
    ; Load our data into the Array
    ld a, h
    ld [de], a; Upper part of address our tile is on
    inc de
    ld a, l
    ld [de], a; Lower part of address our tile is on
    inc de
    ld a, 1
    ld [de], a; They are all alive initially
    inc de
    
    ld a, $01
    ld [hl], a; Draw initial tile onto screen
    inc hl; Increase our VRAM position
    ld a, $00;
    ld [hli], a; add whitespace
    dec c
    jp nz, .NextInvaderRowSkipInit; If we still haven't got 8 in our row, don't go to next row
    ld a, b; Store b for now
    ld bc, 16; load the amount of tiles we need to add to go to next row into bc
    add hl, bc; Go to next row
    ld c, 8; Reset C
    ld b, a; Put the original value of b back into b
.NextInvaderRowSkipInit
    dec b; Decrement the amount we need to draw
    jp nz, .drawInvaders; If this amount isn't 0, continue loop
    ret

; A special function to draw for when slide ==0
DrawInvadersZeroSlide:
    ld b, INVADER_AMOUNT
    ld c, INVADERS_PER_ROW
    ld de, aInvaderData
.drawInvaders
    call WaitForVRamMode
    
    ; Load our new data into the Array
    ld a, h
    ld [de], a; Upper part of address our tile is on
    inc de
    ld a, l
    ld [de], a; Lower part of address our tile is on
    inc de
    ; current address of array is our IsAlive
    ; check if invader is alive, if not go to next
    ld a, [de]; a is 00 for not alive and 01 for alive. fits for our tile IDs
    inc de
    
    ;ld a, $01
    ld [hl], a; Draw invader (tile ID 1) onto screen
    dec hl; go to previous tile
    ld a, $00; add whitespace to previous tile
    ld [hli], a
    inc hl
    ld [hli], a; add whitespace to next tile
    dec c
    jr nz, .NextInvaderRowSkipZeroSlide; If we still haven't got 8 in our row, don't go to next row
    ; Move to next row
    ld a, l
    add a, SCRN_VX_B - INVADERS_PER_ROW * 2 ; One invader is two tiles.
    ld l, a
    adc a, h
    sub l
    ld h, a
    ld c, INVADERS_PER_ROW; Reset C
.NextInvaderRowSkipZeroSlide
    dec b; Decrement the amount we need to draw
    jr nz, .drawInvaders; If this amount isn't 0, continue loop
    ret

; hl: Position of first invader
; b: Amount(40) of invaders
; c: Amount(8) of invaders per row
; d: Tile you come from, the one your current X is on
; e: Tile going into the next position, the one being slided
; DrawInvaderTiles:
;     ld b, INVADER_AMOUNT
;     ld c, INVADERS_PER_ROW
; .drawInvaders
;     ld a, d
;     ld [hli], a; Draw invader's current tile onto screen
;     ld a, e; add the slide tile
;     ld [hli], a
;     dec c
;     jr nz, .NextInvaderRowSkip; If we still haven't got 8 in our row, don't go to next row
;     ; Move to next row
;     ld a, l
;     add a, SCRN_VX_B - INVADERS_PER_ROW * 2 ; One invader is two tiles.
;     ld l, a
;     adc a, h
;     sub l
;     ld h, a
;     ld c, INVADERS_PER_ROW; Reset C
; .NextInvaderRowSkip 
;     dec b; Decrement the amount we need to draw
;     jp nz, .drawInvaders; If this amount isn't 0, continue loop
;     ret

    ;A copy of DrawInvaderTiles to work with the array
DrawInvaderTiles2:
    ld a, d
    ld [wCurrMainTile], a
    ld a, e
    ld [wCurrSlideTile], a
    ld de, aInvaderData
    ld b, INVADER_AMOUNT; the amount of invaders = data in the array / 3 (because 3 bytes per invader being X,Y,IsAlive)
    jp .drawInvaders
.skipInvader
    inc de; go to next invader tile
    dec b; decrease for our dead invader
    jr nz, .drawInvaders; if not 0, keep drawing
    ret; otherwise, return
.drawInvaders
    ld a, [de]
    ld h, a
    inc de
    ld a, [de]
    ld l, a
    ; check if left
    ld a, [wInvaderDir]
    cp 0; if a==0
    jp z, .right; if going right, just continue
    dec hl; if going left, decrement hl 
.right
    ; HL is now our main tile's address
    ; Check if we should draw
    inc de; go to next value, this is our IsAlive
    ld a, [de]
    cp 1
    jr nz, .skipInvader; If not 1, go to next one and don't draw current
    inc de; this will now be on the address of the H value for the next invader already
    call WaitForVRamMode
    ld a, [wCurrMainTile]
    ld [hli], a; Draw invader's current tile onto the address our array is on 
    ld a, [wCurrSlideTile]; add the slide tile
    ld [hl], a
    dec b; Decrease invader count
    jr nz, .drawInvaders; if not 0, keep drawing
    ; xor a
    ; cp b; check if reached 0
    ret



SetHLToFirstInvaderXY:
    ; first set HL to SCRN_VX_B*[Y]
    ld h, 0
    ld a, [wFirstInvaderY]
    ld l, a
    ; ld a, [wFirstInvaderY]
    ; ld h, 0
    ; ld l, a
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

WaitVBlank:
    ld a, [rLY]
    cp 144
    jp c, WaitVBlank
    ret

    ; Wait until we are in LCD mode 0 or 1, so we can write to VRAM without it being locked
WaitForVRamMode:
    ldh a, [rSTAT]
    and STATF_BUSY; STATF_BUSY is equal to %10
    jr nz, WaitForVRamMode
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
wPlayerBulletX: DB
wPlayerBulletY: DB

SECTION "Invaders", wram0
wInvaderSlide : db
wInvaderDir: db ; 0= right, 1= left
wInvadersMovedDown: db
wFirstInvaderX: db
wFirstInvaderY: db
wCurrMainTile: db
wCurrSlideTile: db

SECTION "InvaderData", wram0
aInvaderData: ds 120; Array for invader Data.\

