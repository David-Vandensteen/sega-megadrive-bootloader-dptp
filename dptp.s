;--------------------------
; David Vandensteen - 2016
;----------------------------

;----------------------
; labels               |
;----------------------
                        ;------------------
VDPC EQU    $C00004     ; VDP Control Port |
VDPD EQU    $C00000     ; VDP Data         |		
                        ;------------------
;----------
;   MACROS
;-------------
align: macro 
    cnop 0,\1
    endm
Disable_Ints: macro
    move #$2700, sr ;disable ints
    endm
Enable_Ints: macro
    move #$2000, sr ;enable ints
    endm
Disable_Display: macro
	move.w 	#$8114, (VDPC)                  ; disable display
    endm
Enable_Display: macro
    move.w  #$8174, (VDPC)                  ;enable display
    endm
;-----    
; VDP 
;----------   
VDP_W_Vram: macro addr, dest   
    move.l  #$40000000|((\addr)&$3FFF)<<16|(\addr)>>14, (\dest)
    endm    
VDP_W_Cram: macro addr, dest   
    move.l  #$C0000000|((\addr)&$3FFF)<<16|(\addr)>>14, (\dest)
    endm
VDP_W_Vsram: macro addr, dest  
    move.l  #$40000010|((\addr)&$3FFF)<<16|(\addr)>>14, (\dest)
    endm
;------------------
;	68k vectors
;---------------------------
	org    $0
    dc.l   $00000000    ; Initial stack pointer value
    dc.l   $00000200    ; Start of our program in ROM
    dc.l   Interrupt    ; Bus error
    dc.l   Interrupt    ; Address error
    dc.l   Interrupt    ; Illegal instruction
    dc.l   Interrupt    ; Division by zero
    dc.l   Interrupt    ; CHK exception
    dc.l   Interrupt    ; TRAPV exception
    dc.l   Interrupt    ; Privilege violation
    dc.l   Interrupt    ; TRACE exception
    dc.l   Interrupt    ; Line-A emulator
    dc.l   Interrupt    ; Line-F emulator
    dc.l   Interrupt    ; Unused (reserved)
    dc.l   Interrupt    ; Unused (reserved)
    dc.l   Interrupt    ; Unused (reserved)
    dc.l   Interrupt    ; Unused (reserved)
    dc.l   Interrupt    ; Unused (reserved)
    dc.l   Interrupt    ; Unused (reserved)
    dc.l   Interrupt    ; Unused (reserved)
    dc.l   Interrupt    ; Unused (reserved)
    dc.l   Interrupt    ; Unused (reserved)
    dc.l   Interrupt    ; Unused (reserved)
    dc.l   Interrupt    ; Unused (reserved)
    dc.l   Interrupt    ; Unused (reserved)
    dc.l   Interrupt    ; Spurious exception
    dc.l   Interrupt    ; IRQ level 1
    dc.l   Interrupt    ; IRQ level 2
    dc.l   Interrupt    ; IRQ level 3
    dc.l   Interrupt    ; IRQ level 4 (horizontal retrace interrupt)
    dc.l   Interrupt    ; IRQ level 5
    dc.l   Interrupt    ; IRQ level 6 (vertical retrace interrupt)
    dc.l   Interrupt    ; IRQ level 7
    dc.l   Interrupt    ; TRAP #00 exception
    dc.l   Interrupt    ; TRAP #01 exception
    dc.l   Interrupt    ; TRAP #02 exception
    dc.l   Interrupt    ; TRAP #03 exception
    dc.l   Interrupt    ; TRAP #04 exception
    dc.l   Interrupt    ; TRAP #05 exception
    dc.l   Interrupt    ; TRAP #06 exception
    dc.l   Interrupt    ; TRAP #07 exception
    dc.l   Interrupt    ; TRAP #08 exception
    dc.l   Interrupt    ; TRAP #09 exception
    dc.l   Interrupt    ; TRAP #10 exception
    dc.l   Interrupt    ; TRAP #11 exception
    dc.l   Interrupt    ; TRAP #12 exception
    dc.l   Interrupt    ; TRAP #13 exception
    dc.l   Interrupt    ; TRAP #14 exception
    dc.l   Interrupt    ; TRAP #15 exception
    dc.l   Interrupt    ; Unused (reserved)
    dc.l   Interrupt    ; Unused (reserved)
    dc.l   Interrupt    ; Unused (reserved)
    dc.l   Interrupt    ; Unused (reserved)
    dc.l   Interrupt    ; Unused (reserved)
    dc.l   Interrupt    ; Unused (reserved)
    dc.l   Interrupt    ; Unused (reserved)
    dc.l   Interrupt    ; Unused (reserved)
    dc.l   Interrupt    ; Unused (reserved)
    dc.l   Interrupt    ; Unused (reserved)
    dc.l   Interrupt    ; Unused (reserved)
    dc.l   Interrupt    ; Unused (reserved)
    dc.l   Interrupt    ; Unused (reserved)
    dc.l   Interrupt    ; Unused (reserved)
    dc.l   Interrupt    ; Unused (reserved)
    dc.l   Interrupt    ; Unused (reserved)

