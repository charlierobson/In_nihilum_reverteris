    .module wrx

;--------------------------------
RASTER_DATA             =   $2000
SCREEN_WIDTH_PIXELS		=	256
SCREEN_HEIGHT_RASTERS	=	192
SCREEN_WIDTH_BYTES		=	SCREEN_WIDTH_PIXELS / 8
TV_STD_50HZ				=	312
TV_STD_60HZ				=	262
TV_STD					=	TV_STD_50HZ
VSYNC_RASTERS			=	4
WASTED_RASTERS			=	3
TOTAL_BLANK_RASTERS		=	TV_STD - WASTED_RASTERS - SCREEN_HEIGHT_RASTERS - VSYNC_RASTERS
TOP_BLANK_RASTERS		=	TOTAL_BLANK_RASTERS / 2
BOTTOM_BLANK_RASTERS	=	TOTAL_BLANK_RASTERS - TOP_BLANK_RASTERS

;--------------------------------
FrameCounter:
	.byte	0
StackSave:
	.word	0

;--------------------------------
    .align	32
CREATE_RASTER:
;load hfile address lsb
	ld	    r,a
;NOP-magic to draw pixels :D
	.repeat SCREEN_WIDTH_BYTES
		nop
	.loop
;return to main graphics routine
	jp	    HIRES_RET

;--------------------------------
RASTER_STACK_PRE:
	.repeat SCREEN_HEIGHT_RASTERS
		.word	BLANK_LINE
	.loop
RASTER_STACK:
	ADDR = RASTER_DATA
	.repeat SCREEN_HEIGHT_RASTERS
		.word	ADDR
		ADDR = ADDR + SCREEN_WIDTH_BYTES
	.loop
RASTER_STACK_POST:
	.repeat SCREEN_HEIGHT_RASTERS
		.word	BLANK_LINE
	.loop

	.align	32
BLANK_LINE:
    .fill   32,0

;--------------------------------
;sync to screen update
WAIT_SCREEN:
	ld	    hl,FrameCounter
	ld	    a,(hl)
_waitforit:
	cp	    (hl)
	jr	    z,_waitforit
	ret


;--------------------------------
GENERATE_VSYNC:
;VSync on
	in	    a,($fe)
;Do something useful during VSync:

	ld      de,INPUT._kbin          ; 10
	ld      bc,$fefe                ; 10

	.repeat 8
	in      a,(c)                   ; 12
	rlc     b                       ; 8
	ld      (de),a                  ; 7
	inc     de                      ; 6
	.loop
	; = 264 == 8 * 33

	; waste time

	ld		b,34		        	; 7
	djnz	$						; (40 * 13) + 8
	; = 457 == (34*13)+8+7

	ld	    a,0		        			; 7

;VSync off
	out	    ($fe),a
;Prepare top border:
	ld	    a,256 - TOP_BLANK_RASTERS
	ex	    af,af'
	ld	    ix,GENERATE_HIRES
;Restore registers
	pop	    hl
	pop	    de
	pop	    bc
	pop	    af
;return to do some useful work, and generate top blank rasters
	ret

RSP:    .word RASTER_STACK

;--------------------------------
GENERATE_HIRES:
;delay to synchronize picture-start
	ld	    b,5
	djnz	$       ; 6 * 13 + 8
    ld      a,0
    ld      a,0
;init registers for graphics generation
	ld	    b,SCREEN_HEIGHT_RASTERS
	ld	    (StackSave),sp
	ld	    sp,(RSP)
HIRES_RASTERS:
;get raster address from raster stack
    pop	    hl
;prepare registers for WRX
    ld	    a,h
    ld	    i,a
    ld	    a,l
;start generating the hires screen
	jp	    CREATE_RASTER+$8000
HIRES_RET:
;waste time
    ld	    a,r
;count rasters
    dec	    b
	jp	    nz,HIRES_RASTERS
;restore stack
	ld	    sp,(StackSave)
;Prepare bottom border:
	ld	    ix,GENERATE_VSYNC
	ld	    a,256 - BOTTOM_BLANK_RASTERS
	ex	    af,af'
;increment FrameCounter
	ld	    hl,FrameCounter
	inc	    (hl)
;NMI-generator on
	out	    ($fe),a

;Do vsync-ey type tasks e.g. music
	ld      a,(soundEn)
	and     $ff
	call    nz,play_stc

;Restore registers
	pop	    hl
	pop	    de
	pop	    bc
	pop	    af
;return to do some useful work, and generate bottom blank rasters
	ret
