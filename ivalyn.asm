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
; Start our ROM code at memory address $F000
; *******************************************************************
    SEG code
    ORG $f000

Reset:
    CLEAN_START                         ; macro to clear memory

; *******************************************************************
; Set the main display loop and frame rendering
; *******************************************************************