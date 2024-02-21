    PROCESSOR 6502
; *******************************************************************
; AZYRYN
; By CHRIS
; *******************************************************************
; An action game where the player 'runs' right encountering various
; *******************************************************************
;   TODO:
;   [x] Display Background Colour
;   [x] Set Alpha Symbol Lookup Tables
;   [x] Display Basic Playfield
;   [x] Playfield Color
;   [x] Display Player (Azyryn)
;   [x] Setup Basic Stage Implementation
;   [x] Display Obstacle
;   [x] Game Start (no music)
;   [x] Player Animation (running)
;   [x] Player Jumping
;   [x] Player Moving & Jumping (New Input Based)
;   [x] Obstacle Spawn Countdown
;   [x] Switch Jump Button to 'UP'
;   [x] Obstacle Spawn
;   [x] Obstacle Movement
;   [x] Obstacle Player Collision
;   [x] Player Death Alpha
;   [x] Obstacle Shoot Timer
;   [ ] Obstacle Missle
;   [ ] Random Number Generation
;   [ ] Random Number Timer
;   [ ] Display Random Enemy Type
;   [ ] Player Shooting
;   [ ] Obstacle Death/Score Increment
;   [ ] Display Player Score
;   [ ] Boss Display w/ Scaling
;   [ ] Boss Stop Player Movement
;   [ ] Boss Bullet Collision
;   [ ] Boss Missle
;   [ ] Boss Death
;   [ ] Player Death
;   [ ] SFX Shooting/EnemyShooting/Hits
;   [ ] Scrolling Playfield
;   [ ] Game Color Palette Update
;   [ ] Player Sprite Update
;
;
;   Bugs:
;   [ ] Enemy X wrap around
;   [-] WSYNC placement
;
;
; *******************************************************************
; *******************************************************************
;   include required files with VCS register mapping
; *******************************************************************
    INCLUDE "vcs.h"
    INCLUDE "macro.h"

; *******************************************************************
; Declare variables starting from memory address $80
; *******************************************************************
    SEG.U Variables
    ORG $80

stage           byte                    ; game stage (0 is game, 1 is boss)
score           byte                    ; player's score
musicOn         byte                    ; checks if music is playing
sndTimer        byte                    ; sound timer
PFLine          byte                    ; 0 to 12 then updates the PFSeg
PFSeg           byte                    ; 0 to 8 then restarts again corresponds to each 12 line segment
playerFr        byte                    ; player animation frame for running
pFrCount        byte                    ; player frame counter
playerX         byte                    ; player's X position
playerY         byte                    ; player's Y position
moving          byte                    ; if player is moving or not
jumping         byte                    ; player jump check (bool: starts false)
jumpTmr         byte                    ; jump timer
obstcleDisp     byte                    ; obstacle display (bool: starts false)
obstclType      byte                    ; obstacle type (0 is tower, 1 is ball)
obsSpwnTmr      byte                    ; obstacle spawn timer
obstclTmr       byte                    ; obstacle timer
ObstclX         byte                    ; obstacle X pos
ObstclY         byte                    ; obstacle Y pos
ObMissX         byte                    ; obstacle missle X position
ObMissY         byte                    ; obstacle missle Y position
PlayFldP        word                    ; playfield 0 pointer
PlyFldCP        word                    ; playfield color pointer
PlyrSprP        word                    ; player sprite pointer
ObstSprP        word                    ; obstacle sprite pointer
; constants
PLAYER_HEIGHT = 11                      ; set the sprite height
SPRITE_HEIGHT = 8                       ; obstacle/boss height
MUSIC_LENGTH = 20                       ; the length for music notes to play
SFX_LENGTH = 4                          ; the length for SFX to play

; *******************************************************************
; Start our ROM code at memory address $F000
; *******************************************************************

    SEG code
    ORG $F000                           ; set program orgin to $F000

Reset:
    CLEAN_START                         ; macro to clear memory

