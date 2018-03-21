.define PAGE .byte
.define JUMP .byte
.define BMAP .byte
chp_0:  ;  0
	BMAP	-1
	JUMP	$01, $ff, $ff
	PAGE	$00
	PAGE	$11
	PAGE	$22
	PAGE	$34
	PAGE	-1
chp_1:  ;  1
	BMAP	1
	JUMP	$02, $ff, $ff
	PAGE	$00
	PAGE	$11
	PAGE	$22
	PAGE	$33
	PAGE	$44
	PAGE	-1
chp_2:  ;  2
	BMAP	-1
	JUMP	$03, $04, $ff
	PAGE	$00
	PAGE	$12
	PAGE	-1
chp_3:  ;  3
	BMAP	-1
	JUMP	$05, $ff, $ff
	PAGE	$00
	PAGE	$11
	PAGE	$22
	PAGE	$33
	PAGE	-1
chp_4:  ;  4
	BMAP	-1
	JUMP	$05, $ff, $ff
	PAGE	$00
	PAGE	$11
	PAGE	$22
	PAGE	$33
	PAGE	$44
	PAGE	-1
chp_5:  ;  5
	BMAP	2
	JUMP	$06, $07, $ff
	PAGE	$00
	PAGE	$11
	PAGE	$22
	PAGE	$33
	PAGE	$44
	PAGE	$56
	PAGE	-1
chp_6:  ;  6
	BMAP	-1
	JUMP	$08, $ff, $ff
	PAGE	$00
	PAGE	$11
	PAGE	$22
	PAGE	$33
	PAGE	$44
	PAGE	$55
	PAGE	$66
	PAGE	$77
	PAGE	$88
	PAGE	$99
	PAGE	$aa
	PAGE	-1
chp_7:  ;  7
	BMAP	-1
	JUMP	$08, $ff, $ff
	PAGE	$00
	PAGE	$11
	PAGE	$22
	PAGE	$33
	PAGE	$44
	PAGE	$55
	PAGE	$66
	PAGE	$77
	PAGE	-1
chp_8:  ;  8
	BMAP	3
	JUMP	$09, $00, $ff
	PAGE	$00
	PAGE	$11
	PAGE	$22
	PAGE	$33
	PAGE	$44
	PAGE	$55
	PAGE	$66
	PAGE	$77
	PAGE	$88
	PAGE	$99
	PAGE	-1
chp_9:  ;  9
	BMAP	4
	JUMP	$0a, $0b, $0c
	PAGE	$00
	PAGE	$11
	PAGE	$22
	PAGE	$33
	PAGE	$44
	PAGE	$55
	PAGE	-1
chp_10:  ;  A
	BMAP	-1
	JUMP	$0d, $ff, $ff
	PAGE	$00
	PAGE	$12
	PAGE	$23
	PAGE	$34
	PAGE	$46
	PAGE	$57
	PAGE	$68
	PAGE	$79
	PAGE	$8a
	PAGE	-1
chp_11:  ;  B
	BMAP	-1
	JUMP	$0d, $ff, $ff
	PAGE	$00
	PAGE	$12
	PAGE	$23
	PAGE	$35
	PAGE	$46
	PAGE	$57
	PAGE	$69
	PAGE	$7a
	PAGE	$8b
	PAGE	$9c
	PAGE	-1
chp_12:  ;  C
	BMAP	-1
	JUMP	$0d, $ff, $ff
	PAGE	$00
	PAGE	$12
	PAGE	$23
	PAGE	$34
	PAGE	$45
	PAGE	$56
	PAGE	$67
	PAGE	$78
	PAGE	$89
	PAGE	-1
chp_13:  ;  D
	BMAP	5
	JUMP	$0e, $ff, $ff
	PAGE	$00
	PAGE	$11
	PAGE	$22
	PAGE	-1
chp_14:  ;  E
	BMAP	6
	JUMP	$0f, $10, $ff
	PAGE	$00
	PAGE	$11
	PAGE	$23
	PAGE	$34
	PAGE	$45
	PAGE	$56
	PAGE	$67
	PAGE	$78
	PAGE	$89
	PAGE	$9b
	PAGE	$ac
	PAGE	-1
chp_15:  ;  F
	BMAP	7
	JUMP	$11, $ff, $ff
	PAGE	$00
	PAGE	$11
	PAGE	$22
	PAGE	$33
	PAGE	$44
	PAGE	-1
chp_16:  ;  G
	BMAP	-1
	JUMP	$01, $ff, $ff
	PAGE	$00
	PAGE	$11
	PAGE	$22
	PAGE	$33
	PAGE	$44
	PAGE	-1
chp_17:  ;  H
	BMAP	8
	JUMP	$12, $13, $ff
	PAGE	$00
	PAGE	$11
	PAGE	$22
	PAGE	$33
	PAGE	$44
	PAGE	-1
chp_18:  ;  I
	BMAP	-1
	JUMP	$14, $15, $ff
	PAGE	$00
	PAGE	$11
	PAGE	$22
	PAGE	$33
	PAGE	$44
	PAGE	$55
	PAGE	$66
	PAGE	$77
	PAGE	$88
	PAGE	-1
chp_19:  ;  J
	BMAP	-1
	JUMP	$14, $ff, $ff
	PAGE	$00
	PAGE	$11
	PAGE	$22
	PAGE	$33
	PAGE	$44
	PAGE	$55
	PAGE	$66
	PAGE	$77
	PAGE	-1
chp_20:  ;  K
	BMAP	9
	JUMP	$ff, $ff, $ff
	PAGE	$00
	PAGE	$11
	PAGE	$23
	PAGE	$34
	PAGE	$45
	PAGE	$56
	PAGE	$67
	PAGE	$78
	PAGE	$8a
	PAGE	-1
chp_21:  ;  L
	BMAP	-1
	JUMP	$01, $ff, $ff
	PAGE	$00
	PAGE	$11
	PAGE	$22
	PAGE	$33
	PAGE	$44
	PAGE	-1
