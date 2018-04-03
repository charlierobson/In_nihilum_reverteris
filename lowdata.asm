    .include codegen/global.inc

    .org    LOWDATSTART

    .exportmode assembly

widths:
    .incbin textgamefont-widths.bin
    .incbin textgamefont-i-widths.bin

    bytesperline = 32 * word(192/SCREENLINES)

linestarts: ; contains some redundancy
    .word   $2000+ 0*bytesperline, $2000+ 1*bytesperline, $2000+ 2*bytesperline, $2000+ 3*bytesperline
    .word   $2000+ 4*bytesperline, $2000+ 5*bytesperline, $2000+ 6*bytesperline, $2000+ 7*bytesperline
    .word   $2000+ 8*bytesperline, $2000+ 9*bytesperline, $2000+10*bytesperline, $2000+11*bytesperline
    .word   $2000+12*bytesperline, $2000+13*bytesperline, $2000+14*bytesperline, $2000+15*bytesperline
    .word   $2000+16*bytesperline, $2000+17*bytesperline, $2000+18*bytesperline, $2000+19*bytesperline

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
cpM = 22

chapterptrs:
	.word	chp_0,  chp_1,  chp_2,  chp_3,  chp_4,  chp_5
	.word	chp_6,  chp_7,  chp_8,  chp_9,  chp_10, chp_11
	.word	chp_12, chp_13, chp_14, chp_15, chp_16, chp_17
	.word	chp_18, chp_19, chp_20, chp_21, chp_22

    .include "codegen/chapterdat.asm"


    .export     widths, linestarts, chapterptrs