; *******************************************************************
; Initialize RAM variables and TIA registers
; *******************************************************************
    ; game variables
    LDA #20                             ; load 30 into A
    STA jumpTmr                         ; store 30 into jump timer
    LDA #60                             ; load 80 into A
    STA obsSpwnTmr                      ; store 80 into obstacle spawn timer DEBUG
    STA obstclTmr                       ; store 80 into obstacle timer DEBUG
    ; background/playfield variables
    LDA #$0E                            ; load a white/grey *ALPHA*
    STA COLUPF                          ; set the playfield color *ALPHA*
    ; player/obstacle/boss variables
    LDA #$0E                            ; load white/grey into A
    STA COLUP0                          ; store A into P0 colour register
    LDA #14                             ; load 20 into A
    STA playerX                         ; store A into player X position
    LDA #143                            ; load 143 into A (all the way to the right)
    STA ObstclX                         ; store 143 into obstacle X position
    LDA #14                             ; load 10 into A
    STA playerY                         ; store A into player Y position
    STA ObstclY                         ; store A into obstacle Y position
    ; pointers
    LDA #<PfldSpr                       ; load playfield 0 table
    STA PlayFldP                        ; lo-byte pointer for playfield 0 lookup table
    LDA #>PfldSpr
    STA PlayFldP+1                      ; hi-byte pointer for playfield 0 lookup table

    LDA #<PlayfieldColor                ; load playfield color table
    STA PlyFldCP                        ; lo-byte pointer for playfield 2 lookup table
    LDA #>PlayfieldColor
    STA PlyFldCP+1                      ; hi-byte pointer for playfield 2 lookup table

    LDA #<Player                        ; load player table
    STA PlyrSprP                        ; lo-byte pointer for player lookup table
    LDA #>Player                
    STA PlyrSprP+1                      ; hi-byte pointer for player lookup table
    
    LDA #<ObstacleA                     ; load obstacle A table
    STA ObstSprP                        ; lo-byte pointer for obstacle A lookup table
    LDA #>ObstacleA                     
    STA ObstSprP+1                      ; hi-byte pointer for obstacle A lookup table

; *******************************************************************
; Declare Macros to Display Missles 0 and 1
; *******************************************************************
    MAC DRAW_P_MISSLE
    ENDM

    MAC DRAW_P1_MISSLE
        LDA #%00000000                  ; store empty bit into A
        CPX ObMissY                     ; compare current scanline with Object Missle Y position
        BNE .SkipP1Missle               ; if it's not at the Y coord, skip drawing the missle
.DrawP1Missle
        LDA #%00000010                  ; toggle bit store into A
        DEC ObMissX                     ; decrement obstacle missle X position
.SkipP1Missle
        STA ENAM1                       ; store A value in P1 Missle register
    ENDM




; *******************************************************************
; Set the main display loop and frame rendering
; *******************************************************************
StartFrame:
    ; game reset using console switch
    LSR SWCHB                           ; console input
    BCC Reset                           ; reset the game if pressed
    ; horizontal positioning
    LDA playerX                         ; load player X position
    LDY #0                              ; 0 is player 0 (THEE player)
    JSR SetObjectXPos                   ; jump to SetObjectXPos subroutine
    LDA ObstclX                         ; load obstacle X position
    LDY #1                              ; 1 is player 1 (obstacle)
    JSR SetObjectXPos                   ; jump to SetObjectXPos subroutine
    LDA ObMissX                         ; load obstacle missile X po
    LDY #3                              ; 3 is player 1 missle
    JSR SetObjectXPos                   ; jump to SetObjectXPos subroutine

    LDA #0                              ; set A to 0
    STA WSYNC                           ; strobe WSYNC
    STA HMOVE                           ; apply the horizontal offsets previously set

    ; DISPLAY VSYNC AND VBLANK
    LDA #2
    STA VSYNC                           ; turn on vsync
    STA VBLANK                          ; turn on vblank

   ; display 3 lines of WSYNC
    LDX #3
.LoopWSYNC:
    STA WSYNC
    DEX
    BNE .LoopWSYNC
    LDA #0
    STA VSYNC                           ; turn off vsync

    ; output VBLANK
    LDX #37                             ; x = 37
.LoopVBlank:
    STX WSYNC                           ; wait for next scanline
    DEX                                 ; x--
    BNE .LoopVBlank                     ; loop while x > 0
    LDA #0
    STA VBLANK                          ; turn off VBLANK


; *******************************************************************
; VISIBLE SCANLINES
; here's where it gets tricky
; *******************************************************************
    LDX #96                             ; load X with 192 for each scanline (96 for 2 line kernal)
