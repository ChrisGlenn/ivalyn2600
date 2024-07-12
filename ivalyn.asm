    PROCESSOR 6502
;   include required files with VCS register mapping
    INCLUDE "vcs.h"
    INCLUDE "macro.h"
; *******************************************************************
; THE LABRYNTH OF IVALYN
; VI VII - IX IV
; *******************************************************************
; An action game where the player navigates a maze looking for a magic missle
; or sword to defeat the female dragon Ivalyn and save the princess...
; *******************************************************************
; TODO
; [x] Black Background
; [x] Create Sprite Lookup Tables
; [x] Set Color Lookup Tables
; [] Display Playfield (black background with gray playfield)
; [] Display Player
; [] Player Movement w/ Boundries
; [] Player Movement SFX
; [] Mine Location Check/Counter
; [] Enemy Encounter
; [] Display Enemy
; [] Enemy Appears SFX/Music
; [] Combat Screen Change
; [] Display Combat Enemy
; [] Display Equipped Item
; [] Player Combat
; [] Enemy Combat
; [] Player Death
; [] Enemy Death
; [] Pit Display
; [] Pit Escape w/ Rope
; [] Dragon Display
; [] Dragon Combat
; [] Victory 'Screen'
; [] Defeat
;
; Bugs:
;
;

; *******************************************************************
; Declare variables starting from memory address $80
; *******************************************************************
    SEG.U Variables
    ORG $80

stage           byte                    ; 0 is map 1 is combat 2 is death 3 is victory
enemy           byte                    ; 0 is orc 1 is hundling 2 is dragon
hp              byte                    ; player's hit points

; *******************************************************************
; Start our ROM code at memory address $F000
; *******************************************************************
    SEG code
    ORG $F000

Reset:
    CLEAN_START                         ; macro to clear memory

; *******************************************************************
; Initialize RAM variables and TIA registers
; *******************************************************************
    ; static colors
    LDA #$00                            ; black color
    STA COLUBK                          ; store black into background register
    LDA #$0A                            ; gray
    STA COLUPF                          ; store gray into the playfield register
    LDA #$0C                            ; light gray/white
    STA COLUP0                          ; store in player 0 register


; *******************************************************************
; Set the main display loop and frame rendering
; *******************************************************************
StartFrame:
    ; game reset using console switch
    LSR SWCHB                           ; console input
    BCC Reset                           ; reset the game if pressed

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
; *******************************************************************
; VISIBLE SCANLINES
; here's where it gets tricky
; *******************************************************************
    LDX #192                            ; 192 scanlines
.VisibleScanlines:
    STA WSYNC                           ; wsync
    DEX                                 ; decrement X
    BNE .VisibleScanlines                ; if X > 0 then loop back up

; *******************************************************************
; end of visible scanlines
; *******************************************************************
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


; ***************************************
    JMP StartFrame                      ; jump back to StartFrame
; ***************************************

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
    .byte #%00100100        ;   #  #
    .byte #%00101000        ;   # #
    .byte #%00011000        ;    ##
    .byte #%00111010        ;   ### #
    .byte #%01011100        ;  # ###
    .byte #%01011000        ;  # ##
    .byte #%01011000        ;  # ##
    .byte #%00000100        ;      #

PlayerMissle
    .byte #%00000000        ;
    .byte #%01100100        ;  ##  #
    .byte #%01101000        ;  ## #
    .byte #%01011000        ;  # ##
    .byte #%01111010        ;  #### #
    .byte #%01011100        ;  # ###
    .byte #%01011000        ;  # ##
    .byte #%01011000        ;  # ##
    .byte #%00000100        ;      #

Goblin
    .byte #%00000000        ;
    .byte #%00100100        ;   #  #
    .byte #%00101000        ;   # #
    .byte #%00011000        ;    ##
    .byte #%00011000        ;    ##
    .byte #%00111010        ;   ### #
    .byte #%01011100        ;  # ###
    .byte #%00011000        ;    ##
    .byte #%00001000        ;     #

Hundling
    .byte #%00000000        ;
    .byte #%00100100        ;   #  #
    .byte #%00101000        ;   # #
    .byte #%00011000        ;    ##
    .byte #%00011000        ;    ##
    .byte #%00111010        ;   ### #
    .byte #%01011100        ;  # ###
    .byte #%00111100        ;   ####
    .byte #%00011000        ;    ##

Dragon
    .byte #%00000000        ;
    .byte #%00101000        ;   # #
    .byte #%00111000        ;   ###
    .byte #%01111100        ;  #####
    .byte #%11111110        ; #######
    .byte #%11010110        ; ## # ##
    .byte #%11111110        ; #######
    .byte #%11010110        ; ## # ##
    .byte #%10000010        ; #     # 