;-----------------------------------------------
; Sega Genesis ROM header                       |
;-----------------------------------------------
    
    dc.b "SEGA MEGA DRIVE_"                         ; Sega string                           16 bytes
    dc.b "(c)RESISTANCE   "                         ; copyright                             16 bytes
                                
    dc.b "DPTP            "                         ; Domestic name                         48 bytes
    dc.b "                "                         ; Domestic name						
    dc.b "                "                         ; Domestic name			
                                
    dc.b "DPTP            "                         ; Overseas name                         48 bytes
    dc.b "                "                         ; Overseas name			
    dc.b "                "                         ; Overseas name			
    
    dc.b "GM 12345678-01"                           ; GM (game), product code and serial	14 bytes		
    dc.b $81, $B4                                   ; Checksum will be here					02 bytes
    dc.b "JD              "                         ; Which devices are supported ?			16 bytes
    dc.b $00, $00, $00, $00                         ; ROM start address	
    dc.l End                                        ; ROM end address will be here	
    
    dc.b $00, $FF, $00, $00                         ; RAM start
    dc.b $00, $FF, $FF, $FF                         ; RAM End     
    dc.b "               "                          ; We don't have a modem, so we fill this with spaces	
    dc.b "                        "                 ; Unused
    dc.b "                         "	
    dc.b "JUE             "                         ; Country								16 bytes

	
; END Sega Genesis ROM header

;------
Entry:                      
;------
    Disable_Ints
;-----
TMSS:
;-----
    move.b ($A10001), d0            ; Move Megadrive hardware version to d0
    and.b #$0F, d0                  ; The version is stored in last four bits, mask it with 0F
    beq.s TMSS_Skip                 ; If version is equal to 0, skip TMSS signature
    move.l #"SEGA", ($A14000)       ; Move the string "SEGA"
TMSS_Skip:
    jsr VDP_Init
    Disable_Display
;-----------
; CLEAR RAM |
;-----------------------------------
; RAM MEMORY MAP $FF0000 -> $FFFFFF |
;-----------------------------------
    lea	$FF0000,a0
    move.l #$00000000, d0   ; 0 for clearing
Clear_Ram_Loop:
    move.l d0,(a0)+
    cmp.l #$FFFFFC, a0
    bne Clear_Ram_Loop
    move.l d0,(a0)

Clear_Cram:
    move.l #$C0000000, (VDPC)       ; write to cram at addr 0
    move.l #63, d0                  ; counter
Clear_Cram_Loop:    
    move.w #$0000, (VDPD)           ; black color
    dbra d0, Clear_Cram_Loop

    
Clear_Vram:
    move.l #$40000000, (VDPC)           ; Point data port to start of vram    
    move.l #$10000/4-1, d0               ; counter
