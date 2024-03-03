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
; [] Black Background
; [] Create Sprite Lookup Tables
; [] Set Color Lookup Tables
; [] Display Mage Locations (Score)
; [] Display Playfield
; [] Display Player
; [] Change Player Equipment
; [] 2D Array???
; [] Display Arrow
; [] Death Screen
; [] Dragon Hit
; [] Magic Missle
; [] Dragon Fire
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
    LDA #$FE                            ; gold into A register (background test)
    STA COLUBK                          ; store gold into background register

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


; *******************************************************************
; Complete ROM size to 4k
; *******************************************************************
    ORG $FFFC                       ; move to position $FFFC
    .word Reset                     ; write 2 bytes with the program reset address
    .word Reset                     ; write 2 bytes with the interruption vector