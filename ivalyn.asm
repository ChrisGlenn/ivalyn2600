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
; [] Create Sprite Lookup Tables
; [] Set Color Lookup Tables
; [] Display Score (player's health)
; [] Display Playfield (black background with white playfield)
; [] Display Player
; [] Display Selected Item
; [] Player Movement w/ Boundries
; [] Player Movement SFX
; [] Item Selection
; [] Display Enemy
; [] Enemy Appears SFX/Music
; [] Display Items
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
    ; LDA #$00                            ; black color
    ; STA COLUBK                          ; store black into background register

; *******************************************************************
; Set the main display loop and frame rendering
; *******************************************************************
StartFrame:
    ; game reset using console switch
    ; LSR SWCHB                           ; console input
    ; BCC Reset                           ; reset the game if pressed

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
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;

MagicMissle
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;

Sword
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;

Potion
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;


; *******************************************************************
; Complete ROM size to 4k
; *******************************************************************
    ORG $FFFC                       ; move to position $FFFC
    .word Reset                     ; write 2 bytes with the program reset address
    .word Reset                     ; write 2 bytes with the interruption vector