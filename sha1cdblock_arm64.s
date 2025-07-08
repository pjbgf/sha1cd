//go:build !noasm && gc && arm64 && !amd64

#include "textflag.h"

#define RoundConst0 $1518500249 // 0x5A827999
#define RoundConst1 $1859775393 // 0x6ED9EBA1
#define RoundConst2 $2400959708 // 0x8F1BBCDC
#define RoundConst3 $3395469782 // 0xCA62C1D6

// FUNC1 f = (b & c) | ((~b) & d)
#define FUNC1(b, c, d) \
	MOVW d, R15; \
	EORW c, R15; \
	ANDW b, R15; \
	EORW d, R15

// FUNC2 f = b ^ c ^ d
#define FUNC2(b, c, d) \
	MOVW b, R15; \
	EORW c, R15; \
	EORW d, R15

// FUNC3 f = (b & c) | (b & d) | (c & d)
#define FUNC3(b, c, d) \
	MOVW b, R8; \
	ORR c, R8, R8; \
	ANDW d, R8, R8; \
	MOVW b, R15; \
	ANDW c, R15, R15; \
	ORR R8, R15, R15

#define FUNC4(b, c, d) FUNC2(b, c, d)
	
#define MIX(a, b, c, d, e, k, vreg) \
	RORW $2, b, b; \
	ADDW R15, e, e; \
	MOVW a, R8; \
	RORW $27, R8, R8; \
	MOVW k, R19; \
	ADDW R19, e, e; \
	ADDW R9, e, e; \
	ADDW R8, e, e

#define LOAD(index) \
	MOVWU (index*4)(R16), R9; \
	REVW R9, R9; \
	MOVW R9, (index*4)(RSP)

#define LOADCS(a, b, c, d, e, index) \
	MOVD cs_base+56(FP), R8; \
	MOVW a, ((index*20))(R8); \
	MOVW b, ((index*20)+4)(R8); \
	MOVW c, ((index*20)+8)(R8); \
	MOVW d, ((index*20)+12)(R8); \
	MOVW e, ((index*20)+16)(R8)

#define SHUFFLE(index) \
	MOVW ((index&0xf)*4)(RSP), R9; \
	MOVW (((index-3)&0xf)*4)(RSP), R20; \
	EORW R20, R9; \
	MOVW (((index-8)&0xf)*4)(RSP), R20; \
	EORW R20, R9; \
	MOVW (((index-14)&0xf)*4)(RSP), R20; \
	EORW R20, R9; \
	RORW $31, R9, R9; \
	MOVW R9, ((index&0xf)*4)(RSP)

// LOADM1 stores message word to m1 array.
#define LOADM1(index) \
	MOVD m1_base+32(FP), R8; \
	MOVW ((index&0xf)*4)(RSP), R9; \
	MOVW R9, (index*4)(R8)

#define ROUND1(a, b, c, d, e, index, vreg) \
	LOAD(index); \
	FUNC1(b, c, d); \
	MIX(a, b, c, d, e, RoundConst0, vreg); \
	LOADM1(index)

#define ROUND1x(a, b, c, d, e, index, vreg) \
	SHUFFLE(index); \
	FUNC1(b, c, d); \
	MIX(a, b, c, d, e, RoundConst0, vreg); \
	LOADM1(index)

#define ROUND2(a, b, c, d, e, index, vreg) \
	SHUFFLE(index); \
	FUNC2(b, c, d); \
	MIX(a, b, c, d, e, RoundConst1, vreg); \
	LOADM1(index)

#define ROUND3(a, b, c, d, e, index, vreg) \
	SHUFFLE(index); \
	FUNC3(b, c, d); \
	MIX(a, b, c, d, e, RoundConst2, vreg); \
	LOADM1(index)

#define ROUND4(a, b, c, d, e, index, vreg) \
	SHUFFLE(index); \
	FUNC4(b, c, d); \
	MIX(a, b, c, d, e, RoundConst3, vreg); \
	LOADM1(index)