Rope
    .byte #%00000000        ;
    .byte #%00010000        ;    #
    .byte #%00010000        ;    #
    .byte #%00100000        ;   #
    .byte #%00100000        ;   #
    .byte #%00010000        ;    #
    .byte #%01010100        ;  # # #
    .byte #%00101000        ;   # #
    .byte #%00010000        ;    #

MagicMissle
    .byte #%00000000        ;
    .byte #%00011000        ;    ##
    .byte #%00011000        ;    ##
    .byte #%00011000        ;    ##
    .byte #%00011000        ;    ##
    .byte #%00100100        ;   #  #
    .byte #%00111100        ;   ####
    .byte #%00100100        ;   #  #
    .byte #%00011000        ;    ##

Sword
    .byte #%00000000        ;
    .byte #%00010000        ;    x
    .byte #%00010000        ;    x
    .byte #%00111000        ;   xxx
    .byte #%01010100        ;  x x x
    .byte #%00010000        ;    x
    .byte #%00010000        ;    x
    .byte #%00010000        ;    x
    .byte #%00010000        ;    x

Potion
    .byte #%00000000        ;
    .byte #%00111100        ;   xxxx
    .byte #%01111110        ;  xxxxxx
    .byte #%01111110        ;  xxxxxx
    .byte #%00111100        ;   xxxx
    .byte #%00011000        ;    xx
    .byte #%00011000        ;    xx
    .byte #%00111100        ;   xxxx
    .byte #%00011000        ;    xx

; COLOR TABLES
RopeColour
    .byte #$00              ; black (empty)
    .byte #$E4              ; brown
    .byte #$E4              ; brown
    .byte #$E4              ; brown
    .byte #$E4              ; brown
    .byte #$E4              ; brown
    .byte #$0C              ; silver
    .byte #$0C              ; silver
    .byte #$0C              ; silver

MissleColour
    .byte #$00              ; black (empty)
    .byte #$0E              ; white
    .byte #$0E              ; white
    .byte #$0E              ; white
    .byte #$0E              ; white
    .byte #$0E              ; white
    .byte #$8E              ; light blue
    .byte #$0E              ; white
    .byte #$0E              ; white

SwordColour
    .byte #$00              ; black (empty)
    .byte #$08              ; dark grey
    .byte #$E4              ; brown
    .byte #$08              ; dark grey
    .byte #$0C              ; grey
    .byte #$0C              ; grey
    .byte #$0C              ; grey
    .byte #$0C              ; grey
    .byte #$0C              ; grey

PotionColour
    .byte #$00              ; black (empty)
    .byte #$8E              ; light blue
    .byte #$8E              ; light blue
    .byte #$8E              ; light blue
    .byte #$8E              ; light blue
    .byte #$8E              ; light blue
    .byte #$8E              ; light blue
    .byte #$8E              ; light blue
    .byte #$E8              ; light brown (quark)


; *******************************************************************
; Complete ROM size to 4k
; *******************************************************************
    ORG $FFFC                       ; move to position $FFFC
    .word Reset                     ; write 2 bytes with the program reset address
    .word Reset                     ; write 2 bytes with the interruption vector


; mode: symmetric mirrored line-height 12
;.byte %11110000,%11111111,%11111111 ;|XXXXXXXXXXXXXXXXXXXX| ( 0)
;.byte %01010000,%00000010,%10000001 ;|X X       X X      X| ( 1)
;.byte %01010000,%11101010,%11111101 ;|X X XXX X X X XXXXXX| ( 2)
;.byte %01010000,%10001010,%00000000 ;|X X X   X X         | ( 3)
;.byte %00010000,%10111010,%10111101 ;|X   X XXX X X XXXX X| ( 4)
;.byte %11110000,%10000010,%10110001 ;|XXXXX     X X   XX X| ( 5)
;.byte %00010000,%00111110,%10110111 ;|X     XXXXX XXX XX X| ( 6)
;.byte %01010000,%10100000,%10110001 ;|X X X X     X   XX X| ( 7)
;.byte %01110000,%10101111,%10111101 ;|XXX X X XXXXX XXXX X| ( 8)
;.byte %00010000,%10000010,%10000000 ;|X   X     X        X| ( 9)
;.byte %11110000,%11111010,%11111111 ;|XXXXXXXXX X XXXXXXXX| (10)
;.byte %00010000,%00000010,%11000100 ;|X         X   X   XX| (11)
;.byte %11010000,%11101010,%11010101 ;|X XXXXX X X X X X XX| (12)
;.byte %01010000,%00101000,%00010101 ;|X X   X X   X X X   | (13)
;.byte %00010000,%10101111,%10010001 ;|X   X X XXXXX   X  X| (14)
;.byte %11110000,%11111111,%11111111 ;|XXXXXXXXXXXXXXXXXXXX| (15)