Clear_Vram_Loop:    
    move.l #$00000000, (VDPD)
    dbra d0, Clear_Vram_Loop

;----
; NOT TESTED
;_____________
Clear_Vsram:
    move.l #$40000010, (VDPC)
    move.l #31, d0        ;counter
Clear_Vsram_Loop:
    move.w #$0000, (VDPD)
    dbra d0, Clear_Vsram_Loop

;------
; MAIN |
;------
main:
    jsr VDP_Init
    jsr Scroll_Init_Coord
    lea	Palettes, a0
    jsr Load_Palettes
    
    lea Font_Tiles, a0
    jsr Load_Font
    
    lea Logo_Tiles, a0
    jsr Load_Logo           ; warning no vdp control set (implicit "cue mode")

    lea Logo_Tilemap, a0
    jsr Draw_Tilemap
    
    lea String, a0
    jsr Draw_Text           ; warning no vdp control set (implicit "cue mode")
    
main_loop:
    jsr Vsync_Wait    
    jmp main_loop


    
;-----
; SUB |
;     |
;--------
VDP_Init:
;----------------
	move.w  #$8014, VDPC        ; No HINT, no HV latch
	move.w  #$8174, VDPC        ; Enable Display
	move.w  #$8230, VDPC        ; Field  A: $C000
	move.w  #$8407, VDPC        ; Field  B: $E000
	move.w  #$8578, VDPC        ; Sprites: $F000
	move.w  #$8700, VDPC        ; Background: pal 0, color 0
	move.w  #$8A00, VDPC        ; HInt every scanline
	move.w  #$8B00, VDPC        ; No VINT, full scroll for H+V
	move.w  #$8C81, VDPC        ; H40, no S/H, no interlace
	move.w  #$8D2F, VDPC        ; HScroll: $BC00
	move.w  #$8F02, VDPC        ; Autoincrement: 2 bytes
	move.w  #$9001, VDPC        ; Scroll size: 64x32
	move.w  #$9100, VDPC        ; Hide window plane
	move.w  #$9200, VDPC        ;  "     "      "
    rts
;-----------------
Scroll_Init_Coord:
;-----------------------
    ;Aplan scroll position
    move.l #$7c000002, (VDPC)        ; hscroll
    move.w (PlaneA_pos_x), (VDPD)
    
    move.l #$40000010, (VDPC)        ; vscroll
    move.w (PlaneA_pos_y), (VDPD)
    rts
;------------
Load_Palettes:
;-------------------
    ; a0 -> plalettes 64 words
    
    move.l #$C0000000, (VDPC)     ; write to cram at addr 0
    move.l #63, d0                ; counter 64 colors
Load_Palettes_Loop:	
    move.w (a0)+, (VDPD)
    dbra d0, Load_Palettes_Loop ; decrement d0 ... if d0 = 0 branch to...
    rts		
;--------
Load_Font:
;--------------
    move.l #$40200000, (VDPC)        ; Point data port to start of vram    
    move.l #471, d0                  ; counter ...
                                     ; 8 longs for one char
Load_Font_Loop:
    move.l (a0)+, (VDPD)              
    dbra d0, Load_Font_Loop
    rts
;------
Load_Logo:      ; WARNING implicit "cue mode"
;----------     ; NO VDP CONTROL SET
    clr d0
    move.w (a0)+, d0
    mulu #8, d0
    sub #1, d0
Load_Logo_Loop:
    move.l (a0)+, (VDPD)
    dbra d0, Load_Logo_Loop
    rts
    
;--------
Draw_Text:              ; WARNING IMPLICIT CUE MODE
;-------------
    ;move.l #$40000003, (VDPC)           ; Set up VDP to write to VRAM address 0xC000 (Plane A)