VisibleScanlines:
    ; PLAYFIELD
    LDY PFSeg                           ; load PFSeg into Y
    LDA (PlyFldCP),Y
    STA COLUPF
    LDA (PlayFldP),Y                    ; load the playfield segment at Y
    STA PF0
    STA PF1
    STA PF2
    ; start cycling through the PFLine/PFSeg counters
    LDA PFLine                          ; load PFLine (which tracks which scanline it's on)
    CMP #7                              ; compare with 4
    BEQ .PFAdv                          ; if 8 jump to PFAdv
    INC PFLine                          ; else increase PFLine by 1
    JMP .PFOver                         ; then jump to the final PFOver
.PFAdv
    LDA PFSeg                           ; load PFSeg
    CMP #11                             ; compare to 11
    BEQ .PFSegAdv                       ; if 11 then jump to seg advance
    LDA #0                              ; load 0 into the accumultaor
    STA PFLine                          ; reset the PFLine
    INC PFSeg                           ; else crease PFSeg by 1
    JMP .PFOver                         ; jump to PFOver
.PFSegAdv
    LDA #0                              ; load 0 into A
    STA PFLine                          ; store 0 into PFLine resetting it
    STA PFSeg                           ; store 0 into PFSeg resetting it
.PFOver
    ; END OF PLAYFIELD

; GAME LEVEL
; the player is standing stationary, nothing is happening
; if the player presses right then they will be moving along with any enemies
; that may be spawning
.GameStart
    DRAW_P1_MISSLE                      ; draw player 1 (obstacle) missle
    ; check if game is set to game start if not then advance
    LDA stage                           ; load stage into A
    BNE .GameBoss                       ; if stage != 0 then jump to Game Boss
    ; DRAW PLAYER 0
.S0Player0YCheck
    TXA                                 ; transfer X to A (current scanline count)
    SEC                                 ; set carry flag
    SBC playerY                         ; subtract player Y from X
    CMP PLAYER_HEIGHT                   ; compare with player_height constant (11)
    BCC .S0DrawPlayer                   ; jump to the draw player subroutine
    LDA #0                              ; else set lookup index to 0
.S0DrawPlayer
    TAY                                 ; transfer A to Y
    LDA (PlyrSprP),Y                    ; load player bitmap data from lookup table
    STA GRP0                            ; set graphics for player 0 (player)
    ; END DRAWING PLAYER 0
    ; check for drawing Obstacle
    LDA obstcleDisp                     ; load obstacleDisp into A
    BEQ .NoOb                           ; if 0 (false) skip drawing obstacle
    ; DRAW OBSTACLE
.ObstacleYCheck
    TXA                                 ; transfer X (current scanline) to A
    SEC                                 ; set carry flag
    SBC ObstclY                         ; subtract obstacle 1 Y from X
    CMP SPRITE_HEIGHT                   ; compare with SPRITE_HEIGHT
    BCC .DrawObstacle                   ; jump to draw obstacle subroutine
    LDA #0                              ; else set lookup index to 0
.DrawObstacle
    TAY                                 ; transfer A to Y
    LDA (ObstSprP),Y                    ; load obstacle bitmap data from lookup table
    ;STA WSYNC                          ; wait for scanline
    STA GRP1                            ; set graphics for player 1 (obstacle)
    ; END DRAW OBSTACLE
.NoOb                                   ; no object
    JMP .GameLoop                       ; jump to game loop to finish frame

; GAME BOSS FIGHT
; Boss appears and fires random enemies at the player to dodge
; the player shoots at the boss and once it's health is 0 then
; the game increments the obstacle speed modifier and loops back to Game Start
.GameBoss
    STA WSYNC
    LDA stage                           ; load stage into A
    CMP #1                              ; compare with 1
    BNE .GameLoop                       ; if stage != 1 then jump to Death
.GameLoop
    LDA #0                              ; reset A to 0
    STA WSYNC
    DEX                                 ; decrement X
    BNE VisibleScanlines                ; loop back up to the start of VisibleScanlines if not 0

; *******************************************************************
; end of visible scanlines
; *******************************************************************
    ; DISPLAY OVERSCAN
    LDA #2
    STA VBLANK                          ; turn ON VBLANK
    LDX #30                             ; display 30 lines of VBLANK
.LoopOverscan
    STA WSYNC
    DEX
    BNE .LoopOverscan
    LDA #0
    STA VBLANK                          ; turn OFF VBLANK

; *******************************************************************
; Process joystick input for player0
; right to start the game and button to jump(also fire during the boss fight)
; *******************************************************************
CheckP0Right:
    LDA #%10000000
    BIT SWCHA
    BNE .P0RightNull                    ; if right is not pressed then skip
    LDA stage                           ; load stage into A
    CMP #0                              ; compare with 0
    BNE CheckButtonPressed              ; if != 0 then skip right check
.P0RightPressed
    LDA #1                              ; load 1 into accumulator
    STA moving                          ; set moving to 1 (true)
    JMP CheckButtonPressed              ; jump to CheckButtonPressed
.P0RightNull
    LDA #0                              ; load 0 into A
    STA moving                          ; set moving to 0 (false)
CheckP0Up:
    LDA #%00010000                      
    BIT SWCHA
    BNE EndInputCheck                   ; if INPT4 is not hit then skip check
    LDA jumpTmr                         ; load jump timer into A
    CMP #20                             ; compare with 30
    BNE EndInputCheck                   ; if jump timer != 60 then jump to end input check
.P0up
    LDA #1                              ; load 1 into A
    STA jumping                         ; store 1 into jumping (true)
CheckButtonPressed:
    ; FIRE A MISSLE CODE GOES HERE
    ; FIRE A MISSLE CODE GOES HERE
.ButtonPressed

EndInputCheck:


; *******************************************************************
; Player animation
; running and jumping animation
; *******************************************************************
    LDA jumping                         ; check for jumping by load jumping into A
    CLC                                 ; clear the carry flag
    CMP #1                              ; check if jumping is 1
    BEQ .FrameJ                         ; if so then jump to FrameJ (jumping frame)
    LDA moving                          ; load moving into A
    CLC                                 ; clear the carry flag
    CMP #1                              ; compare with 1
    BNE .StillAnim                      ; if != 1 then jump to StillAnim
    LDA pFrCount                        ; load pFrCount
    CMP #7                              ; compare with 7
    BEQ .AdvCount                       ; if 7 then go to advance
    INC pFrCount                        ; otherwise inc
    JMP .EndAnim                        ; jump to end anim
.AdvCount
    LDA #0                              ; load 0
    STA pFrCount                        ; reset pFrCount to 0
    LDA playerFr                        ; load playerFr
    CMP #0                              ; compare with 0
    BEQ .Frame0                         ; if 0 then jump to frame 0
    JMP .Frame1                         ; else jump to frame 1
.Frame0
    ; pointer
    LDA #<PlayRunF0                     ; load player table
    STA PlyrSprP                        ; lo-byte pointer for player lookup table
    LDA #>PlayRunF0                
    STA PlyrSprP+1                      ; hi-byte pointer for player lookup table
    LDA #1                              ; load 1 into A
    STA playerFr                        ; playerFr equals 1
    JMP .EndAnim                        ; jump to end anim
.Frame1
    ; pointer
    LDA #<PlayRunF1                     ; load player table
    STA PlyrSprP                        ; lo-byte pointer for player lookup table
    LDA #>PlayRunF1                
    STA PlyrSprP+1                      ; hi-byte pointer for player lookup table
    LDA #0                              ; load 0 into A
    STA playerFr                        ; playerFR equals 0
    JMP .EndAnim
.FrameJ
    ; pointer
    LDA #<PlayJump                      ; load player table
    STA PlyrSprP                        ; lo-byte pointer for player lookup table
    LDA #>PlayJump                 
    STA PlyrSprP+1                      ; hi-byte pointer for player lookup table
    LDA #24
    STA playerY
    JMP .EndAnim
.StillAnim
    ; pointer
    LDA #<Player                        ; load player table
    STA PlyrSprP                        ; lo-byte pointer for player lookup table
    LDA #>Player                
    STA PlyrSprP+1                      ; hi-byte pointer for player lookup table
    JMP .EndAnim                        ; jump to end animation
.EndAnim

; player jumping timer
    LDA jumping                         ; load jumping into A
    CMP #1                              ; compare A with 1
    BNE .JumpReturn                     ; if player is NOT jumping jump to jumpReturn
    LDA jumpTmr                         ; load jumpTmr into A
    CMP #0                              ; compare A with 0
    BNE .JumpIn                         ; if A is NOT 0 then goto JumpIn
    JMP .JumpReset                      ; else goto jumpReset to reset the jump timer
.JumpIn
    DEC jumpTmr                         ; decrement jumpTmr (jump timer)
    JMP .JumpReturn                     ; jump to jumpreturn
.JumpReset
    LDA #14                             ; load 14 into A
    STA playerY                         ; store A into playerY (grounding the player)
    LDA #20                             ; load 30 into A
    STA jumpTmr                         ; store A into jumpTmr (jump timer)
    LDA #0                              ; load 0 into A
    STA jumping                         ; store 0 into jumping (false)
.JumpReturn


; *******************************************************************
; Obstacle Control
; *******************************************************************
ObstacleSprite:
.Turret
.Orb

; Obstacle Countdown Timer
; only operates when moving
ObstacleSpawn:
    LDA moving                          ; load moving into A
    CLC                                 ; clear carry flag
    BEQ .ObstacleOut                    ; if 0 then skip countdown
    LDA obstcleDisp                     ; load obstacle display into A
    CLC                                 ; clear carry flag
    CMP #1                              ; compare with 1 (true)
    BEQ .ObstacleOut                    ; if the obstacle is out jump to ObstacleOut
    LDA obsSpwnTmr                      ; load obstacle timer into A
    BEQ .SpawnObstacle                  ; check if equals 0
    DEC obsSpwnTmr                      ; decrement obstclTmr
    JMP .ObstacleOut                    ; jump to obstacle out
.SpawnObstacle
    LDA #1                              ; load 1 into A
    STA obstcleDisp                     ; set obstacle Display to 1 (true)
.ObstacleOut

; obstacle AI (moving, shooting, ect)
ObstacleAIUpdate:
    ; check if obstacle is displaying (true)
    LDA obstcleDisp                     ; load obstacle display into A
    BEQ .EndObUpdate                    ; if 0 (false) skip movement check
    ; countdown the shoot timer
    LDA obstclTmr                       ; load obstacle timer (timer to shoot) int A
    BEQ .ObstacleMovement               ; if A == 0 then skip to ObstacleMovement
    DEC obstclTmr                       ; else decrement obstacle timer (timer to shoot)
.ObstacleMovement
    ; check moving (true) and then move obstacle
    LDA moving                          ; load moving into A
    BEQ .EndObUpdate                    ; if 0 (false) skip movement
    DEC ObstclX                         ; else decrement Obstacle X coord
.EndObUpdate


; *******************************************************************
; Check for object collisions
; between P0 and P1, P0 and M1, P1 and M2
; *******************************************************************
; check collision between player 0 (player) and player 1 (enemy)
CheckCollisionP0P1:
    LDA #%10000000                      ; CXPPMM bit 7 detects P0 and P1 collisions
    BIT CXPPMM                          ; check bit 7 with above pattern
    BNE .P0P1Collision                  ; if collision P0/P1 jump to P0P1Collision
    JMP EndCollisionCheck               ; else jump to collision check
.P0P1Collision
    JSR GameOver                        ; jump to Game Over subroutine
; check collision between player 0 (player) and missle 1 (enemy missle)
CheckCollisionP0M1:
.P0M1Collision
; check collision between player 1 (enemy) and missle 0 (player missle)
CheckCollisionP1M0:
.P1M0Collision

EndCollisionCheck:
    STA CXCLR                           ; clear all collision flags before next frame


; ***************************************
    JMP StartFrame                      ; jump back to StartFrame
; ***************************************




; *******************************************************************
; Subroutine to reset the obstacle missile (M1)
; *******************************************************************
ObstacleShoot SUBROUTINE
    LDA ObstclY                         ; load obstacle Y position into A
    CLC                                 ; clear carry flag
    ADC #8                              ; add 8 to obstacle Y
    RTS                                 ; return from subroutine

; *******************************************************************
; Subroutine to handle object horizontal position with fine offset
; *******************************************************************
; A is the target x-coord position in pixels of our object
; Y is the object type (0:player0, 1:player1, 2:missle0, 3:missle1, 4:ball)
; *******************************************************************
SetObjectXPos subroutine
    sta WSYNC                           ; start a fresh new scanline
    sec                                 ; make sure the carry flag is set before subroutine
.Div15Loop
    sbc #15                             ; subtract 15 from accumulator
    bcs .Div15Loop                      ; loop until carry flag is clear
    eor #7                              ; handle offset range from -8 to 7
    asl
    asl
    asl
    asl                                 ; four shift lefts to get only the top 4 bits
    sta HMP0,Y                          ; store the fine offset to the correct HMxx
    sta RESP0,Y                         ; fix object position in 15 step increment
    rts                                 ; return from subroutine


; *******************************************************************
; Game Over subroutine
; reset the score, stop the game, change player sprite??
; *******************************************************************
GameOver subroutine
    LDA #2                              ; load 2 into A
    STA stage                           ; store 2 into stage (death)
    ; change playfield color pointer
    LDA #<PlayfieldDeathColor           ; load playfield color table
    STA PlyFldCP                        ; lo-byte pointer for playfield 2 lookup table
    LDA #>PlayfieldDeathColor
    STA PlyFldCP+1                      ; hi-byte pointer for playfield 2 lookup table
    RTS                                 ; return from subroutine

; *******************************************************************
; Declare ROM lookup tables
; *******************************************************************
Digits:
    .byte %01110111          ; ### ###
    .byte %01010101          ; # # # #
    .byte %01010101          ; # # # #
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###

    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #

    .byte %01110111          ; ### ###
    .byte %00010001          ;   #   #
    .byte %01110111          ; ### ###
    .byte %01000100          ; #   #
    .byte %01110111          ; ### ###

    .byte %01110111          ; ### ###
    .byte %00010001          ;   #   #
    .byte %00110011          ;  ##  ##
    .byte %00010001          ;   #   #
    .byte %01110111          ; ### ###

    .byte %01010101          ; # # # #
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###
    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #

    .byte %01110111          ; ### ###
    .byte %01000100          ; #   #
    .byte %01110111          ; ### ###
    .byte %00010001          ;   #   #
    .byte %01110111          ; ### ###

    .byte %01110111          ; ### ###
    .byte %01000100          ; #   #
    .byte %01110111          ; ### ###
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###

    .byte %01110111          ; ### ###
    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #

    .byte %01110111          ; ### ###
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###

    .byte %01110111          ; ### ###
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###
    .byte %00010001          ;   #   #
    .byte %01110111          ; ### ###

    .byte %00100010          ;  #   #
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###
    .byte %01010101          ; # # # #
    .byte %01010101          ; # # # #

    .byte %01110111          ; ### ###
    .byte %01010101          ; # # # #
    .byte %01100110          ; ##  ##
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###

    .byte %01110111          ; ### ###
    .byte %01000100          ; #   #
    .byte %01000100          ; #   #
    .byte %01000100          ; #   #
    .byte %01110111          ; ### ###

    .byte %01100110          ; ##  ##
    .byte %01010101          ; # # # #
    .byte %01010101          ; # # # #
    .byte %01010101          ; # # # #
    .byte %01100110          ; ##  ##

    .byte %01110111          ; ### ###
    .byte %01000100          ; #   #
    .byte %01110111          ; ### ###
    .byte %01000100          ; #   #
    .byte %01110111          ; ### ###

    .byte %01110111          ; ### ###
    .byte %01000100          ; #   #
    .byte %01100110          ; ##  ##
    .byte %01000100          ; #   #
    .byte %01000100          ; #   #

Player
    .byte #%00000000        ;
    .byte #%01100110        ;  ##  ##
    .byte #%00100100        ;   #  #
    .byte #%00100100        ;   #  #
    .byte #%01011000        ;  # ##
    .byte #%01010110        ;  # # ##
    .byte #%00100101        ;   #  # #
    .byte #%00011000        ;    ##
    .byte #%00100100        ;   #  #
    .byte #%00101100        ;   # ##
    .byte #%00011000        ;    ##

PlayRunF0
    .byte #%00000000        ;
    .byte #%00000000        ;  
    .byte #%01100011        ;  ##   ##
    .byte #%00100110        ;   #  ##
    .byte #%00011000        ;    ##
    .byte #%00110110        ;   ## ##
    .byte #%00100101        ;   #  # #
    .byte #%00011000        ;    ##
    .byte #%00100100        ;   #  #
    .byte #%00101100        ;   # ##
    .byte #%00011000        ;    ##

PlayRunF1
    .byte #%00000000        ;
    .byte #%00010000        ;    #
    .byte #%00001100        ;     ##
    .byte #%00010100        ;    # #
    .byte #%00011000        ;    ##
    .byte #%01010110        ;  # # ##
    .byte #%01100101        ;  ##  # #
    .byte #%00011000        ;    ##
    .byte #%00100100        ;   #  #
    .byte #%00101100        ;   # ##
    .byte #%00011000        ;    ##

PlayJump
    .byte #%00000000        ;
    .byte #%00000000        ;  
    .byte #%01100011        ;  ##   ##
    .byte #%00100110        ;   #  ##
    .byte #%00011000        ;    ##
    .byte #%01010110        ;  # # ##
    .byte #%01100101        ;  ##  # #
    .byte #%00011000        ;    ##
    .byte #%00100100        ;   #  #
    .byte #%00101100        ;   # ##
    .byte #%00011000        ;    ##

ObstacleA
    .byte #%00000000        ;
    .byte #%01111110        ;  ###### 
    .byte #%00111100        ;   ####
    .byte #%00011000        ;    ##
    .byte #%00011000        ;    ##
    .byte #%00100100        ;   #  #
    .byte #%00011000        ;    ##
    .byte #%00100100        ;   #  #
    .byte #%00100100        ;   #  #

ObstacleB
    .byte #%00000000        ;
    .byte #%00111100        ;   ####
    .byte #%01100110        ;  ##  ##
    .byte #%11011011        ; ## ## ##
    .byte #%10100101        ; # #  # #
    .byte #%10100101        ; # #  # #
    .byte #%11011011        ; ## ## ##
    .byte #%01100110        ;  ##  ##
    .byte #%00111100        ;   ####

Enemy
    .byte #%00000000        ;
    .byte #%00011000        ;    ##
    .byte #%10111101        ; # #### #
    .byte #%01111110        ;  ######
    .byte #%11111111        ; ########
    .byte #%11100111        ; ###  ###
    .byte #%00111100        ;   ####
    .byte #%01000010        ;  #    #
    .byte #%00111100        ;   ####

; player color
; obstacle color
; enemy color

PfldSpr
    .byte #%00000000        ; ( 0)
    .byte #%00000000        ; ( 1)
    .byte #%00000000        ; ( 2)
    .byte #%00110011        ; ( 3)
    .byte #%11111111        ; ( 4)
    .byte #%10111111        ; ( 5)
    .byte #%11111011        ; ( 6)
    .byte #%11011111        ; ( 7)
    .byte #%11111101        ; ( 8)
    .byte #%11111111        ; ( 9)
    .byte #%11111111        ; (10)
    .byte #%11111111        ; (11) 

PlayfieldColor
    .byte #$00              ;
    .byte #$00              ; black
    .byte #$00              ; black
    .byte #$50              ;
    .byte #$50              ;
    .byte #$50              ;
    .byte #$50              ;
    .byte #$50              ;
    .byte #$50              ;
    .byte #$50              ;
    .byte #$58              ;
    .byte #$54              ;

PlayfieldDeathColor
    .byte #$00              ;
    .byte #$00              ; black
    .byte #$00              ; black
    .byte #$04              ; dark grey (buildings)
    .byte #$04              ; dark grey (buildings)
    .byte #$04              ; dark grey (buildings)
    .byte #$04              ; dark grey (buildings)
    .byte #$04              ; dark grey (buildings)
    .byte #$04              ; dark grey (buildings)
    .byte #$04              ; dark grey (buildings)
    .byte #$0C              ; lighter grey (road)
    .byte #$0E              ; light grey (foreground)


; *******************************************************************
; Complete ROM size to 4k
; *******************************************************************
    ORG $FFFC                       ; move to position $FFFC
    .word Reset                     ; write 2 bytes with the program reset address
    .word Reset                     ; write 2 bytes with the interruption vector





; *******************************************************************
; MISC NOTES
; *******************************************************************


; mode: symmetric mirrored line-height 11
; .byte $00,$00,$00 ;|                    | ( 0)
; .byte $00,$00,$00 ;|                    | ( 1)
; .byte $00,$00,$00 ;|                    | ( 2)
; .byte $00,$00,$00 ;|                    | ( 3)
; .byte $00,$00,$F0 ;|                XXXX| ( 4)
; .byte $00,$00,$FC ;|              XXXXXX| ( 5)
; .byte $00,$00,$C6 ;|             XX   XX| ( 6)
; .byte $00,$00,$C6 ;|             XX   XX| ( 7)
; .byte $00,$00,$FE ;|             XXXXXXX| ( 8)
; .byte $00,$00,$7E ;|             XXXXXX | ( 9)
; .byte $00,$00,$FE ;|             XXXXXXX| (10)
; .byte $00,$00,$FC ;|              XXXXXX| (11)
; .byte $00,$00,$50 ;|                X X | (12)
; .byte $00,$00,$00 ;|                    | (13)