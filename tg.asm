basic_vsync     = 00220H
basic_ret_app1  = 00292H
basic_ret_app2  = 002A4H
basic_if_break  = 00F46H

screen:	        = $2000
PAUSE 	        = $0F35	;inBC=delay
KSCAN	        = $02bb	;outHL=Key, L=ROWbit, H=KEYbit
FINDCHR         = $07bd	;HL=key

SPC_WIDTH       = 4     ; must match first byte of font width file + 1

;-------------------------------------------------------------------------------

        .org    $4009

        .exportmode NO$GMB
        .export

versn	.byte   $00
e_ppc	.word   $0000
d_file	.word   dfile
df_cc	.word   dfile+1 
vars	.word   var 
dest	.word   $0000 
e_line	.word   var+1 
ch_add	.word   last-1 
x_ptr	.word   $0000 
stkbot	.word   last 
stkend	.word   last 
breg	.byte   $00 
mem     .word   membot 
unuseb	.byte   $00 
df_sz	.byte   $02 
s_top	.word   $0000 
last_k	.word   $ffff 
db_st	.byte   $ff
margin	.byte   55 
nxtlin	.word   line10 
oldpc   .word   $0000
flagx   .byte   $00
strlen  .word   $0000 
t_addr  .word   $0c8d; $0c6b
seed    .word   $0000 
frames  .word   $ffff
coords  .byte   $00 
        .byte   $00 
pr_cc   .byte   188 
s_posn  .byte   33 
s_psn1  .byte   24 
cdflag  .byte   64 
PRTBUF  .fill   32,0
prbend  .byte   $76 
membot  .fill   32,0

;-------------------------------------------------------------------------------

line1:  .byte   0,1
        .word   line1end-$-2
        .byte   $ea

;
.module main
;
PS: ; program start

        call    cls
        call    initwad
        ld      ix,wrx

        xor     a
        call    showpic

        ld      a,1
        ld      (chapnum),a

_gochap:
        call    loadchapter

        xor     a
        ld      (pagenum),a
        call    getpage
        ld      (page),hl

_updatepage:
        call    cls
        call    drawpage

_tc:    call    gamestep

        ld      a,(up)
        cp      1
        jr      nz,_td

_tcdi:  ld      a,(pagenum)
        dec     a
        call    trysetpage
        jr      nz,_updatepage

_td:    ld      a,(down)
        cp      1
        jr      nz,_tja

_tddi:  ld      a,(pagenum)
        inc     a
        call    trysetpage
        jr      nz,_updatepage

_tja:   ld      a,(btnA)
        cp      1
        jr      nz,_tjb

        ld      a,(jtab+0)
        bit     7,a
        jr      z,_newchapter

_tjb:   ld      a,(btnB)
        cp      1
        jr      nz,_tjc

        ld      a,(jtab+1)
        bit     7,a
        jr      z,_newchapter

_tjc:   ld      a,(btnC)
        cp      1
        jr      nz,_tc

        ld      a,(jtab+2)
        bit     7,a
        jr      nz,_tc

_newchapter:
        ld      (chapnum),a
        jp      _gochap



trysetpage:
        ld      (_tempage),a
        cp      $ff             ; page of -1 no allowed
        ret     z

        call    getpage
        ld      a,$ff           ; end of chapter marked with ffff
        cp      h
        ret     z

_tempage=$+1
        ld      a,0
        ld      (pagenum),a
        ld      (page),hl
        or      $ff             ; clear z flag to indicate success
        ret


chapnum:
        .byte   0
chapter:
        .word   0

pagenum:
        .byte   0
page:
        .word   0

jtab:
        .byte   0,0,0

;-------------------------------------------------------------------------------
;
.module ci
;
loadchapter:
        ld      a,(chapnum)             ; index into the chapter pointer table
        add     a,a
        ld      l,a
        ld      h,chapterptrs / 256
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a                     ; hl points to start of chapter info block
 
        ld      a,(hl)                  ; snaffle out the bmp index, if there is one
        cp      -1
        jr      z,_nopic

        push    hl
        call    showpic
        pop     hl

_nopic:
        inc     hl
        ld      (chapter),hl

        ld      a,(chapnum)
        call    wadLoad
        ret


showpic:
        add     a,$16
        call    wadLoad

        ld      hl,$8032
        ld      de,screen
        ld      bc,32*192
        ldir

_wait4key:
        call   gamestep
        ld      a,(select)
        cp      1
        jr      nz,_wait4key
        ret



