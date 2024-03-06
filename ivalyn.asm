    PROCESSOR 6502
;   include required files with VCS register mapping
    INCLUDE "vcs.h"
    INCLUDE "macro.h"
; *******************************************************************
; THE LABRYNTH OF IVALYN
; By CHRIS
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
; [] Item Selection
; [] Display Enemy
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

; *******************************************************************
; Start our ROM code at memory address $F000
; *******************************************************************
    SEG code
    ORG $f000

Reset:
    CLEAN_START                         ; macro to clear memory

; *******************************************************************
; Initialize RAM variables and TIA registers
; *******************************************************************
    LDA #$00                            ; black color
    STA COLUBK                          ; store black into background register

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
VisibleScanlines:
    STA WSYNC                           ; wsync
    DEX                                 ; decrement X
    BNE VisibleScanlines                ; if X > 0 then loop back up

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
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;

Goblin
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;
    .byte #%00000000        ;

Hundling
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