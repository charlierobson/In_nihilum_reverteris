;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
;
    .module INPUT
;


; -----  4  3  2  1  0
;
; $FE -  V, C, X, Z, SH   0
; $FD -  G, F, D, S, A    1
; $FB -  T, R, E, W, Q    2
; $F7 -  5, 4, 3, 2, 1    3
; $EF -  6, 7, 8, 9, 0    4
; $DF -  Y, U, I, O, P    5
; $BF -  H, J, K, L, NL   6
; $7F -  B, N, M, ., SP   7
;

; input state data:
;
; joystick bit, or $ff/%11111111 for no joy
; key row offset 0-7,
; key mask, or $ff/%11111111 for no key
; trigger impulse



inputstates:
    .byte	%10000000,4,%00001000,0        ; up      (7)
    .byte	%01000000,4,%00010000,0        ; down    (6)
    .byte	%00100000,7,%00001000,0        ; left    (N)
    .byte	%00010000,7,%00000100,0        ; right   (M)
    .byte	%00001000,6,%00000001,0        ; select  (NL) / fire
    .byte	%11111111,1,%00000001,0        ; A
    .byte	%11111111,7,%00010000,0        ; B
    .byte	%11111111,0,%00001000,0        ; C


; calculate actual input impulse addresses
up      = inputstates + 3
down    = inputstates + 7
left    = inputstates + 11
right   = inputstates + 15
select  = inputstates + 19
btnA    = inputstates + 23
btnB    = inputstates + 27
btnC    = inputstates + 31

; kbin is filled by the display interrupt

    .align  8
_kbin:
    .fill   8

_lastJ:
    .byte   $ff


readinput:
    ; _kbin is filled during display generation wasted time

    ld      bc,$e007        ; initiate a zxpand joystick read
    ld      a,$a0
    out     (c),a
    ex      (sp),hl
    ex      (sp),hl
    in      a,(c)           ; retrieve joystick byte
    ld      (_lastJ),a

    ; point at first input state block,
    ; return from update function pointing to next
    ;
    ld      hl,inputstates
    call    updateinputstate ; (up)
    call    updateinputstate ; (down)
    call    updateinputstate ;  etc.
    call    updateinputstate ;
    call    updateinputstate
    call    updateinputstate
    call    updateinputstate

    ; fall into here for last input - quit

updateinputstate:
    ld      a,(hl)          ; input info table
    ld      (_uibittest),a  ; get mask for j/s bit test

    inc     hl
    ld      a,(hl)          ; half-row index
    inc     hl
    ld      de,_kbin        ; keyboard bits table pointer - 8 byte aligned
    or      e
    ld      e,a             ; add offset to table
    ld      a,(de)          ; get key input bits
    and     (hl)            ; result will be a = 0 if required key is down
    inc     hl
    jr      z,{+}           ; skip joystick read if pressed

    ld      a,(_lastJ)

+:  sla     (hl)            ; (key & 3) = 0 - not pressed, 1 - just pressed, 2 - just released and >3 - held

_uibittest = $+1
    and     0               ; if a key was already detected a will be 0 so this test succeeds
    jr      nz,{+}          ; otherwise joystick bit is tested - skip if bit = 1 (not pressed)

    set     0,(hl)          ; signify impulse

+:  inc     hl              ; ready for next input in table
    ret