getpage:
        ; a <- page number
        ; hl -> offset into page data

        ld      hl,(chapter)

        ld      d,0                     ; each page info is 5 bytes
        ld      e,a
        add     hl,de
        sla     e
        sla     e
        add     hl,de
        push    hl
        inc     hl
        inc     hl
        ld      de,jtab
        ldi
        ldi
        ldi
        pop     hl
        ld      a,(hl)                  ; get offset into page text
        inc     hl
        ld      h,(hl)
        ld      l,a
        ret

;-------------------------------------------------------------------------------
;
.module dp
;
drawpage:
        ld      hl,(page)
        ld      de,$8000
        add     hl,de
        ld      (wordp),hl

        ; we have a pointer to the page text within the chapter

_loop:
        ld      hl,(wordp)
        ld      a,(hl)
        and     a                       ; a = 0 when no more words left
        ret     z

        call    getword                 ; get the next word into the word buffer

        ld      (wordp),hl

        ld      a,(wordbuf)
        cp      10
        jr      z,_donewline

        call    getwordlen              ; return with word length in BC

        ld      a,(x)                   ; will x + word len fit?
        add     a,c

        ld      hl,wordbuf              ; get a word pointer ready in case it needs updating

        call    c,_newlineorbust

        call    textout                 ; render the word
        jr      _loop

_donewline:
        call    newline
        jr      nz,_loop
        ret


_newlineorbust:
        call    newline                 ; no space left, so advance a line
        jr      nz,_remspc              ; continue if there are lines left

        pop     hl                      ; don't return to drawing, but to caller
        ret

_remspc:
        ld      a,(hl)                  ; remove whitespace from front of word if necessary
        cp      32
        ret     nz

        inc     hl
        ret


newline:
        xor     a                       ; newline
        ld      (x),a
        ld      a,(y)
        inc     a
        ld      (y),a
        cp      17
        ret


wordp:
        .word   0


;-------------------------------------------------------------------------------
;
.module words
;
getword:
        call    _gwi
        ex      de,hl
        ld      (hl),0
        ex      de,hl
        ret

_gwi:
        ld      de,wordbuf
        ld      a,(hl)

_scrape:
        ldi
        cp      10
        ret     z
        ld      a,(hl)
        cp      32
        ret     z
        cp      15
        jr      nc,_scrape
        ret

wordbuf:
        .fill   32


getwordlen:
        ld      de,wordbuf
        ld      h,widths / 256
        ld      bc,0
        jr      _advance

_accum:
        ld      l,a
        ld      a,(hl)
        add     a,c
        ld      c,a
        inc     c
        inc     de

_advance:
        ld      a,(de)
        and     a
        jr      nz,_accum

        dec     c
        ret

;-------------------------------------------------------------------------------
;
.module wad
;
initwad:
        ld      de,wadfile      ; send filename
        call    $1ffa

        ld      bc,$8007        ; open read
        ld      a,$00
        out     (c),a
        jp      $1ff6           ; wait/get response


wadLoad:
        ld      h,0
        ld      l,a
        add     hl,hl
        ld      de,wadptrs
        add     hl,de
        xor     a
        ld      (PRTBUF),a
        ld      (PRTBUF+3),a
        ld      de,PRTBUF+1
        ldi
        ldi

        ld      de,PRTBUF
        ld      l,4             ; transfer seek position dword
        ld      a,l
        call    $1ffc

        ld      bc,$8007        ; dword seek
        ld      a,$d0
        out     (c),a
        call    $1ff6           ; wait/get response

        ld      de,$8000        ; read 8k to $8000, nasty but oh well
-:      push    de

        ld      bc,$A007        ; file read, 256 bytes
        xor     a
        out     (c),a
        call    $1ff6           ; wait/get response

        pop     de              ; xfer
        push    de
        xor     a
        ld      l,a
        call    $1ffc

        pop     de
        inc     d
        ld      a,$a0
        cp      d
        jr      nz,{-}

        ret

;-------------------------------------------------------------------------------
;
.module co
;
-:      inc     hl

        cp      $20
        jr      nz,{+}

        ld      a,(x)
        add     a,SPC_WIDTH
        ld      (x),a
        jr      textout

+:      call    charout

textout:
        ld      a,(hl)
        and     a
        jr      nz,{-}
        ret



; x = 5 w = 3
; byte mode
; x % 8 + w < 8
;
; x = 8 w = 4
; copy mode
; x % 8 = 0
;
; x = 12 w = 6
; word mode

x:      .byte   0
y:      .byte   0
w:      .byte   0

