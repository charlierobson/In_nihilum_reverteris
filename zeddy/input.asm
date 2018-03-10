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
; joystick bit, or $ff/%11111111 for no joy
; key row offset 0-7,
; key mask, or $ff/%11111111 for no key
; trigger impulse



inputstates:
    .byte	%10000000,2,%00000001,0        ; up      (Q)
    .byte	%01000000,1,%00000001,0        ; down    (A)
    .byte	%00100000,7,%00001000,0        ; left    (N)
    .byte	%00010000,7,%00000100,0        ; right   (M)
    .byte	%00001000,7,%00000001,0        ; fire    (SP)
    .byte	%11111111,3,%00000001,0        ; advance (1)
    .byte	%11111111,4,%00000001,0        ; feature (0)
    .byte	%11111111,5,%00000001,0        ; pause   (P)


; calculate actual input impulse addresses
up      = inputstates + 3
down    = inputstates + 7
left    = inputstates + 11
right   = inputstates + 15
fire    = inputstates + 19
advance = inputstates + 23
feature = inputstates + 27
pause   = inputstates + 31


    .align  8
_kbin:
    .fill   8

_lastJ:
    .byte   0

_nullstick:
    ld      a,$ff
    ret

readinput:
jsreadfn = $+1
    call    _nullstick
    ld      (_lastJ),a

    ; point at first input state block
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