// func blockARM64(dig *digest, p []byte, m1 []uint32, cs [][5]uint32)
TEXT ·blockARM64(SB), NOSPLIT, $64-80
    MOVD    dig+0(FP), R8
    MOVD    p_base+8(FP), R16
    MOVD    p_len+16(FP), R10

    LSR     $6, R10, R10
    LSL     $6, R10, R10
    ADD     R16, R10, R21

    // Load h0-h4 into R1–R5.
    MOVW    (R8), R1                   // R1 = h0
    MOVW    4(R8), R2                  // R2 = h1
    MOVW    8(R8), R3                  // R3 = h2
    MOVW    12(R8), R4                 // R4 = h3
    MOVW    16(R8), R5                 // R5 = h4

loop:
    // len(p) >= chunk
    CMP     R16, R21
    BLS     end

	// Initialize registers a, b, c, d, e.
	MOVW R1, R10
	MOVW R2, R11
	MOVW R3, R12
	MOVW R4, R13
	MOVW R5, R14

	// ROUND1 (steps 0-15)
	LOADCS(R10, R11, R12, R13, R14, 0)
	ROUND1(R10, R11, R12, R13, R14, 0, V31)	
	ROUND1(R14, R10, R11, R12, R13, 1, V30)
	ROUND1(R13, R14, R10, R11, R12, 2, V29)
	ROUND1(R12, R13, R14, R10, R11, 3, V28)
	ROUND1(R11, R12, R13, R14, R10, 4, V27)
	ROUND1(R10, R11, R12, R13, R14, 5, V26)
	ROUND1(R14, R10, R11, R12, R13, 6, V25)
	ROUND1(R13, R14, R10, R11, R12, 7, V24)
	ROUND1(R12, R13, R14, R10, R11, 8, V23)
	ROUND1(R11, R12, R13, R14, R10, 9, V22)
	ROUND1(R10, R11, R12, R13, R14, 10, V21)
	ROUND1(R14, R10, R11, R12, R13, 11, V20)
	ROUND1(R13, R14, R10, R11, R12, 12, V19)
	ROUND1(R12, R13, R14, R10, R11, 13, V18)
	ROUND1(R11, R12, R13, R14, R10, 14, V17)
	ROUND1(R10, R11, R12, R13, R14, 15, V16)

	// ROUND1x (steps 16-19) - same as ROUND1 but with no data load.
	ROUND1x(R14, R10, R11, R12, R13, 16, V15)
	ROUND1x(R13, R14, R10, R11, R12, 17, V14)
	ROUND1x(R12, R13, R14, R10, R11, 18, V13)
	ROUND1x(R11, R12, R13, R14, R10, 19, V12)

	// ROUND2 (steps 20-39)
	ROUND2(R10, R11, R12, R13, R14, 20, V11)
	ROUND2(R14, R10, R11, R12, R13, 21, V10)
	ROUND2(R13, R14, R10, R11, R12, 22, V9)
	ROUND2(R12, R13, R14, R10, R11, 23, V8)
	ROUND2(R11, R12, R13, R14, R10, 24, V7)
	ROUND2(R10, R11, R12, R13, R14, 25, V6)
	ROUND2(R14, R10, R11, R12, R13, 26, V5)
	ROUND2(R13, R14, R10, R11, R12, 27, V4)
	ROUND2(R12, R13, R14, R10, R11, 28, V3)
	ROUND2(R11, R12, R13, R14, R10, 29, V2)
	ROUND2(R10, R11, R12, R13, R14, 30, V1)
	ROUND2(R14, R10, R11, R12, R13, 31, V0)
	ROUND2(R13, R14, R10, R11, R12, 32, V31)
	ROUND2(R12, R13, R14, R10, R11, 33, V30)
	ROUND2(R11, R12, R13, R14, R10, 34, V29)
	ROUND2(R10, R11, R12, R13, R14, 35, V28)
	ROUND2(R14, R10, R11, R12, R13, 36, V27)
	ROUND2(R13, R14, R10, R11, R12, 37, V26)
	ROUND2(R12, R13, R14, R10, R11, 38, V25)
	ROUND2(R11, R12, R13, R14, R10, 39, V24)

	// ROUND3 (steps 40-59)
	ROUND3(R10, R11, R12, R13, R14, 40, V23)
	ROUND3(R14, R10, R11, R12, R13, 41, V22)
	ROUND3(R13, R14, R10, R11, R12, 42, V21)
	ROUND3(R12, R13, R14, R10, R11, 43, V20)
	ROUND3(R11, R12, R13, R14, R10, 44, V19)
	ROUND3(R10, R11, R12, R13, R14, 45, V18)
	ROUND3(R14, R10, R11, R12, R13, 46, V17)
	ROUND3(R13, R14, R10, R11, R12, 47, V16)
	ROUND3(R12, R13, R14, R10, R11, 48, V15)
	ROUND3(R11, R12, R13, R14, R10, 49, V14)
	ROUND3(R10, R11, R12, R13, R14, 50, V13)
	ROUND3(R14, R10, R11, R12, R13, 51, V12)
	ROUND3(R13, R14, R10, R11, R12, 52, V11)
	ROUND3(R12, R13, R14, R10, R11, 53, V10)
	ROUND3(R11, R12, R13, R14, R10, 54, V9)
	ROUND3(R10, R11, R12, R13, R14, 55, V8)
	ROUND3(R14, R10, R11, R12, R13, 56, V7)
	ROUND3(R13, R14, R10, R11, R12, 57, V6)

	LOADCS(R12, R13, R14, R10, R11, 1)
	ROUND3(R12, R13, R14, R10, R11, 58, V5)
	ROUND3(R11, R12, R13, R14, R10, 59, V4)

	// ROUND4 (steps 60-79)
	ROUND4(R10, R11, R12, R13, R14, 60, V3)
	ROUND4(R14, R10, R11, R12, R13, 61, V2)
	ROUND4(R13, R14, R10, R11, R12, 62, V1)
	ROUND4(R12, R13, R14, R10, R11, 63, V0)
	ROUND4(R11, R12, R13, R14, R10, 64, V31)

	LOADCS(R10, R11, R12, R13, R14, 2)
	ROUND4(R10, R11, R12, R13, R14, 65, V30)
	ROUND4(R14, R10, R11, R12, R13, 66, V29)
	ROUND4(R13, R14, R10, R11, R12, 67, V28)
	ROUND4(R12, R13, R14, R10, R11, 68, V27)
	ROUND4(R11, R12, R13, R14, R10, 69, V26)
	ROUND4(R10, R11, R12, R13, R14, 70, V25)
	ROUND4(R14, R10, R11, R12, R13, 71, V24)
	ROUND4(R13, R14, R10, R11, R12, 72, V23)
	ROUND4(R12, R13, R14, R10, R11, 73, V22)
	ROUND4(R11, R12, R13, R14, R10, 74, V21)
	ROUND4(R10, R11, R12, R13, R14, 75, V20)
	ROUND4(R14, R10, R11, R12, R13, 76, V19)
	ROUND4(R13, R14, R10, R11, R12, 77, V18)
	ROUND4(R12, R13, R14, R10, R11, 78, V17)
	ROUND4(R11, R12, R13, R14, R10, 79, V16)

	// Add registers to temp hash.
	ADDW R10, R1, R1
	ADDW R11, R2, R2
	ADDW R12, R3, R3
	ADDW R13, R4, R4
	ADDW R14, R5, R5

	ADD  $64, R16, R16
	B  loop

end:
	MOVD dig+0(FP), R8
	MOVW R1, (R8)
	MOVW R2, 4(R8)
	MOVW R3, 8(R8)
	MOVW R4, 12(R8)
	MOVW R5, 16(R8)
	RET