charout:
        push    hl
 
        ; get character width into c
        ;
        ld      l,a
        ld      h,widths / 256
        ld      c,(hl)
        ld      hl,w
        ld      (hl),c          ; stash for later

        ; calculate glyph data address
        ;
        ld      h,0             ; hl = a * 12 + font base
        ld      l,a
        add     hl,hl
        add     hl,hl
        ld      d,h
        ld      e,l
        add     hl,hl
        add     hl,de
        ld      de,font
        add     hl,de

        ; calculate screen line offset
        ;
        push    hl
        ld      a,(y)
        add     a,a
        add     a,linestarts & 255
        ld      l,a
        ld      h,linestarts / 256
        ld      a,(hl)
        inc     hl
        ld      d,(hl)
        ld      e,a
        pop     hl

        ; calculate glyph pixel offset
        ;
        ld      a,(x)
        and     7
        ld      b,a             ; b <- screen pixel offset

        ; calculate screen byte offset
        ;
        ld      a,(x)
        and     $f8
        rrca
        rrca
        rrca
        add     a,e
        ld      e,a
        jr      nc,{+}
        inc     d
+:
        ; determine which glyph renderer to use

        ; if pixel offset is 0 then it's super easy
        ;
        ld      a,b
        and     a
        jr      z,bytealigned

        ; if pixel offset + char width < 8 then rotated bits will fit in a byte
        ;
        add     a,c             ; c = char width
        ld      c,b             ; c <- pixel offset / aka shift count
        cp      8
        jr      c,byteshift        

        ; otherwise we need a word to get lost in

;-------------------------------------------------------------------------------
;
.module ws
;
wordshift:
        ld      b,11
        jr      _stw

_advance:
        inc     hl
        ld      a,e
        add     a,31
        ld      e,a
        jr      nc,_stw

        inc     d

_stw:   push    hl
        push    bc
        ld      a,(hl)
        ld      b,c
        ld      l,0

_shift: srl     a
        rr      l
        djnz    _shift

        ld      b,a
        ld      a,(de)
        or      b
        ld      (de),a
        inc     de
        ld      a,(de)
        or      l
        ld      (de),a

        pop     bc
        pop     hl
        djnz    _advance

        jr      updatex

;-------------------------------------------------------------------------------
;
.module bs
;
byteshift:
        ld      b,11
        jr      _stb

_advance:
        inc     hl
        ld      a,e
        add     a,32
        ld      e,a
        jr      nc,_stb

        inc     d

_stb:   push    bc
        ld      a,(hl)
        ld      b,c

_shift: rrca
        djnz    _shift

        ld      b,a
        ld      a,(de)
        or      b
        ld      (de),a

        pop     bc
        djnz    _advance

        jr      updatex

;-------------------------------------------------------------------------------
;
.module ba
;
bytealigned:
        ld      bc,$0bff        ; set c to be high number so we can use LDI
        jr      _stb

_advance:
        ld      a,e
        add     a,31            ; ldi already added 1
        ld      e,a
        jr      nc,_stb

        inc     d

_stb:   ldi
        djnz    _advance

updatex:
        ld      a,(x)           ; update cursor x
        ld      c,a
        ld      a,(w)
        add     a,c
        inc     a
        ld      (x),a

        pop     hl
        ret

;-------------------------------------------------------------------------------
;
.module misc
;
cls:
        ld	hl,screen
	ld      de,screen+1
	ld      bc,6144-1
        xor     a
	ld      (hl),a
	ldir
        ld      (x),a
        ld      (y),a
        ret

 gamestep:
        ld      hl,gameframe
        ld      a,(hl)
-:      cp      (hl)
        jr      z,{-}

        jp      readinput

;-------------------------------------------------------------------------------

PE: ; program end

;-------------------------------------------------------------------------------
;
.module hrg
;
wrx:
        ; timing, do a waste, then prepare for display

        ld      b,7             ; 7
        djnz    $               ; 7 * 13 + 8 = 99
        ld      a,0             ; 7
        ld      a,0             ; 7
        ld      hl,screen       ; 10

        ld      b,192           ; 7    192 rows
        ld      de,32           ; 10   row stride

        ; from start to here = 140T
_loop:
        ld      a,h
        ld      i,a
        ld      a,l
        call    hrg_dummy+8000H
        add     hl,de
        dec     b
        jp      nz,_loop

        ; prepare for bottom margin and VSYNC

        ld      hl,gameframe
        inc     (hl)

VCentreBot = $+1
	ld	a,55 ;BOTTOM_MARGIN 	; 7
	neg				; 8
	inc	a			; 4
	ex	af,af'			; 4
	ld	ix,GENERATE_VSYNC	; 14

        ; NMI on

	out	($fe),a 		; 11

        ; Do the things you need to do

        ; CALL VSYNCTASK

        ; return to application

	pop	hl			; 10
	pop	de			; 10
	pop	bc			; 10
	pop	af			; 10
	ret				; 10


GENERATE_VSYNC:
; VSync start
	in	a,($fe) 		; 11

        ld      de,INPUT._kbin          ; 10
        ld      bc,$fefe                ; 10
        ; = 20
        .repeat 8
                in      a,(c)           ; 12
                rlc     b               ; 8
                ld      (de),a          ; 7
                inc     de              ; 6  = 33
        .loop
        ; = 8 * 33 = 264

	;waste time
	ld		b,40		; 7
	djnz	$			; 13/8
	; = (40*13)+8+7 = 535

	; for timing only
	ld	a,0		        ; 7

; total T = 535 + 264 + 20  + 7 = 826

; prepare for top margin
VCentreTop = $+1
	ld	a,(margin)              ; 7
	neg				; 8
	inc	a			; 4
	ex	af,af'			; 4
	ld	ix,wrx		        ; 14

	pop	hl			; 10
	pop	de			; 10
	pop	bc			; 10
	pop	af			; 10

        ; NMI on, VSync stop
	out	($fe),a 		; 11

        ; return to application
	ret

hrg_dummy:
        ld      r,a
        .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        ret     nc

;-------------------------------------------------------------------------------

font:
        .incbin textgamefont.bin

        .align 256
widths:
        .incbin textgamefont-widths.bin

        bytesperline = 32 * 11

        ; needs to be here for alignment purposes
linestarts:
        .word   screen+ 0*bytesperline, screen+ 1*bytesperline, screen+ 2*bytesperline, screen+ 3*bytesperline
        .word   screen+ 4*bytesperline, screen+ 5*bytesperline, screen+ 6*bytesperline, screen+ 7*bytesperline
        .word   screen+ 8*bytesperline, screen+ 9*bytesperline, screen+10*bytesperline, screen+11*bytesperline
        .word   screen+12*bytesperline, screen+13*bytesperline, screen+14*bytesperline, screen+15*bytesperline
        .word   screen+16*bytesperline, screen+17*bytesperline

;-------------------------------------------------------------------------------

gameframe
	.byte	0

;-------------------------------------------------------------------------------

cp0 = 0
cp1 = 1
cp2 = 2
cp3 = 3
cp4 = 4
cp5 = 5
cp6 = 6
cp7 = 7
cp8 = 8
cp9 = 9
cpA = 10
cpB = 11
cpC = 12
cpD = 13
cpE = 14
cpF = 15
cpG = 16
cpH = 17
cpI = 18
cpJ = 19
cpK = 20
cpL = 21
        .define PG .word
        .define JP .byte
        .define BM .byte

        .align 256

chapterptrs:
	.word	chp_0,  chp_1,  chp_2,  chp_3,  chp_4,  chp_5
	.word	chp_6,  chp_7,  chp_8,  chp_9,  chp_10, chp_11
	.word	chp_12, chp_13, chp_14, chp_15, chp_16, chp_17
	.word	chp_18, chp_19, chp_20, chp_21

        .include "codegen/chapterdat.asm"

        .align 256
wadptrs:
        .include "codegen/wad.asm"

wadfile:
        .byte   $39,$2c,$1b,$3c,$26,$29+$80     ; TG.WAD

;-------------------------------------------------------------------------------

        .include "input.asm"

;-------------------------------------------------------------------------------

scrbase
        .word   screen
        .byte   076H                    ; N/L
line1end:

;-------------------------------------------------------------------------------

line10:
        .byte   0,10
        .word   line10end-$-2
        .byte   $F9,$D4,$C5,$0B         ; RAND USR VAL "
        .byte   $1D,$22,$21,$1D,$20	; 16514 
        .byte   $0B                     ; "
        .byte   076H                    ; N/L
line10end:

;-------------------------------------------------------------------------------

dfile:
        .byte   076H
        .byte   076H,076H,076H,076H,076H,076H,076H,076H
        .byte   076H,076H,076H,076H,076H,076H,076H,076H
        .byte   076H,076H,076H,076H,076H,076H,076H,076H

;-------------------------------------------------------------------------------

var:    .byte   080H
last:

        .end