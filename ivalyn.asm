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

; JUST GET A BLACK SCREEN AND THEN WE WILL GO FROM THERE...
    ORG $F000

Reset
    CLEAN_START

StartFrame
    LDA #$0E
    STA COLUBK
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

    LDX #192
.VisibleFrame:
    LDA #0
    STA WSYNC
    DEX
    BNE .VisibleFrame

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

    JMP StartFrame                      ; jump back to StartFrame

    ORG $FFFC                       ; move to position $FFFC
    .word Reset                     ; write 2 bytes with the program reset address
    .word Reset                     ; write 2 bytes with the interruption vector