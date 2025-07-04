// Code generated by command: go run asm.go -out ../sha1cdblock_amd64.s -pkg sha1cd. DO NOT EDIT.

//go:build !noasm && gc && amd64 && !arm64

#include "textflag.h"

// func blockAMD64(dig *digest, p []byte, m1 []uint32, cs [][5]uint32)
TEXT ·blockAMD64(SB), NOSPLIT, $64-80
	MOVQ dig+0(FP), R8
	MOVQ p_base+8(FP), DI
	MOVQ p_len+16(FP), DX
	SHRQ $+6, DX
	SHLQ $+6, DX
	LEAQ (DI)(DX*1), SI

	// Load h0, h1, h2, h3, h4.
	MOVL (R8), AX
	MOVL 4(R8), BX
	MOVL 8(R8), CX
	MOVL 12(R8), DX
	MOVL 16(R8), BP

	// len(p) >= chunk
	CMPQ DI, SI
	JEQ  end

loop:
	// Initialize registers a, b, c, d, e.
	MOVL AX, R10
	MOVL BX, R11
	MOVL CX, R12
	MOVL DX, R13
	MOVL BP, R14

	// ROUND1 (steps 0-15)
	// Load cs
	MOVQ cs_base+56(FP), R8
	MOVL R10, (R8)
	MOVL R11, 4(R8)
	MOVL R12, 8(R8)
	MOVL R13, 12(R8)
	MOVL R14, 16(R8)

	// ROUND1(0)
	// LOAD
	MOVL   (DI), R9
	BSWAPL R9
	MOVL   R9, (SP)

	// FUNC1
	MOVL R13, R15
	XORL R12, R15
	ANDL R11, R15
	XORL R13, R15

	// MIX
	ROLL $+30, R11
	ADDL R15, R14
	MOVL R10, R8
	ROLL $+5, R8
	LEAL 1518500249(R14)(R9*1), R14
	ADDL R8, R14

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL (SP), R9
	MOVL R9, (R8)

	// ROUND1(1)
	// LOAD
	MOVL   4(DI), R9
	BSWAPL R9
	MOVL   R9, 4(SP)

	// FUNC1
	MOVL R12, R15
	XORL R11, R15
	ANDL R10, R15
	XORL R12, R15

	// MIX
	ROLL $+30, R10
	ADDL R15, R13
	MOVL R14, R8
	ROLL $+5, R8
	LEAL 1518500249(R13)(R9*1), R13
	ADDL R8, R13

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 4(SP), R9
	MOVL R9, 4(R8)

	// ROUND1(2)
	// LOAD
	MOVL   8(DI), R9
	BSWAPL R9
	MOVL   R9, 8(SP)

	// FUNC1
	MOVL R11, R15
	XORL R10, R15
	ANDL R14, R15
	XORL R11, R15

	// MIX
	ROLL $+30, R14
	ADDL R15, R12
	MOVL R13, R8
	ROLL $+5, R8
	LEAL 1518500249(R12)(R9*1), R12
	ADDL R8, R12

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 8(SP), R9
	MOVL R9, 8(R8)

	// ROUND1(3)
	// LOAD
	MOVL   12(DI), R9
	BSWAPL R9
	MOVL   R9, 12(SP)

	// FUNC1
	MOVL R10, R15
	XORL R14, R15
	ANDL R13, R15
	XORL R10, R15

	// MIX
	ROLL $+30, R13
	ADDL R15, R11
	MOVL R12, R8
	ROLL $+5, R8
	LEAL 1518500249(R11)(R9*1), R11
	ADDL R8, R11

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 12(SP), R9
	MOVL R9, 12(R8)

	// ROUND1(4)
	// LOAD
	MOVL   16(DI), R9
	BSWAPL R9
	MOVL   R9, 16(SP)

	// FUNC1
	MOVL R14, R15
	XORL R13, R15
	ANDL R12, R15
	XORL R14, R15

	// MIX
	ROLL $+30, R12
	ADDL R15, R10
	MOVL R11, R8
	ROLL $+5, R8
	LEAL 1518500249(R10)(R9*1), R10
	ADDL R8, R10

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 16(SP), R9
	MOVL R9, 16(R8)

	// ROUND1(5)
	// LOAD
	MOVL   20(DI), R9
	BSWAPL R9
	MOVL   R9, 20(SP)

	// FUNC1
	MOVL R13, R15
	XORL R12, R15
	ANDL R11, R15
	XORL R13, R15

	// MIX
	ROLL $+30, R11
	ADDL R15, R14
	MOVL R10, R8
	ROLL $+5, R8
	LEAL 1518500249(R14)(R9*1), R14
	ADDL R8, R14

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 20(SP), R9
	MOVL R9, 20(R8)

	// ROUND1(6)
	// LOAD
	MOVL   24(DI), R9
	BSWAPL R9
	MOVL   R9, 24(SP)

	// FUNC1
	MOVL R12, R15
	XORL R11, R15
	ANDL R10, R15
	XORL R12, R15

	// MIX
	ROLL $+30, R10
	ADDL R15, R13
	MOVL R14, R8
	ROLL $+5, R8
	LEAL 1518500249(R13)(R9*1), R13
	ADDL R8, R13

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 24(SP), R9
	MOVL R9, 24(R8)

	// ROUND1(7)
	// LOAD
	MOVL   28(DI), R9
	BSWAPL R9
	MOVL   R9, 28(SP)

	// FUNC1
	MOVL R11, R15
	XORL R10, R15
	ANDL R14, R15
	XORL R11, R15

	// MIX
	ROLL $+30, R14
	ADDL R15, R12
	MOVL R13, R8
	ROLL $+5, R8
	LEAL 1518500249(R12)(R9*1), R12
	ADDL R8, R12

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 28(SP), R9
	MOVL R9, 28(R8)

	// ROUND1(8)
	// LOAD
	MOVL   32(DI), R9
	BSWAPL R9
	MOVL   R9, 32(SP)

	// FUNC1
	MOVL R10, R15
	XORL R14, R15
	ANDL R13, R15
	XORL R10, R15

	// MIX
	ROLL $+30, R13
	ADDL R15, R11
	MOVL R12, R8
	ROLL $+5, R8
	LEAL 1518500249(R11)(R9*1), R11
	ADDL R8, R11

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 32(SP), R9
	MOVL R9, 32(R8)

	// ROUND1(9)
	// LOAD
	MOVL   36(DI), R9
	BSWAPL R9
	MOVL   R9, 36(SP)

	// FUNC1
	MOVL R14, R15
	XORL R13, R15
	ANDL R12, R15
	XORL R14, R15

	// MIX
	ROLL $+30, R12
	ADDL R15, R10
	MOVL R11, R8
	ROLL $+5, R8
	LEAL 1518500249(R10)(R9*1), R10
	ADDL R8, R10

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 36(SP), R9
	MOVL R9, 36(R8)

	// ROUND1(10)
	// LOAD
	MOVL   40(DI), R9
	BSWAPL R9
	MOVL   R9, 40(SP)

	// FUNC1
	MOVL R13, R15
	XORL R12, R15
	ANDL R11, R15
	XORL R13, R15

	// MIX
	ROLL $+30, R11
	ADDL R15, R14
	MOVL R10, R8
	ROLL $+5, R8
	LEAL 1518500249(R14)(R9*1), R14
	ADDL R8, R14

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 40(SP), R9
	MOVL R9, 40(R8)

	// ROUND1(11)
	// LOAD
	MOVL   44(DI), R9
	BSWAPL R9
	MOVL   R9, 44(SP)

	// FUNC1
	MOVL R12, R15
	XORL R11, R15
	ANDL R10, R15
	XORL R12, R15

	// MIX
	ROLL $+30, R10
	ADDL R15, R13
	MOVL R14, R8
	ROLL $+5, R8
	LEAL 1518500249(R13)(R9*1), R13
	ADDL R8, R13

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 44(SP), R9
	MOVL R9, 44(R8)

	// ROUND1(12)
	// LOAD
	MOVL   48(DI), R9
	BSWAPL R9
	MOVL   R9, 48(SP)

	// FUNC1
	MOVL R11, R15
	XORL R10, R15
	ANDL R14, R15
	XORL R11, R15

	// MIX
	ROLL $+30, R14
	ADDL R15, R12
	MOVL R13, R8
	ROLL $+5, R8
	LEAL 1518500249(R12)(R9*1), R12
	ADDL R8, R12

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 48(SP), R9
	MOVL R9, 48(R8)

	// ROUND1(13)
	// LOAD
	MOVL   52(DI), R9
	BSWAPL R9
	MOVL   R9, 52(SP)

	// FUNC1
	MOVL R10, R15
	XORL R14, R15
	ANDL R13, R15
	XORL R10, R15

	// MIX
	ROLL $+30, R13
	ADDL R15, R11
	MOVL R12, R8
	ROLL $+5, R8
	LEAL 1518500249(R11)(R9*1), R11
	ADDL R8, R11

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 52(SP), R9
	MOVL R9, 52(R8)

	// ROUND1(14)
	// LOAD
	MOVL   56(DI), R9
	BSWAPL R9
	MOVL   R9, 56(SP)

	// FUNC1
	MOVL R14, R15
	XORL R13, R15
	ANDL R12, R15
	XORL R14, R15

	// MIX
	ROLL $+30, R12
	ADDL R15, R10
	MOVL R11, R8
	ROLL $+5, R8
	LEAL 1518500249(R10)(R9*1), R10
	ADDL R8, R10

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 56(SP), R9
	MOVL R9, 56(R8)

	// ROUND1(15)
	// LOAD
	MOVL   60(DI), R9
	BSWAPL R9
	MOVL   R9, 60(SP)

	// FUNC1
	MOVL R13, R15
	XORL R12, R15
	ANDL R11, R15
	XORL R13, R15

	// MIX
	ROLL $+30, R11
	ADDL R15, R14
	MOVL R10, R8
	ROLL $+5, R8
	LEAL 1518500249(R14)(R9*1), R14
	ADDL R8, R14

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 60(SP), R9
	MOVL R9, 60(R8)

	// ROUND1x (steps 16-19) - same as ROUND1 but with no data load.
	// ROUND1x(16)
	// SHUFFLE
	MOVL (SP), R9
	XORL 52(SP), R9
	XORL 32(SP), R9
	XORL 8(SP), R9
	ROLL $+1, R9
	MOVL R9, (SP)

	// FUNC1
	MOVL R12, R15
	XORL R11, R15
	ANDL R10, R15
	XORL R12, R15

	// MIX
	ROLL $+30, R10
	ADDL R15, R13
	MOVL R14, R8
	ROLL $+5, R8
	LEAL 1518500249(R13)(R9*1), R13
	ADDL R8, R13

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL (SP), R9
	MOVL R9, 64(R8)

	// ROUND1x(17)
	// SHUFFLE
	MOVL 4(SP), R9
	XORL 56(SP), R9
	XORL 36(SP), R9
	XORL 12(SP), R9
	ROLL $+1, R9
	MOVL R9, 4(SP)

	// FUNC1
	MOVL R11, R15
	XORL R10, R15
	ANDL R14, R15
	XORL R11, R15

	// MIX
	ROLL $+30, R14
	ADDL R15, R12
	MOVL R13, R8
	ROLL $+5, R8
	LEAL 1518500249(R12)(R9*1), R12
	ADDL R8, R12

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 4(SP), R9
	MOVL R9, 68(R8)

	// ROUND1x(18)
	// SHUFFLE
	MOVL 8(SP), R9
	XORL 60(SP), R9
	XORL 40(SP), R9
	XORL 16(SP), R9
	ROLL $+1, R9
	MOVL R9, 8(SP)

	// FUNC1
	MOVL R10, R15
	XORL R14, R15
	ANDL R13, R15
	XORL R10, R15

	// MIX
	ROLL $+30, R13
	ADDL R15, R11
	MOVL R12, R8
	ROLL $+5, R8
	LEAL 1518500249(R11)(R9*1), R11
	ADDL R8, R11

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 8(SP), R9
	MOVL R9, 72(R8)

	// ROUND1x(19)
	// SHUFFLE
	MOVL 12(SP), R9
	XORL (SP), R9
	XORL 44(SP), R9
	XORL 20(SP), R9
	ROLL $+1, R9
	MOVL R9, 12(SP)

	// FUNC1
	MOVL R14, R15
	XORL R13, R15
	ANDL R12, R15
	XORL R14, R15

	// MIX
	ROLL $+30, R12
	ADDL R15, R10
	MOVL R11, R8
	ROLL $+5, R8
	LEAL 1518500249(R10)(R9*1), R10
	ADDL R8, R10

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 12(SP), R9
	MOVL R9, 76(R8)

	// ROUND2 (steps 20-39)
	// ROUND2(20)
	// SHUFFLE
	MOVL 16(SP), R9
	XORL 4(SP), R9
	XORL 48(SP), R9
	XORL 24(SP), R9
	ROLL $+1, R9
	MOVL R9, 16(SP)

	// FUNC2
	MOVL R11, R15
	XORL R12, R15
	XORL R13, R15

	// MIX
	ROLL $+30, R11
	ADDL R15, R14
	MOVL R10, R8
	ROLL $+5, R8
	LEAL 1859775393(R14)(R9*1), R14
	ADDL R8, R14

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 16(SP), R9
	MOVL R9, 80(R8)

	// ROUND2(21)
	// SHUFFLE
	MOVL 20(SP), R9
	XORL 8(SP), R9
	XORL 52(SP), R9
	XORL 28(SP), R9
	ROLL $+1, R9
	MOVL R9, 20(SP)

	// FUNC2
	MOVL R10, R15
	XORL R11, R15
	XORL R12, R15

	// MIX
	ROLL $+30, R10
	ADDL R15, R13
	MOVL R14, R8
	ROLL $+5, R8
	LEAL 1859775393(R13)(R9*1), R13
	ADDL R8, R13

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 20(SP), R9
	MOVL R9, 84(R8)

	// ROUND2(22)
	// SHUFFLE
	MOVL 24(SP), R9
	XORL 12(SP), R9
	XORL 56(SP), R9
	XORL 32(SP), R9
	ROLL $+1, R9
	MOVL R9, 24(SP)

	// FUNC2
	MOVL R14, R15
	XORL R10, R15
	XORL R11, R15

	// MIX
	ROLL $+30, R14
	ADDL R15, R12
	MOVL R13, R8
	ROLL $+5, R8
	LEAL 1859775393(R12)(R9*1), R12
	ADDL R8, R12

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 24(SP), R9
	MOVL R9, 88(R8)

	// ROUND2(23)
	// SHUFFLE
	MOVL 28(SP), R9
	XORL 16(SP), R9
	XORL 60(SP), R9
	XORL 36(SP), R9
	ROLL $+1, R9
	MOVL R9, 28(SP)

	// FUNC2
	MOVL R13, R15
	XORL R14, R15
	XORL R10, R15

	// MIX
	ROLL $+30, R13
	ADDL R15, R11
	MOVL R12, R8
	ROLL $+5, R8
	LEAL 1859775393(R11)(R9*1), R11
	ADDL R8, R11

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 28(SP), R9
	MOVL R9, 92(R8)

	// ROUND2(24)
	// SHUFFLE
	MOVL 32(SP), R9
	XORL 20(SP), R9
	XORL (SP), R9
	XORL 40(SP), R9
	ROLL $+1, R9
	MOVL R9, 32(SP)

	// FUNC2
	MOVL R12, R15
	XORL R13, R15
	XORL R14, R15

	// MIX
	ROLL $+30, R12
	ADDL R15, R10
	MOVL R11, R8
	ROLL $+5, R8
	LEAL 1859775393(R10)(R9*1), R10
	ADDL R8, R10

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 32(SP), R9
	MOVL R9, 96(R8)

	// ROUND2(25)
	// SHUFFLE
	MOVL 36(SP), R9
	XORL 24(SP), R9
	XORL 4(SP), R9
	XORL 44(SP), R9
	ROLL $+1, R9
	MOVL R9, 36(SP)

	// FUNC2
	MOVL R11, R15
	XORL R12, R15
	XORL R13, R15

	// MIX
	ROLL $+30, R11
	ADDL R15, R14
	MOVL R10, R8
	ROLL $+5, R8
	LEAL 1859775393(R14)(R9*1), R14
	ADDL R8, R14

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 36(SP), R9
	MOVL R9, 100(R8)

	// ROUND2(26)
	// SHUFFLE
	MOVL 40(SP), R9
	XORL 28(SP), R9
	XORL 8(SP), R9
	XORL 48(SP), R9
	ROLL $+1, R9
	MOVL R9, 40(SP)

	// FUNC2
	MOVL R10, R15
	XORL R11, R15
	XORL R12, R15

	// MIX
	ROLL $+30, R10
	ADDL R15, R13
	MOVL R14, R8
	ROLL $+5, R8
	LEAL 1859775393(R13)(R9*1), R13
	ADDL R8, R13

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 40(SP), R9
	MOVL R9, 104(R8)

	// ROUND2(27)
	// SHUFFLE
	MOVL 44(SP), R9
	XORL 32(SP), R9
	XORL 12(SP), R9
	XORL 52(SP), R9
	ROLL $+1, R9
	MOVL R9, 44(SP)

	// FUNC2
	MOVL R14, R15
	XORL R10, R15
	XORL R11, R15

	// MIX
	ROLL $+30, R14
	ADDL R15, R12
	MOVL R13, R8
	ROLL $+5, R8
	LEAL 1859775393(R12)(R9*1), R12
	ADDL R8, R12

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 44(SP), R9
	MOVL R9, 108(R8)

	// ROUND2(28)
	// SHUFFLE
	MOVL 48(SP), R9
	XORL 36(SP), R9
	XORL 16(SP), R9
	XORL 56(SP), R9
	ROLL $+1, R9
	MOVL R9, 48(SP)

	// FUNC2
	MOVL R13, R15
	XORL R14, R15
	XORL R10, R15

	// MIX
	ROLL $+30, R13
	ADDL R15, R11
	MOVL R12, R8
	ROLL $+5, R8
	LEAL 1859775393(R11)(R9*1), R11
	ADDL R8, R11

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 48(SP), R9
	MOVL R9, 112(R8)

	// ROUND2(29)
	// SHUFFLE
	MOVL 52(SP), R9
	XORL 40(SP), R9
	XORL 20(SP), R9
	XORL 60(SP), R9
	ROLL $+1, R9
	MOVL R9, 52(SP)

	// FUNC2
	MOVL R12, R15
	XORL R13, R15
	XORL R14, R15

	// MIX
	ROLL $+30, R12
	ADDL R15, R10
	MOVL R11, R8
	ROLL $+5, R8
	LEAL 1859775393(R10)(R9*1), R10
	ADDL R8, R10

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 52(SP), R9
	MOVL R9, 116(R8)

	// ROUND2(30)
	// SHUFFLE
	MOVL 56(SP), R9
	XORL 44(SP), R9
	XORL 24(SP), R9
	XORL (SP), R9
	ROLL $+1, R9
	MOVL R9, 56(SP)

	// FUNC2
	MOVL R11, R15
	XORL R12, R15
	XORL R13, R15

	// MIX
	ROLL $+30, R11
	ADDL R15, R14
	MOVL R10, R8
	ROLL $+5, R8
	LEAL 1859775393(R14)(R9*1), R14
	ADDL R8, R14

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 56(SP), R9
	MOVL R9, 120(R8)

	// ROUND2(31)
	// SHUFFLE
	MOVL 60(SP), R9
	XORL 48(SP), R9
	XORL 28(SP), R9
	XORL 4(SP), R9
	ROLL $+1, R9
	MOVL R9, 60(SP)

	// FUNC2
	MOVL R10, R15
	XORL R11, R15
	XORL R12, R15

	// MIX
	ROLL $+30, R10
	ADDL R15, R13
	MOVL R14, R8
	ROLL $+5, R8
	LEAL 1859775393(R13)(R9*1), R13
	ADDL R8, R13

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 60(SP), R9
	MOVL R9, 124(R8)

	// ROUND2(32)
	// SHUFFLE
	MOVL (SP), R9
	XORL 52(SP), R9
	XORL 32(SP), R9
	XORL 8(SP), R9
	ROLL $+1, R9
	MOVL R9, (SP)

	// FUNC2
	MOVL R14, R15
	XORL R10, R15
	XORL R11, R15

	// MIX
	ROLL $+30, R14
	ADDL R15, R12
	MOVL R13, R8
	ROLL $+5, R8
	LEAL 1859775393(R12)(R9*1), R12
	ADDL R8, R12

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL (SP), R9
	MOVL R9, 128(R8)

	// ROUND2(33)
	// SHUFFLE
	MOVL 4(SP), R9
	XORL 56(SP), R9
	XORL 36(SP), R9
	XORL 12(SP), R9
	ROLL $+1, R9
	MOVL R9, 4(SP)

	// FUNC2
	MOVL R13, R15
	XORL R14, R15
	XORL R10, R15

	// MIX
	ROLL $+30, R13
	ADDL R15, R11
	MOVL R12, R8
	ROLL $+5, R8
	LEAL 1859775393(R11)(R9*1), R11
	ADDL R8, R11

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 4(SP), R9
	MOVL R9, 132(R8)

	// ROUND2(34)
	// SHUFFLE
	MOVL 8(SP), R9
	XORL 60(SP), R9
	XORL 40(SP), R9
	XORL 16(SP), R9
	ROLL $+1, R9
	MOVL R9, 8(SP)

	// FUNC2
	MOVL R12, R15
	XORL R13, R15
	XORL R14, R15

	// MIX
	ROLL $+30, R12
	ADDL R15, R10
	MOVL R11, R8
	ROLL $+5, R8
	LEAL 1859775393(R10)(R9*1), R10
	ADDL R8, R10

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 8(SP), R9
	MOVL R9, 136(R8)

	// ROUND2(35)
	// SHUFFLE
	MOVL 12(SP), R9
	XORL (SP), R9
	XORL 44(SP), R9
	XORL 20(SP), R9
	ROLL $+1, R9
	MOVL R9, 12(SP)

	// FUNC2
	MOVL R11, R15
	XORL R12, R15
	XORL R13, R15

	// MIX
	ROLL $+30, R11
	ADDL R15, R14
	MOVL R10, R8
	ROLL $+5, R8
	LEAL 1859775393(R14)(R9*1), R14
	ADDL R8, R14

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 12(SP), R9
	MOVL R9, 140(R8)

	// ROUND2(36)
	// SHUFFLE
	MOVL 16(SP), R9
	XORL 4(SP), R9
	XORL 48(SP), R9
	XORL 24(SP), R9
	ROLL $+1, R9
	MOVL R9, 16(SP)

	// FUNC2
	MOVL R10, R15
	XORL R11, R15
	XORL R12, R15

	// MIX
	ROLL $+30, R10
	ADDL R15, R13
	MOVL R14, R8
	ROLL $+5, R8
	LEAL 1859775393(R13)(R9*1), R13
	ADDL R8, R13

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 16(SP), R9
	MOVL R9, 144(R8)

	// ROUND2(37)
	// SHUFFLE
	MOVL 20(SP), R9
	XORL 8(SP), R9
	XORL 52(SP), R9
	XORL 28(SP), R9
	ROLL $+1, R9
	MOVL R9, 20(SP)

	// FUNC2
	MOVL R14, R15
	XORL R10, R15
	XORL R11, R15

	// MIX
	ROLL $+30, R14
	ADDL R15, R12
	MOVL R13, R8
	ROLL $+5, R8
	LEAL 1859775393(R12)(R9*1), R12
	ADDL R8, R12

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 20(SP), R9
	MOVL R9, 148(R8)

	// ROUND2(38)
	// SHUFFLE
	MOVL 24(SP), R9
	XORL 12(SP), R9
	XORL 56(SP), R9
	XORL 32(SP), R9
	ROLL $+1, R9
	MOVL R9, 24(SP)

	// FUNC2
	MOVL R13, R15
	XORL R14, R15
	XORL R10, R15

	// MIX
	ROLL $+30, R13
	ADDL R15, R11
	MOVL R12, R8
	ROLL $+5, R8
	LEAL 1859775393(R11)(R9*1), R11
	ADDL R8, R11

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 24(SP), R9
	MOVL R9, 152(R8)

	// ROUND2(39)
	// SHUFFLE
	MOVL 28(SP), R9
	XORL 16(SP), R9
	XORL 60(SP), R9
	XORL 36(SP), R9
	ROLL $+1, R9
	MOVL R9, 28(SP)

	// FUNC2
	MOVL R12, R15
	XORL R13, R15
	XORL R14, R15

	// MIX
	ROLL $+30, R12
	ADDL R15, R10
	MOVL R11, R8
	ROLL $+5, R8
	LEAL 1859775393(R10)(R9*1), R10
	ADDL R8, R10

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 28(SP), R9
	MOVL R9, 156(R8)

	// ROUND3 (steps 40-59)
	// ROUND3(40)
	// SHUFFLE
	MOVL 32(SP), R9
	XORL 20(SP), R9
	XORL (SP), R9
	XORL 40(SP), R9
	ROLL $+1, R9
	MOVL R9, 32(SP)

	// FUNC3
	MOVL R11, R8
	ORL  R12, R8
	ANDL R13, R8
	MOVL R11, R15
	ANDL R12, R15
	ORL  R8, R15

	// MIX
	ROLL $+30, R11
	ADDL R15, R14
	MOVL R10, R8
	ROLL $+5, R8
	LEAL 2400959708(R14)(R9*1), R14
	ADDL R8, R14

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 32(SP), R9
	MOVL R9, 160(R8)

	// ROUND3(41)
	// SHUFFLE
	MOVL 36(SP), R9
	XORL 24(SP), R9
	XORL 4(SP), R9
	XORL 44(SP), R9
	ROLL $+1, R9
	MOVL R9, 36(SP)

	// FUNC3
	MOVL R10, R8
	ORL  R11, R8
	ANDL R12, R8
	MOVL R10, R15
	ANDL R11, R15
	ORL  R8, R15

	// MIX
	ROLL $+30, R10
	ADDL R15, R13
	MOVL R14, R8
	ROLL $+5, R8
	LEAL 2400959708(R13)(R9*1), R13
	ADDL R8, R13

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 36(SP), R9
	MOVL R9, 164(R8)

	// ROUND3(42)
	// SHUFFLE
	MOVL 40(SP), R9
	XORL 28(SP), R9
	XORL 8(SP), R9
	XORL 48(SP), R9
	ROLL $+1, R9
	MOVL R9, 40(SP)

	// FUNC3
	MOVL R14, R8
	ORL  R10, R8
	ANDL R11, R8
	MOVL R14, R15
	ANDL R10, R15
	ORL  R8, R15

	// MIX
	ROLL $+30, R14
	ADDL R15, R12
	MOVL R13, R8
	ROLL $+5, R8
	LEAL 2400959708(R12)(R9*1), R12
	ADDL R8, R12

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 40(SP), R9
	MOVL R9, 168(R8)

	// ROUND3(43)
	// SHUFFLE
	MOVL 44(SP), R9
	XORL 32(SP), R9
	XORL 12(SP), R9
	XORL 52(SP), R9
	ROLL $+1, R9
	MOVL R9, 44(SP)

	// FUNC3
	MOVL R13, R8
	ORL  R14, R8
	ANDL R10, R8
	MOVL R13, R15
	ANDL R14, R15
	ORL  R8, R15

	// MIX
	ROLL $+30, R13
	ADDL R15, R11
	MOVL R12, R8
	ROLL $+5, R8
	LEAL 2400959708(R11)(R9*1), R11
	ADDL R8, R11

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 44(SP), R9
	MOVL R9, 172(R8)

	// ROUND3(44)
	// SHUFFLE
	MOVL 48(SP), R9
	XORL 36(SP), R9
	XORL 16(SP), R9
	XORL 56(SP), R9
	ROLL $+1, R9
	MOVL R9, 48(SP)

	// FUNC3
	MOVL R12, R8
	ORL  R13, R8
	ANDL R14, R8
	MOVL R12, R15
	ANDL R13, R15
	ORL  R8, R15

	// MIX
	ROLL $+30, R12
	ADDL R15, R10
	MOVL R11, R8
	ROLL $+5, R8
	LEAL 2400959708(R10)(R9*1), R10
	ADDL R8, R10

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 48(SP), R9
	MOVL R9, 176(R8)

	// ROUND3(45)
	// SHUFFLE
	MOVL 52(SP), R9
	XORL 40(SP), R9
	XORL 20(SP), R9
	XORL 60(SP), R9
	ROLL $+1, R9
	MOVL R9, 52(SP)

	// FUNC3
	MOVL R11, R8
	ORL  R12, R8
	ANDL R13, R8
	MOVL R11, R15
	ANDL R12, R15
	ORL  R8, R15

	// MIX
	ROLL $+30, R11
	ADDL R15, R14
	MOVL R10, R8
	ROLL $+5, R8
	LEAL 2400959708(R14)(R9*1), R14
	ADDL R8, R14

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 52(SP), R9
	MOVL R9, 180(R8)

	// ROUND3(46)
	// SHUFFLE
	MOVL 56(SP), R9
	XORL 44(SP), R9
	XORL 24(SP), R9
	XORL (SP), R9
	ROLL $+1, R9
	MOVL R9, 56(SP)

	// FUNC3
	MOVL R10, R8
	ORL  R11, R8
	ANDL R12, R8
	MOVL R10, R15
	ANDL R11, R15
	ORL  R8, R15

	// MIX
	ROLL $+30, R10
	ADDL R15, R13
	MOVL R14, R8
	ROLL $+5, R8
	LEAL 2400959708(R13)(R9*1), R13
	ADDL R8, R13

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 56(SP), R9
	MOVL R9, 184(R8)

	// ROUND3(47)
	// SHUFFLE
	MOVL 60(SP), R9
	XORL 48(SP), R9
	XORL 28(SP), R9
	XORL 4(SP), R9
	ROLL $+1, R9
	MOVL R9, 60(SP)

	// FUNC3
	MOVL R14, R8
	ORL  R10, R8
	ANDL R11, R8
	MOVL R14, R15
	ANDL R10, R15
	ORL  R8, R15

	// MIX
	ROLL $+30, R14
	ADDL R15, R12
	MOVL R13, R8
	ROLL $+5, R8
	LEAL 2400959708(R12)(R9*1), R12
	ADDL R8, R12

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 60(SP), R9
	MOVL R9, 188(R8)

	// ROUND3(48)
	// SHUFFLE
	MOVL (SP), R9
	XORL 52(SP), R9
	XORL 32(SP), R9
	XORL 8(SP), R9
	ROLL $+1, R9
	MOVL R9, (SP)

	// FUNC3
	MOVL R13, R8
	ORL  R14, R8
	ANDL R10, R8
	MOVL R13, R15
	ANDL R14, R15
	ORL  R8, R15

	// MIX
	ROLL $+30, R13
	ADDL R15, R11
	MOVL R12, R8
	ROLL $+5, R8
	LEAL 2400959708(R11)(R9*1), R11
	ADDL R8, R11

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL (SP), R9
	MOVL R9, 192(R8)

	// ROUND3(49)
	// SHUFFLE
	MOVL 4(SP), R9
	XORL 56(SP), R9
	XORL 36(SP), R9
	XORL 12(SP), R9
	ROLL $+1, R9
	MOVL R9, 4(SP)

	// FUNC3
	MOVL R12, R8
	ORL  R13, R8
	ANDL R14, R8
	MOVL R12, R15
	ANDL R13, R15
	ORL  R8, R15

	// MIX
	ROLL $+30, R12
	ADDL R15, R10
	MOVL R11, R8
	ROLL $+5, R8
	LEAL 2400959708(R10)(R9*1), R10
	ADDL R8, R10

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 4(SP), R9
	MOVL R9, 196(R8)

	// ROUND3(50)
	// SHUFFLE
	MOVL 8(SP), R9
	XORL 60(SP), R9
	XORL 40(SP), R9
	XORL 16(SP), R9
	ROLL $+1, R9
	MOVL R9, 8(SP)

	// FUNC3
	MOVL R11, R8
	ORL  R12, R8
	ANDL R13, R8
	MOVL R11, R15
	ANDL R12, R15
	ORL  R8, R15

	// MIX
	ROLL $+30, R11
	ADDL R15, R14
	MOVL R10, R8
	ROLL $+5, R8
	LEAL 2400959708(R14)(R9*1), R14
	ADDL R8, R14

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 8(SP), R9
	MOVL R9, 200(R8)

	// ROUND3(51)
	// SHUFFLE
	MOVL 12(SP), R9
	XORL (SP), R9
	XORL 44(SP), R9
	XORL 20(SP), R9
	ROLL $+1, R9
	MOVL R9, 12(SP)

	// FUNC3
	MOVL R10, R8
	ORL  R11, R8
	ANDL R12, R8
	MOVL R10, R15
	ANDL R11, R15
	ORL  R8, R15

	// MIX
	ROLL $+30, R10
	ADDL R15, R13
	MOVL R14, R8
	ROLL $+5, R8
	LEAL 2400959708(R13)(R9*1), R13
	ADDL R8, R13

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 12(SP), R9
	MOVL R9, 204(R8)

	// ROUND3(52)
	// SHUFFLE
	MOVL 16(SP), R9
	XORL 4(SP), R9
	XORL 48(SP), R9
	XORL 24(SP), R9
	ROLL $+1, R9
	MOVL R9, 16(SP)

	// FUNC3
	MOVL R14, R8
	ORL  R10, R8
	ANDL R11, R8
	MOVL R14, R15
	ANDL R10, R15
	ORL  R8, R15

	// MIX
	ROLL $+30, R14
	ADDL R15, R12
	MOVL R13, R8
	ROLL $+5, R8
	LEAL 2400959708(R12)(R9*1), R12
	ADDL R8, R12

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 16(SP), R9
	MOVL R9, 208(R8)

	// ROUND3(53)
	// SHUFFLE
	MOVL 20(SP), R9
	XORL 8(SP), R9
	XORL 52(SP), R9
	XORL 28(SP), R9
	ROLL $+1, R9
	MOVL R9, 20(SP)

	// FUNC3
	MOVL R13, R8
	ORL  R14, R8
	ANDL R10, R8
	MOVL R13, R15
	ANDL R14, R15
	ORL  R8, R15

	// MIX
	ROLL $+30, R13
	ADDL R15, R11
	MOVL R12, R8
	ROLL $+5, R8
	LEAL 2400959708(R11)(R9*1), R11
	ADDL R8, R11

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 20(SP), R9
	MOVL R9, 212(R8)

	// ROUND3(54)
	// SHUFFLE
	MOVL 24(SP), R9
	XORL 12(SP), R9
	XORL 56(SP), R9
	XORL 32(SP), R9
	ROLL $+1, R9
	MOVL R9, 24(SP)

	// FUNC3
	MOVL R12, R8
	ORL  R13, R8
	ANDL R14, R8
	MOVL R12, R15
	ANDL R13, R15
	ORL  R8, R15

	// MIX
	ROLL $+30, R12
	ADDL R15, R10
	MOVL R11, R8
	ROLL $+5, R8
	LEAL 2400959708(R10)(R9*1), R10
	ADDL R8, R10

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 24(SP), R9
	MOVL R9, 216(R8)

	// ROUND3(55)
	// SHUFFLE
	MOVL 28(SP), R9
	XORL 16(SP), R9
	XORL 60(SP), R9
	XORL 36(SP), R9
	ROLL $+1, R9
	MOVL R9, 28(SP)

	// FUNC3
	MOVL R11, R8
	ORL  R12, R8
	ANDL R13, R8
	MOVL R11, R15
	ANDL R12, R15
	ORL  R8, R15

	// MIX
	ROLL $+30, R11
	ADDL R15, R14
	MOVL R10, R8
	ROLL $+5, R8
	LEAL 2400959708(R14)(R9*1), R14
	ADDL R8, R14

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 28(SP), R9
	MOVL R9, 220(R8)

	// ROUND3(56)
	// SHUFFLE
	MOVL 32(SP), R9
	XORL 20(SP), R9
	XORL (SP), R9
	XORL 40(SP), R9
	ROLL $+1, R9
	MOVL R9, 32(SP)

	// FUNC3
	MOVL R10, R8
	ORL  R11, R8
	ANDL R12, R8
	MOVL R10, R15
	ANDL R11, R15
	ORL  R8, R15

	// MIX
	ROLL $+30, R10
	ADDL R15, R13
	MOVL R14, R8
	ROLL $+5, R8
	LEAL 2400959708(R13)(R9*1), R13
	ADDL R8, R13

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 32(SP), R9
	MOVL R9, 224(R8)

	// ROUND3(57)
	// SHUFFLE
	MOVL 36(SP), R9
	XORL 24(SP), R9
	XORL 4(SP), R9
	XORL 44(SP), R9
	ROLL $+1, R9
	MOVL R9, 36(SP)

	// FUNC3
	MOVL R14, R8
	ORL  R10, R8
	ANDL R11, R8
	MOVL R14, R15
	ANDL R10, R15
	ORL  R8, R15

	// MIX
	ROLL $+30, R14
	ADDL R15, R12
	MOVL R13, R8
	ROLL $+5, R8
	LEAL 2400959708(R12)(R9*1), R12
	ADDL R8, R12

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 36(SP), R9
	MOVL R9, 228(R8)

	// Load cs
	MOVQ cs_base+56(FP), R8
	MOVL R12, 20(R8)
	MOVL R13, 24(R8)
	MOVL R14, 28(R8)
	MOVL R10, 32(R8)
	MOVL R11, 36(R8)

	// ROUND3(58)
	// SHUFFLE
	MOVL 40(SP), R9
	XORL 28(SP), R9
	XORL 8(SP), R9
	XORL 48(SP), R9
	ROLL $+1, R9
	MOVL R9, 40(SP)

	// FUNC3
	MOVL R13, R8
	ORL  R14, R8
	ANDL R10, R8
	MOVL R13, R15
	ANDL R14, R15
	ORL  R8, R15

	// MIX
	ROLL $+30, R13
	ADDL R15, R11
	MOVL R12, R8
	ROLL $+5, R8
	LEAL 2400959708(R11)(R9*1), R11
	ADDL R8, R11

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 40(SP), R9
	MOVL R9, 232(R8)

	// ROUND3(59)
	// SHUFFLE
	MOVL 44(SP), R9
	XORL 32(SP), R9
	XORL 12(SP), R9
	XORL 52(SP), R9
	ROLL $+1, R9
	MOVL R9, 44(SP)

	// FUNC3
	MOVL R12, R8
	ORL  R13, R8
	ANDL R14, R8
	MOVL R12, R15
	ANDL R13, R15
	ORL  R8, R15

	// MIX
	ROLL $+30, R12
	ADDL R15, R10
	MOVL R11, R8
	ROLL $+5, R8
	LEAL 2400959708(R10)(R9*1), R10
	ADDL R8, R10

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 44(SP), R9
	MOVL R9, 236(R8)

	// ROUND4 (steps 60-79)
	// ROUND4(60)
	// SHUFFLE
	MOVL 48(SP), R9
	XORL 36(SP), R9
	XORL 16(SP), R9
	XORL 56(SP), R9
	ROLL $+1, R9
	MOVL R9, 48(SP)

	// FUNC2
	MOVL R11, R15
	XORL R12, R15
	XORL R13, R15

	// MIX
	ROLL $+30, R11
	ADDL R15, R14
	MOVL R10, R8
	ROLL $+5, R8
	LEAL 3395469782(R14)(R9*1), R14
	ADDL R8, R14

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 48(SP), R9
	MOVL R9, 240(R8)

	// ROUND4(61)
	// SHUFFLE
	MOVL 52(SP), R9
	XORL 40(SP), R9
	XORL 20(SP), R9
	XORL 60(SP), R9
	ROLL $+1, R9
	MOVL R9, 52(SP)

	// FUNC2
	MOVL R10, R15
	XORL R11, R15
	XORL R12, R15

	// MIX
	ROLL $+30, R10
	ADDL R15, R13
	MOVL R14, R8
	ROLL $+5, R8
	LEAL 3395469782(R13)(R9*1), R13
	ADDL R8, R13

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 52(SP), R9
	MOVL R9, 244(R8)

	// ROUND4(62)
	// SHUFFLE
	MOVL 56(SP), R9
	XORL 44(SP), R9
	XORL 24(SP), R9
	XORL (SP), R9
	ROLL $+1, R9
	MOVL R9, 56(SP)

	// FUNC2
	MOVL R14, R15
	XORL R10, R15
	XORL R11, R15

	// MIX
	ROLL $+30, R14
	ADDL R15, R12
	MOVL R13, R8
	ROLL $+5, R8
	LEAL 3395469782(R12)(R9*1), R12
	ADDL R8, R12

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 56(SP), R9
	MOVL R9, 248(R8)

	// ROUND4(63)
	// SHUFFLE
	MOVL 60(SP), R9
	XORL 48(SP), R9
	XORL 28(SP), R9
	XORL 4(SP), R9
	ROLL $+1, R9
	MOVL R9, 60(SP)

	// FUNC2
	MOVL R13, R15
	XORL R14, R15
	XORL R10, R15

	// MIX
	ROLL $+30, R13
	ADDL R15, R11
	MOVL R12, R8
	ROLL $+5, R8
	LEAL 3395469782(R11)(R9*1), R11
	ADDL R8, R11

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 60(SP), R9
	MOVL R9, 252(R8)

	// ROUND4(64)
	// SHUFFLE
	MOVL (SP), R9
	XORL 52(SP), R9
	XORL 32(SP), R9
	XORL 8(SP), R9
	ROLL $+1, R9
	MOVL R9, (SP)

	// FUNC2
	MOVL R12, R15
	XORL R13, R15
	XORL R14, R15

	// MIX
	ROLL $+30, R12
	ADDL R15, R10
	MOVL R11, R8
	ROLL $+5, R8
	LEAL 3395469782(R10)(R9*1), R10
	ADDL R8, R10

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL (SP), R9
	MOVL R9, 256(R8)

	// Load cs
	MOVQ cs_base+56(FP), R8
	MOVL R10, 40(R8)
	MOVL R11, 44(R8)
	MOVL R12, 48(R8)
	MOVL R13, 52(R8)
	MOVL R14, 56(R8)

	// ROUND4(65)
	// SHUFFLE
	MOVL 4(SP), R9
	XORL 56(SP), R9
	XORL 36(SP), R9
	XORL 12(SP), R9
	ROLL $+1, R9
	MOVL R9, 4(SP)

	// FUNC2
	MOVL R11, R15
	XORL R12, R15
	XORL R13, R15

	// MIX
	ROLL $+30, R11
	ADDL R15, R14
	MOVL R10, R8
	ROLL $+5, R8
	LEAL 3395469782(R14)(R9*1), R14
	ADDL R8, R14

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 4(SP), R9
	MOVL R9, 260(R8)

	// ROUND4(66)
	// SHUFFLE
	MOVL 8(SP), R9
	XORL 60(SP), R9
	XORL 40(SP), R9
	XORL 16(SP), R9
	ROLL $+1, R9
	MOVL R9, 8(SP)

	// FUNC2
	MOVL R10, R15
	XORL R11, R15
	XORL R12, R15

	// MIX
	ROLL $+30, R10
	ADDL R15, R13
	MOVL R14, R8
	ROLL $+5, R8
	LEAL 3395469782(R13)(R9*1), R13
	ADDL R8, R13

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 8(SP), R9
	MOVL R9, 264(R8)

	// ROUND4(67)
	// SHUFFLE
	MOVL 12(SP), R9
	XORL (SP), R9
	XORL 44(SP), R9
	XORL 20(SP), R9
	ROLL $+1, R9
	MOVL R9, 12(SP)

	// FUNC2
	MOVL R14, R15
	XORL R10, R15
	XORL R11, R15

	// MIX
	ROLL $+30, R14
	ADDL R15, R12
	MOVL R13, R8
	ROLL $+5, R8
	LEAL 3395469782(R12)(R9*1), R12
	ADDL R8, R12

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 12(SP), R9
	MOVL R9, 268(R8)

	// ROUND4(68)
	// SHUFFLE
	MOVL 16(SP), R9
	XORL 4(SP), R9
	XORL 48(SP), R9
	XORL 24(SP), R9
	ROLL $+1, R9
	MOVL R9, 16(SP)

	// FUNC2
	MOVL R13, R15
	XORL R14, R15
	XORL R10, R15

	// MIX
	ROLL $+30, R13
	ADDL R15, R11
	MOVL R12, R8
	ROLL $+5, R8
	LEAL 3395469782(R11)(R9*1), R11
	ADDL R8, R11

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 16(SP), R9
	MOVL R9, 272(R8)

	// ROUND4(69)
	// SHUFFLE
	MOVL 20(SP), R9
	XORL 8(SP), R9
	XORL 52(SP), R9
	XORL 28(SP), R9
	ROLL $+1, R9
	MOVL R9, 20(SP)

	// FUNC2
	MOVL R12, R15
	XORL R13, R15
	XORL R14, R15

	// MIX
	ROLL $+30, R12
	ADDL R15, R10
	MOVL R11, R8
	ROLL $+5, R8
	LEAL 3395469782(R10)(R9*1), R10
	ADDL R8, R10

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 20(SP), R9
	MOVL R9, 276(R8)

	// ROUND4(70)
	// SHUFFLE
	MOVL 24(SP), R9
	XORL 12(SP), R9
	XORL 56(SP), R9
	XORL 32(SP), R9
	ROLL $+1, R9
	MOVL R9, 24(SP)

	// FUNC2
	MOVL R11, R15
	XORL R12, R15
	XORL R13, R15

	// MIX
	ROLL $+30, R11
	ADDL R15, R14
	MOVL R10, R8
	ROLL $+5, R8
	LEAL 3395469782(R14)(R9*1), R14
	ADDL R8, R14

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 24(SP), R9
	MOVL R9, 280(R8)

	// ROUND4(71)
	// SHUFFLE
	MOVL 28(SP), R9
	XORL 16(SP), R9
	XORL 60(SP), R9
	XORL 36(SP), R9
	ROLL $+1, R9
	MOVL R9, 28(SP)

	// FUNC2
	MOVL R10, R15
	XORL R11, R15
	XORL R12, R15

	// MIX
	ROLL $+30, R10
	ADDL R15, R13
	MOVL R14, R8
	ROLL $+5, R8
	LEAL 3395469782(R13)(R9*1), R13
	ADDL R8, R13

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 28(SP), R9
	MOVL R9, 284(R8)

	// ROUND4(72)
	// SHUFFLE
	MOVL 32(SP), R9
	XORL 20(SP), R9
	XORL (SP), R9
	XORL 40(SP), R9
	ROLL $+1, R9
	MOVL R9, 32(SP)

	// FUNC2
	MOVL R14, R15
	XORL R10, R15
	XORL R11, R15

	// MIX
	ROLL $+30, R14
	ADDL R15, R12
	MOVL R13, R8
	ROLL $+5, R8
	LEAL 3395469782(R12)(R9*1), R12
	ADDL R8, R12

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 32(SP), R9
	MOVL R9, 288(R8)

	// ROUND4(73)
	// SHUFFLE
	MOVL 36(SP), R9
	XORL 24(SP), R9
	XORL 4(SP), R9
	XORL 44(SP), R9
	ROLL $+1, R9
	MOVL R9, 36(SP)

	// FUNC2
	MOVL R13, R15
	XORL R14, R15
	XORL R10, R15

	// MIX
	ROLL $+30, R13
	ADDL R15, R11
	MOVL R12, R8
	ROLL $+5, R8
	LEAL 3395469782(R11)(R9*1), R11
	ADDL R8, R11

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 36(SP), R9
	MOVL R9, 292(R8)

	// ROUND4(74)
	// SHUFFLE
	MOVL 40(SP), R9
	XORL 28(SP), R9
	XORL 8(SP), R9
	XORL 48(SP), R9
	ROLL $+1, R9
	MOVL R9, 40(SP)

	// FUNC2
	MOVL R12, R15
	XORL R13, R15
	XORL R14, R15

	// MIX
	ROLL $+30, R12
	ADDL R15, R10
	MOVL R11, R8
	ROLL $+5, R8
	LEAL 3395469782(R10)(R9*1), R10
	ADDL R8, R10

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 40(SP), R9
	MOVL R9, 296(R8)

	// ROUND4(75)
	// SHUFFLE
	MOVL 44(SP), R9
	XORL 32(SP), R9
	XORL 12(SP), R9
	XORL 52(SP), R9
	ROLL $+1, R9
	MOVL R9, 44(SP)

	// FUNC2
	MOVL R11, R15
	XORL R12, R15
	XORL R13, R15

	// MIX
	ROLL $+30, R11
	ADDL R15, R14
	MOVL R10, R8
	ROLL $+5, R8
	LEAL 3395469782(R14)(R9*1), R14
	ADDL R8, R14

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 44(SP), R9
	MOVL R9, 300(R8)

	// ROUND4(76)
	// SHUFFLE
	MOVL 48(SP), R9
	XORL 36(SP), R9
	XORL 16(SP), R9
	XORL 56(SP), R9
	ROLL $+1, R9
	MOVL R9, 48(SP)

	// FUNC2
	MOVL R10, R15
	XORL R11, R15
	XORL R12, R15

	// MIX
	ROLL $+30, R10
	ADDL R15, R13
	MOVL R14, R8
	ROLL $+5, R8
	LEAL 3395469782(R13)(R9*1), R13
	ADDL R8, R13

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 48(SP), R9
	MOVL R9, 304(R8)

	// ROUND4(77)
	// SHUFFLE
	MOVL 52(SP), R9
	XORL 40(SP), R9
	XORL 20(SP), R9
	XORL 60(SP), R9
	ROLL $+1, R9
	MOVL R9, 52(SP)

	// FUNC2
	MOVL R14, R15
	XORL R10, R15
	XORL R11, R15

	// MIX
	ROLL $+30, R14
	ADDL R15, R12
	MOVL R13, R8
	ROLL $+5, R8
	LEAL 3395469782(R12)(R9*1), R12
	ADDL R8, R12

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 52(SP), R9
	MOVL R9, 308(R8)

	// ROUND4(78)
	// SHUFFLE
	MOVL 56(SP), R9
	XORL 44(SP), R9
	XORL 24(SP), R9
	XORL (SP), R9
	ROLL $+1, R9
	MOVL R9, 56(SP)

	// FUNC2
	MOVL R13, R15
	XORL R14, R15
	XORL R10, R15

	// MIX
	ROLL $+30, R13
	ADDL R15, R11
	MOVL R12, R8
	ROLL $+5, R8
	LEAL 3395469782(R11)(R9*1), R11
	ADDL R8, R11

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 56(SP), R9
	MOVL R9, 312(R8)

	// ROUND4(79)
	// SHUFFLE
	MOVL 60(SP), R9
	XORL 48(SP), R9
	XORL 28(SP), R9
	XORL 4(SP), R9
	ROLL $+1, R9
	MOVL R9, 60(SP)

	// FUNC2
	MOVL R12, R15
	XORL R13, R15
	XORL R14, R15

	// MIX
	ROLL $+30, R12
	ADDL R15, R10
	MOVL R11, R8
	ROLL $+5, R8
	LEAL 3395469782(R10)(R9*1), R10
	ADDL R8, R10

	// Load m1
	MOVQ m1_base+32(FP), R8
	MOVL 60(SP), R9
	MOVL R9, 316(R8)

	// Add registers to temp hash.
	ADDL R10, AX
	ADDL R11, BX
	ADDL R12, CX
	ADDL R13, DX
	ADDL R14, BP
	ADDQ $+64, DI
	CMPQ DI, SI
	JB   loop

end:
	MOVQ dig+0(FP), SI
	MOVL AX, (SI)
	MOVL BX, 4(SI)
	MOVL CX, 8(SI)
	MOVL DX, 12(SI)
	MOVL BP, 16(SI)
	RET