Draw_Text_Loop:    
    clr d1
    move.b (a0)+, d1
    tst d1                              ; if zero terminated string goto exit
    beq Draw_Text_End
    sub.w #31, d1                       ; for matching with ascii table
    or.w #$2000,d1                      ; use palette 1 (tilemap pattern ABBC DEEE EEEE EEEE )
                                        ;                                || | | |    |    |
                                        ;                                || | |  `----`----`- pattern ID
                                        ;                                || | `-------------- vertical flip
                                        ;                                || `---------------- horizontal flip
                                        ;                                |`------------------ Coulour palette (0,1,2,3)
                                        ;                                `------------------- low or high plane ?????
    move.w d1, VDPD                     ; move tilemap to VDP
    jmp Draw_Text_Loop
Draw_Text_End:
    rts
;----
Draw_Tilemap:           ; WARNING IMPLICIT DRAW ON A PLANE
;------------
    ; a0 -> tilemap
    
    move.l #$40000003, (VDPC)           ; Set up VDP to write to VRAM address 0xC000 (Plane A)
    clr d0
    move.w (a0)+, d0
    sub.w #1, d0
Draw_Tilemap_Loop:
    move.w (a0)+, (VDPD)
    dbra d0, Draw_Tilemap_Loop
    rts
;----------
Vsync_Wait:
;----------------
    move.w  VDPC, d0	    ; Move VDP status word to d0
    andi.w  #$8, d0         ; AND with bit 4 (vblank), result in status register
    beq     Vsync_Wait      ; Branch if equal (to zero)
    rts
;----------
Interrupt:
;-------------
    rte
    
    
;-------
; DATAS |
;-------
Palettes:
    include "data\Logo_palette.s"
    
    dc.w    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000  ; font  palette |
    dc.w    $0000, $0000, $0000, $0000, $0EEE, $0000, $0000, $0000  ; font  palette |

    dc.w    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000  ; empty palette |
    dc.w    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000  ; empty palette |

    dc.w    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000  ; empty palette |
    dc.w    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000  ; empty palette |

    
Font_Tiles: 

    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
;!        
    dc.l    $DDD00000
    dc.l    $D0D00000
    dc.l    $D0D00000
    dc.l    $D0D00000
    dc.l    $DDD00000
    dc.l    $D0D00000
    dc.l    $DDD00000
    dc.l    $00000000
;"
    dc.l    $CCCCC000
    dc.l    $C0C0C000
    dc.l    $C0C0C000
    dc.l    $CCCCC000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
;#        
    dc.l    $0CCCCC00
    dc.l    $CC0C0CC0
    dc.l    $C00000C0
    dc.l    $CC0C0CC0
    dc.l    $C00000C0
    dc.l    $CC0C0CC0
    dc.l    $0CCCCC00
    dc.l    $00000000
;$ TODO
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
;% TODO
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
;& TODO
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
;'        
    dc.l    $CCC00000
    dc.l    $C0C00000
    dc.l    $C0C00000
    dc.l    $CCC00000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
;(        
    dc.l    $0CCC0000
    dc.l    $CC0C0000
    dc.l    $C0CC0000
    dc.l    $C0C00000
    dc.l    $C0CC0000
    dc.l    $CC0C0000
    dc.l    $0CCC0000
    dc.l    $00000000
;)        
    dc.l    $CCC00000
    dc.l    $C0CC0000
    dc.l    $CC0C0000
    dc.l    $0C0C0000
    dc.l    $CC0C0000
    dc.l    $C0CC0000
    dc.l    $CCC00000
    dc.l    $00000000
;* TODO
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
;+        
    dc.l    $00CCC000
    dc.l    $00C0C000
    dc.l    $CCC0CCC0
    dc.l    $C00000C0
    dc.l    $CCC0CCC0
    dc.l    $00C0C000
    dc.l    $00CCC000
    dc.l    $00000000
;,        
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $CCC00000
    dc.l    $C0C00000
    dc.l    $C0C00000
    dc.l    $CCC00000
;-        
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $CCCCCCC0
    dc.l    $C00000C0
    dc.l    $CCCCCCC0
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
;.    
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $CC000000
    dc.l    $CC000000
    dc.l    $00000000
;/        
    dc.l    $000CCC00
    dc.l    $00CC0C00
    dc.l    $0CC0CC00
    dc.l    $CC0CC000
    dc.l    $C0CC0000
    dc.l    $CCC00000
    dc.l    $00000000
    dc.l    $00000000
;0        
    dc.l    $0CCCCC00
    dc.l    $CC000CC0
    dc.l    $C0CC00C0
    dc.l    $C0C0C0C0
    dc.l    $C00CC0C0
    dc.l    $CC000CC0
    dc.l    $0CCCCC00
    dc.l    $00000000
;1        
    dc.l    $0CCCC000
    dc.l    $0C00C000
    dc.l    $0CC0C000
    dc.l    $00C0C000
    dc.l    $0CC0CC00
    dc.l    $0C000C00
    dc.l    $0CCCCC00
    dc.l    $00000000
;C       
    dc.l    $CCCCCC00
    dc.l    $C0000CC0
    dc.l    $CCCCC0C0
    dc.l    $CC000CC0
    dc.l    $C0CCCCC0
    dc.l    $C00000C0
    dc.l    $CCCCCCC0
    dc.l    $00000000
;3        
    dc.l    $CCCCCC00
    dc.l    $C0000CC0
    dc.l    $CCCCC0C0
    dc.l    $00C00CC0
    dc.l    $CCCCC0C0
    dc.l    $C0000CC0
    dc.l    $CCCCCC00
    dc.l    $00000000
;4        
    dc.l    $CCC0CCC0
    dc.l    $C0C0C0C0
    dc.l    $C0CCC0C0
    dc.l    $C00000C0
    dc.l    $CCCCC0C0
    dc.l    $0000C0C0
    dc.l    $0000CCC0
    dc.l    $00000000
;5        
    dc.l    $CCCCCCC0
    dc.l    $C00000C0
    dc.l    $C0CCCCC0
    dc.l    $C0000CC0
    dc.l    $CCCCC0C0
    dc.l    $C0000CC0
    dc.l    $CCCCCC00
    dc.l    $00000000
;6        
    dc.l    $0CCCCC00
    dc.l    $CC000C00
    dc.l    $C0CCCC00
    dc.l    $C0000CC0
    dc.l    $C0CCC0C0
    dc.l    $CC000CC0
    dc.l    $0CCCCC00
    dc.l    $00000000
;7        
    dc.l    $CCCCCCC0
    dc.l    $C00000C0
    dc.l    $CCCCC0C0
    dc.l    $00CC0CC0
    dc.l    $0CC0CC00
    dc.l    $0C0CC000
    dc.l    $0CCC0000
    dc.l    $00000000
;8        
    dc.l    $0CCCCC00
    dc.l    $CC000CC0
    dc.l    $C0CCC0C0
    dc.l    $CC000CC0
    dc.l    $C0CCC0C0
    dc.l    $CC000CC0
    dc.l    $0CCCCC00
    dc.l    $00000000
;9        
    dc.l    $0CCCCC00
    dc.l    $CC000CC0
    dc.l    $C0CCC0C0
    dc.l    $CC0000C0
    dc.l    $0CCCC0C0
    dc.l    $0C000CC0
    dc.l    $0CCCCC00
    dc.l    $00000000        
;:                
    dc.l    $00000000
    dc.l    $CCC00000
    dc.l    $C0C00000
    dc.l    $CCC00000
    dc.l    $C0C00000
    dc.l    $CCC00000
    dc.l    $00000000
    dc.l    $00000000
;; TODO
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
;< TODO
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
;= TODO
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
;> TODO
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
;?
    dc.l    $0CCCCC00
    dc.l    $CC000CC0
    dc.l    $C0CCC0C0
    dc.l    $CCC00CC0
    dc.l    $00CCCC00
    dc.l    $00C0C000
    dc.l    $00CCC000
    dc.l    $00000000
;@ TODO
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000
    dc.l    $00000000   
;a    
    dc.l    $0CCCCC00
    dc.l    $CC000CC0
    dc.l    $C0CCC0C0
    dc.l    $C00000C0
    dc.l    $C0CCC0C0
    dc.l    $C0C0C0C0
    dc.l    $CCC0CCC0
    dc.l    $00000000
        
    dc.l    $CCCCCC00
    dc.l    $C0000CC0
    dc.l    $C0CCC0C0
    dc.l    $C0000CC0
    dc.l    $C0CCC0C0
    dc.l    $C0000CC0
    dc.l    $CCCCCC00
    dc.l    $00000000
        
    dc.l    $0CCCCCC0
    dc.l    $CC0000C0
    dc.l    $C0CCCCC0
    dc.l    $C0C00000
    dc.l    $C0CCCCC0
    dc.l    $CC0000C0
    dc.l    $0CCCCCC0
    dc.l    $00000000
        
    dc.l    $CCCCCC00
    dc.l    $C0000CC0
    dc.l    $C0CCC0C0
    dc.l    $C0C0C0C0
    dc.l    $C0CCC0C0
    dc.l    $C0000CC0
    dc.l    $CCCCCC00
    dc.l    $00000000
        
    dc.l    $CCCCCCC0
    dc.l    $C00000C0
    dc.l    $C0CCCCC0
    dc.l    $C000C000
    dc.l    $C0CCCCC0
    dc.l    $C00000C0
    dc.l    $CCCCCCC0
    dc.l    $00000000
        
    dc.l    $CCCCCCC0
    dc.l    $C00000C0
    dc.l    $C0CCCCC0
    dc.l    $C000C000
    dc.l    $C0CCC000
    dc.l    $C0C00000
    dc.l    $CCC00000
    dc.l    $00000000
        
    dc.l    $0CCCCCC0
    dc.l    $CC0000C0
    dc.l    $C0CCCCC0
    dc.l    $C0C000C0
    dc.l    $C0CCC0C0
    dc.l    $CC0000C0
    dc.l    $0CCCCCC0
    dc.l    $00000000
        
    dc.l    $CCC0CCC0
    dc.l    $C0C0C0C0
    dc.l    $C0CCC0C0
    dc.l    $C00000C0
    dc.l    $C0CCC0C0
    dc.l    $C0C0C0C0
    dc.l    $CCC0CCC0
    dc.l    $00000000
        
    dc.l    $CCCCCCC0
    dc.l    $C00000C0
    dc.l    $CCC0CCC0
    dc.l    $00C0C000
    dc.l    $CCC0CCC0
    dc.l    $C00000C0
    dc.l    $CCCCCCC0
    dc.l    $00000000
        
    dc.l    $0000CCC0
    dc.l    $0000C0C0
    dc.l    $0000C0C0
    dc.l    $CCC0C0C0
    dc.l    $C0CCC0C0
    dc.l    $CC000CC0
    dc.l    $0CCCCC00
    dc.l    $00000000
        
    dc.l    $CCC0CCC0
    dc.l    $C0CCC0C0
    dc.l    $C0CC0CC0
    dc.l    $C000CC00
    dc.l    $C0CC0CC0
    dc.l    $C0CCC0C0
    dc.l    $CCC0CCC0
    dc.l    $00000000
    
    dc.l    $CCC00000
    dc.l    $C0C00000
    dc.l    $C0C00000
    dc.l    $C0C00000
    dc.l    $C0CCCCC0
    dc.l    $C00000C0
    dc.l    $CCCCCCC0
    dc.l    $00000000
        
    dc.l    $CCC0CCC0
    dc.l    $C0CCC0C0
    dc.l    $C00C00C0
    dc.l    $C0C0C0C0
    dc.l    $C0CCC0C0
    dc.l    $C0C0C0C0
    dc.l    $CCC0CCC0
    dc.l    $00000000
        
    dc.l    $CCC0CCC0
    dc.l    $C0CCC0C0
    dc.l    $C00CC0C0
    dc.l    $C0C0C0C0
    dc.l    $C0CC00C0
    dc.l    $C0CCC0C0
    dc.l    $CCC0CCC0
    dc.l    $00000000
        
    dc.l    $0CCCCC00
    dc.l    $CC000CC0
    dc.l    $C0CCC0C0
    dc.l    $C0C0C0C0
    dc.l    $C0CCC0C0
    dc.l    $CC000CC0
    dc.l    $0CCCCC00
    dc.l    $00000000
        
    dc.l    $CCCCCC00
    dc.l    $C0000CC0
    dc.l    $C0CCC0C0
    dc.l    $C0000CC0
    dc.l    $C0CCCC00
    dc.l    $C0C00000
    dc.l    $CCC00000
    dc.l    $00000000
        
    dc.l    $0CCCCC00
    dc.l    $CC000CC0
    dc.l    $C0CCC0C0
    dc.l    $C0C0C0C0
    dc.l    $C0CC0CC0
    dc.l    $CC00C0C0
    dc.l    $0CCCCCC0
    dc.l    $00000000
        
    dc.l    $CCCCCC00
    dc.l    $C0000CC0
    dc.l    $C0CCC0C0
    dc.l    $C0000CC0
    dc.l    $C0CC0CC0
    dc.l    $C0CCC0C0
    dc.l    $CCC0CCC0
    dc.l    $00000000
        
    dc.l    $0CCCCCC0
    dc.l    $CC0000C0
    dc.l    $C0CCCCC0
    dc.l    $CC000CC0
    dc.l    $CCCCC0C0
    dc.l    $C0000CC0
    dc.l    $CCCCCC00
    dc.l    $00000000
        
    dc.l    $CCCCCCC0
    dc.l    $C00000C0
    dc.l    $CCC0CCC0
    dc.l    $00C0C000
    dc.l    $00C0C000
    dc.l    $00C0C000
    dc.l    $00CCC000
    dc.l    $00000000
        
    dc.l    $CCC0CCC0
    dc.l    $C0C0C0C0
    dc.l    $C0C0C0C0
    dc.l    $C0C0C0C0
    dc.l    $C0CCC0C0
    dc.l    $CC000CC0
    dc.l    $0CCCCC00
    dc.l    $00000000
        
    dc.l    $CCC0CCC0
    dc.l    $C0C0C0C0
    dc.l    $C0CCC0C0
    dc.l    $CC0C0CC0
    dc.l    $0C0C0C00
    dc.l    $0CC0CC00
    dc.l    $00CCC000
    dc.l    $00000000
        
    dc.l    $CCC0CCC0
    dc.l    $C0C0C0C0
    dc.l    $C0CCC0C0
    dc.l    $C0C0C0C0
    dc.l    $C00C00C0
    dc.l    $C0CCC0C0
    dc.l    $CCC0CCC0
    dc.l    $00000000
        
    dc.l    $CCC0CCC0
    dc.l    $C0CCC0C0
    dc.l    $CC0C0CC0
    dc.l    $0CC0CC00
    dc.l    $CC0C0CC0
    dc.l    $C0CCC0C0
    dc.l    $CCC0CCC0
    dc.l    $00000000
        
    dc.l    $CCC0CCC0
    dc.l    $C0CCC0C0
    dc.l    $CC0C0CC0
    dc.l    $0CC0CC00
    dc.l    $00C0C000
    dc.l    $00C0C000
    dc.l    $00CCC000
    dc.l    $00000000
        
    dc.l    $CCCCCCC0
    dc.l    $C00000C0
    dc.l    $CCCC0CC0
    dc.l    $0CC0CC00
    dc.l    $CC0CCCC0
    dc.l    $C00000C0
    dc.l    $CCCCCCC0
    dc.l    $00000000
 
    include "data\Logo_Tiles.s"
    align 2
    include "data\Logo_tilemap.s"
    align 2
    include "data\set_string.s"
    align 2
End:
