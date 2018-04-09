basic_vsync     = 00220H
basic_ret_app1  = 00292H
basic_ret_app2  = 002A4H
basic_if_break  = 00F46H

screen:	        = $2000
PAUSE 	        = $0F35	;inBC=delay
KSCAN	        = $02bb	;outHL=Key, L=ROWbit, H=KEYbit
FINDCHR         = $07bd	;HL=key

        .include codegen/global.inc

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

        .include lowdata.bin.inc

;-------------------------------------------------------------------------------

line1:  .byte   0,1
        .word   line1end-$-2
        .byte   $ea

;
.module A_MAIN
;
AA_PS: ; program start

        ld      bc,$e007                ; go low
        ld      a,$b2
        out     (c),a

        xor     a
        ld      (soundEn),a

        call    cls
        ld	ix,GENERATE_VSYNC

        call    initwad

        ld      a,$22                   ; lowdat
        call    wadload
        ld      hl,$8000
        ld      de,LOWDATSTART
        ld      bc,$4000-LOWDATSTART
        ldir

        ld      hl,berlin
        call    INIT_STC

        ld      b,100
-:      call    WAIT_SCREEN             ; allow time for TV to sync so first part of music is not cut off
        djnz    {-}

        call    cls

_begin:
        ld      a,$ff                   ; music on, show title picture
        ld      (soundEn),a

        ld      a,22                    ; prepare for first chapter
        ld      (chapnum),a

_gochap:
        call    loadchapter
        call    clearosr

        call    scrollup

        xor     a                       ; disable jumps until the last line is on screen
        ld      (jmpA),a
        ld      (jmpB),a
        ld      (jmpC),a

        ld      b,SCREENLINES           ; render up to this many lines
        ld      hl,$8000                ; begin the beguine

_nextline:
        push    bc
        push    hl
        call    renderline 
        pop     hl
        inc     hl
        inc     hl
        inc     hl
        pop     bc
        djnz    _nextline

        ld      a,0
        ld      (startlinenum),a

        ;

_mainloop:
        call    gamestep

        call    flashindicator

        ld      a,(sound)
        cp      1
        jr      nz,_tu

        ld      a,(soundEn)
        xor     $ff
        ld      (soundEn),a
        call    z,mute_stc

_tu:    ld      a,(lineup)
        cp      1
        jr      z,{+}
        cp      $ff
+:      call    z,_linereverse

_td:    ld      a,(linedown)
        cp      1
        jr      z,{+}
        cp      $ff
+:      call    z,_lineforward

_tpd:   ld      a,(pagedown)
        cp      1
        jr      z,{+}
        ld      a,(select)
        cp      1
        jr      nz,_tpu

+:      ld      b,SCREENLINES
-:      push    bc
        call    _lineforward
        pop     bc
        djnz    {-}
        call    toplineisblank
        call    z,_lineforward

_tpu:   ld      a,(pageup)
        cp      1
        jr      nz,_tja

_nxpage:
        ld      b,SCREENLINES
-:      push    bc
        call    _linereverse
        pop     bc
        djnz    {-}
        call    toplineisblank
        call    z,_linereverse

_tja:   call    lastlinetest
        jr      nz,_mainloop

        ;

        ld      a,(btnA)
        cp      1
        jr      nz,_tjb

        ld      a,(jtab+0)
        cp      $ff
        jr      nz,_newchapter

_tjb:   ld      a,(btnB)
        cp      1
        jr      nz,_tjc

        ld      a,(jtab+1)
        cp      $ff
        jr      nz,_newchapter

_tjc:   ld      a,(btnC)
        cp      1
        jp      nz,_mainloop

        ld      a,(jtab+2)
        cp      $ff
        jp      z,_mainloop

_newchapter:
        ld      (chapnum),a
        call    clearindicator
        jp      _gochap


; z set if first line at top of screen
firstlinetest:
        ld      a,(startlinenum)
        or      a
        ret


; z set if last line is at bottom of screen
lastlinetest:
        ld      a,(startlinenum)
        add     a,SCREENLINES
        ld      l,a             ; hl => line data
        ld      h,0
        ld      d,$80
        ld      e,l
        add     hl,hl
        add     hl,de
        ld      a,(hl)          ; OR together the char count and line pointers
        inc     hl
        or      (hl)
        inc     hl
        or      (hl)
        ret


_lineforward:
        ld      a,(startlinenum)
        inc     a
        ld      b,15
        call    tryshowline
        ret     z
        jp      scrollup

_linereverse:
        ld      a,(startlinenum)
        dec     a
        ld      b,0
        call    tryshowline
        ret     z
        jp      scrolldown


; z set if line blank
toplineisblank:
        ld      a,(startlinenum)
        ld      l,a             ; hl => line data
        ld      h,0
        ld      d,$80
        ld      e,l
        add     hl,hl
        add     hl,de
        ld      a,(hl)          ; OR together the char count and line pointers
        or      a
        ret


tryshowline:
        cp      $ff             ; page of -1 no allowed
        ret     z

        ld      (_templn),a  ; self modify
        add     a,b             ; offset
        ld      l,a             ; hl => line data
        ld      h,0
        ld      d,$80
        ld      e,l
        add     hl,hl
        add     hl,de

        push    hl
        ld      a,(hl)          ; OR together the char count and line pointers
        inc     hl
        or      (hl)
        inc     hl
        or      (hl)
        pop     hl
        ret     z               ; result is 0 if the target line is past the end of text.

_templn=$+1
        ld      a,-1            ; self modified
        ld      (startlinenum),a

        call    clearindicator

        call    renderline2     ; hl is data ptr

        or      $ff             ; return with z clear to indicate success
        ret




renderline:
        ld      b,(hl)                  ; line character count

        inc     hl                      ; line ptr
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a

        call    clearosr

        or      h                       ; line ptr is 0? if so we're done
        jp      z,scrollup

        xor     a                       ; char count 0 = newline
        cp      b
        jr      z,_emptyline

        ld      (x),a
        set     7,h                     ; pointer to text data

_line:
        push    bc
        ld      a,(hl)
        call    extcharout 
        pop     bc
        inc     hl
        djnz    _line

_emptyline:
        ld      a,(y)
        inc     a
        ld      (y),a

        jp      scrollup


renderline2:
        ld      b,(hl)                  ; line character count

        inc     hl                      ; line ptr
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a

        call    clearosr

        xor     a                       ; char count 0 = newline
        cp      b
        ret     z

        ld      (x),a
        set     7,h                     ; pointer to text data

_line2:
        push    bc
        ld      a,(hl)
        call    extcharout 
        pop     bc
        inc     hl
        djnz    _line2

        ret



chapnum:
        .byte   0
chappic:
        .byte   $ff

linenum:
        .byte   0

startlinenum:
        .byte   0

jtab = $
jmpA = $+3
jmpB = $+4
jmpC = $+5
        .byte   0,0,0
        .byte   0,0,0

;-------------------------------------------------------------------------------
;
.module ci
;
loadchapter:
        ld      a,(chappic)
        cp      $ff
        jr      z,{+}

        call    showpic

+:      ld      hl,chapterptrs
        ld      a,(chapnum)             ; index into the chapter pointer table
        add     a,a
        add     a,l
        ld      l,a
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a                     ; hl points to start of chapter info block
 
        ld      a,(hl)                  ; snaffle out the bmp index, if there is one
        ld      (chappic),a

        inc     hl                      ; copy out jump indicies
        ld      de,jtab
        ldi
        ldi
        ldi

        ld      a,(chapnum)
        jp      wadLoad


;-------------------------------------------------------------------------------


showpic:
        add     a,$17                   ; start of images in wad
        call    wadLoad

        ld      hl,$8032                ; image data pointer
        ld      b,192/4

-:      push    bc                      ; save loop count

        call    WAIT_SCREEN

        ld      de,(RASTER_STACK_OSL)   ; copy a line of image into first off-screen scanline
        ld      bc,32*4
        ldir

        call    scrollup4

        pop     bc                      ; loop counter
        djnz    {-}

        jp      waitkey


;-------------------------------------------------------------------------------
;
.module cu
;
flashindicator:
        push    af
        push    hl
        push    de
        call    firstlinetest
        ld      hl,(RASTER_STACK)
        call    nz,_indic
        call    lastlinetest
        ld      hl,(RASTER_STACK_OSL-2)
        call    nz,_indic
        pop     de
        pop     hl
        pop     af
        ret

clearindicator:
        push    af
        push    hl
        push    de
        xor     a
        ld      hl,(RASTER_STACK)
        call    {+}
        ld      hl,(RASTER_STACK_OSL-2)
        call    {+}
        pop     de
        pop     hl
        pop     af
        ret

_indic: xor     a
        ld      a,(frameCounter)
        and     32
        jr      z,{+}
        ld      a,$2a
+:      ld      de,31
        add     hl,de
        ld      (hl),a
        ret

;-------------------------------------------------------------------------------
;
.module co
;
extcharout:
        cp      $20
        jr      nz,_notspc

        ld      a,(x)
        add     a,SPC_WIDTH
        ld      (x),a
        ret

_notspc:
        cp      $09
        jr      nz,_nottab

        ld      a,(x)
        add     a,TAB_WIDTH
        ld      (x),a
        ret

_nottab:
        cp      $1a
        jr      nz,_notjmpa

        ld      (jmpA),a

_notjmpa:
        cp      $1c
        jr      nz,_notjmpb

        ld      (jmpB),a

_notjmpb:
        cp      $1e
        jr      nz,_notjmpc

        ld      (jmpC),a

_notjmpc:
        ; falls into charout

; character rendering is a little bit optimised
;
; a different rendering method is used depending on whether the character:
;  * is aligned on a byte boundary
;  * will fit entirely within a byte after shifting
;  * requires a 16 bit window for shifting
;
; byte shift mode
; x % 8 + w <= 8
; ex: x = 5 w = 2
;
; copy mode
; x % 8 = 0
; ex: x = 8 w = 4
;
; word shift mode
; x % 8 + w > 8
; ex: x = 7 w = 6

charout:
        push    hl
 
        ; get character width into c
        ;
        ld      l,a
        ld      h,widths / 256
        ld      c,(hl)

        ld      hl,w
        ld      (hl),c          ; stash width for later
        cp      128             ; if this is an italic character, employ some shonky kerning
        jr      c,{+}

        dec     c               ; kern
        dec     c
        ld      (hl),c
        inc     c
        inc     c

        ; calculate glyph data address
        ;
+:      cp      128
        jr      c,{+}
        sub     15
+:      sub     15
        ld      h,0             ; hl = a * 10 + font base
        ld      l,a
        ld      d,h
        ld      e,l
        add     hl,hl
        add     hl,hl
        add     hl,de
        add     hl,hl
        ld      de,font
        add     hl,de

        ; calculate screen line offset
        ;
        ld      de,(RASTER_STACK_OSL)

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
        ld      b,10
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
        ld      b,10
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
        ld      b,10
        jr      _stb

_advance:
        ld      a,e
        add     a,32
        ld      e,a
        jr      nc,_stb

        inc     d

_stb:   ld      c,(hl)
        ld      a,(de)
        or      c
        ld      (de),a
        inc     hl

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


x:      .byte   0
y:      .byte   0
w:      .byte   0


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
        ld      h,0             ; a * 3 bytes / entry
        ld      l,a
        ld      d,h
        ld      e,l
        add     hl,hl
        add     hl,de
        ld      de,wadptrs
        add     hl,de
        xor     a
        ld      (PRTBUF),a
        ld      (PRTBUF+3),a
        ld      de,PRTBUF+1
        ldi
        ldi
        ld      a,(hl)          ; length in 256 byte blocks
        or      $80             ; high byte of last address
        ld      (w),a

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
        ld      a,(w)           ; loaded enough?
        cp      d
        jr      nz,{-}

        ret

;-------------------------------------------------------------------------------
;
.module misc
;
scrollup4:
        push    hl
        push    de
        push    bc

        ld      hl,RASTER_STACK         ; cache the first on-screen scanline pointer
        ld      de,RASTER_STACK_BUFFER
        ld      bc,4*2
        ldir

        ld      hl,RASTER_STACK+(4*2)  ; move the stack, post and buffer up
        ld      de,RASTER_STACK
        ld      bc,(192+LINEHEIGHTPIX+4)*2
        ldir

        pop     bc
        pop     de
        pop     hl
        ret


scrollup:
        call    WAIT_SCREEN             ; scroll the stack up one scanline

scrollup12:
        push    hl
        push    de
        push    bc

        ld      hl,RASTER_STACK         ; cache the first on-screen scanline pointer
        ld      de,RASTER_STACK_BUFFER
        ld      bc,LINEHEIGHTPIX*2
        ldir

        ld      hl,RASTER_STACK+(LINEHEIGHTPIX*2)  ; move the stack, post and buffer up
        ld      de,RASTER_STACK
        ld      bc,(192+LINEHEIGHTPIX+LINEHEIGHTPIX)*2
        ldir

        pop     bc
        pop     de
        pop     hl
        ret


scrolldown:
        call    WAIT_SCREEN             ; scroll the stack up one scanline

        push    hl
        push    de
        push    bc

        ld      hl,RASTER_STACK_OSL     ; cache the first on-screen scanline pointer
        ld      de,RASTER_STACK_BUFFER
        ld      bc,LINEHEIGHTPIX*2
        ldir

        ld      hl,RASTER_STACK_OSL-1   ; move the stack down
        ld      de,RASTER_STACK_OSL+(LINEHEIGHTPIX*2)-1
        ld      bc,(192+LINEHEIGHTPIX)*2
        lddr

        ld      hl,RASTER_STACK_BUFFER
        ld      de,RASTER_STACK
        ld      bc,LINEHEIGHTPIX*2
        ldir

        pop     bc
        pop     de
        pop     hl
        ret


; RASTER_STACK                     RASTER_STACK_OSL   RASTER_STACK_BUFFER
; 192*2                            LINEHEIGHTPIX*2    LINEHEIGHTPIX*2
; 000 001 .. 012 013 ... 190 191   [192 193 .. 203]   [204 ... 215]
;                                  [000        011]   [000 ... 011]
; de         hl

clearosr:
        push    af
        push    hl
        push    de
        push    bc
        ld      de,(RASTER_STACK_OSL)
        ld      h,d
        ld      l,e
        ld      (hl),0
        inc     de
        ld      bc,32*LINEHEIGHTPIX-1
        ldir
        pop     bc
        pop     de
        pop     hl
        pop     af
        ret


cls:
        push    af
        xor     a
        ld      (x),a
        ld      (y),a
        ld	hl,screen
	ld      de,screen+1
	ld      bc,32*(192+LINEHEIGHTPIX)
	ld      (hl),a
	ldir
        pop     af
        ret


gamestep:
        call    WAIT_SCREEN
        jp      readinput


waitkey:
        call    gamestep
        ld      a,(select)
        cp      1
        ret     z
        ld      a,(pagedown)
        cp      1
        jr      nz,waitkey
        ret


waitkeytimeout:
        xor     a
        jr      {+}

-:      call    gamestep
        ld      a,(select)
        cp      1
        ret     z                       ; zero set, carry clear
        ld      a,(pagedown)
        cp      1
        ret     z                       ; zero set, carry clear
        ld      a,(_timeout)
+:      inc     a
        ld      (_timeout),a
        jr      nz,{-}
        ret                             ; ret with carry set

_timeout:
        .byte   0

;-------------------------------------------------------------------------------

font:
        .incbin textgamefont.bin
        .incbin textgamefont-i.bin

wadfile:
        .byte   $2e,$33,$37,$1b,$3c,$26,$29+$80     ; INR.WAD

wadptrs:
        .include "codegen/wad.asm"

;-------------------------------------------------------------------------------

        .include "input.asm"

;-------------------------------------------------------------------------------

        .include "stcplay.asm"

berlin:
        .incbin "stc/berlin.stc"

soundEn:
        .byte   $ff

;-------------------------------------------------------------------------------

AA_PE: ; program end

        .include        StackWRX.asm

;-------------------------------------------------------------------------------

scrbase:
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