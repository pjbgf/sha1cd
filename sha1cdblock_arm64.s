//go:build !noasm && gc && arm64 && !amd64

#include "textflag.h"
#include "funcdata.h"

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
	MOVW b, R27; \
	ORRW c, R27; \
	ANDW d, R27; \
	MOVW b, R15; \
	ANDW c, R15; \
	ORRW R27, R15

#define FUNC4(b, c, d) FUNC2(b, c, d)
	
// bits.RotateLeft32(a, 5) + f + e + w[i&0xf] + K
// c = bits.RotateLeft32(b, 30)
#define MIX(a, b, c, d, e, k, index) \
	RORW $2, b, b; \
	ADDW R15, e, e; \
	MOVW a, R27; \
	RORW $27, R27, R27; \
	MOVW k, R19; \
	ADDW R19, e, e; \
	MOVW (460+(((index)&0xf)*4))(RSP), R20; \
	ADDW R20, e, e; \
	ADDW R27, e, e

#define LOAD(index) \
	MOVWU (index*4)(R16), R9; \
	REVW R9, R9; \
	MOVW R9, (460+(((index)&0xf)*4))(RSP)

#define LOADCS(a, b, c, d, e, index) \
	ADD $328, RSP, R27; \
	MOVW a, ((index*20))(R27); \
	MOVW b, ((index*20)+4)(R27); \
	MOVW c, ((index*20)+8)(R27); \
	MOVW d, ((index*20)+12)(R27); \
	MOVW e, ((index*20)+16)(R27)

#define SHUFFLE(index) \
	MOVW (460+(((index)&0xf)*4))(RSP), R9; \
	MOVW (460+(((index-3)&0xf)*4))(RSP), R20; \
	EORW R20, R9, R9; \
	MOVW (460+(((index-8)&0xf)*4))(RSP), R20; \
	EORW R20, R9, R9; \
	MOVW (460+(((index-14)&0xf)*4))(RSP), R20; \
	EORW R20, R9, R9; \
	RORW $31, R9, R9; \
	MOVW R9, (460+(((index)&0xf)*4))(RSP)

// LOADM1 stores message word to m1 array.
#define LOADM1(index) \
	MOVW (460+(((index)&0xf)*4))(RSP), R9; \
	MOVW R9, (((index)*4)+8)(RSP)

#define ROUND1(a, b, c, d, e, index) \
	LOAD(index); \
	FUNC1(b, c, d); \
	MIX(a, b, c, d, e, RoundConst0, index); \
	LOADM1(index)

#define ROUND1x(a, b, c, d, e, index) \
	SHUFFLE(index); \
	FUNC1(b, c, d); \
	MIX(a, b, c, d, e, RoundConst0, index); \
	LOADM1(index)

#define ROUND2(a, b, c, d, e, index) \
	SHUFFLE(index); \
	FUNC2(b, c, d); \
	MIX(a, b, c, d, e, RoundConst1, index); \
	LOADM1(index)

#define ROUND3(a, b, c, d, e, index) \
	SHUFFLE(index); \
	FUNC3(b, c, d); \
	MIX(a, b, c, d, e, RoundConst2, index); \
	LOADM1(index)

#define ROUND4(a, b, c, d, e, index) \
	SHUFFLE(index); \
	FUNC4(b, c, d); \
	MIX(a, b, c, d, e, RoundConst3, index); \
	LOADM1(index)

#define SPILL_REGS(start) \
	MOVD R16, start+0(RSP); \
	MOVD R1,  start+8(RSP); \
	MOVD R2,  start+16(RSP); \
	MOVD R3,  start+24(RSP); \
	MOVD R4,  start+32(RSP); \
	MOVD R5,  start+40(RSP)

#define UNSPILL_REGS(start) \
	MOVD start+0(RSP), R16; \
	MOVD start+8(RSP), R1; \
	MOVD start+16(RSP), R2; \
	MOVD start+24(RSP), R3; \
	MOVD start+32(RSP), R4; \
	MOVD start+40(RSP), R5

// blockARM64 Stack Frame Layout
// =====================================
//
// Function Arguments (checkCollision parameters):
// ┌───────────────────────────────────────────────────────────────┐
// │ Offset  │ Size │ Type        │ Description                    │
// ├─────────┼──────┼─────────────┼────────────────────────────────┤
// │ 8-327   │ 320B │ [80]uint32  │ m1 - message buffer 1          │
// │ 328-387 │  60B │ [3][5]uint32│ cs - chaining state array      │
// │ 388-407 │  20B │ [5]uint32   │ h - hash state values          │
// │ 408-423 │  16B │ (padding)   │ alignment/reserved space       │
// └─────────┴──────┴─────────────┴────────────────────────────────┘
//
// Local Variables:
// ┌───────────────────────────────────────────────────────────────┐
// │ Offset  │ Size │ Type        │ Description                    │
// ├─────────┼──────┼─────────────┼────────────────────────────────┤
// │ 424-431 │  8B  │ *uint32     │ ptr - chunk end pointer        │
// │ 432-439 │  8B  │ int64       │ loop - iteration counter       │
// │ 440-443 │  4B  │ uint32      │ col - collision detection flag │
// │ 444-447 │  4B  │ uint32      │ hi - hash iteration counter    │
// │ 448-455 │  8B  │ (padding)   │ alignment for ephemeral data   │
// └─────────┴──────┴─────────────┴────────────────────────────────┘
//
// Ephemeral/Temporary Data:
// ┌───────────────────────────────────────────────────────────────┐
// │ Offset  │ Size │ Type        │ Description                    │
// ├─────────┼──────┼─────────────┼────────────────────────────────┤
// │ 456-459 │  4B  │ uint32      │ temp_col - temporary collision │
// │ 460-523 │ 64B  │ [16]uint32  │ w - sliding window (msg words) │
// │ 524-571 │ 48B  │ spill slots │ register spill area            │
// └─────────┴──────┴─────────────┴────────────────────────────────┘
//
// func blockARM64(h []uint32, p []byte) bool
TEXT ·blockARM64(SB), 0, $584-49
	NO_LOCAL_POINTERS

start:
	MOVD h_base+0(FP), R8
	MOVD p_base+24(FP), R16
	MOVD p_len+32(FP), R10
	
	// Calculate end pointer for complete chunks only.
	LSR $6, R10, R10
	LSL $6, R10, R10
	ADD R16, R10, R21
	MOVD R21, 424(RSP)
	
	// Load h0-h4 into R1-R5.
	MOVW (R8), R1
	MOVW 4(R8), R2
	MOVW 8(R8), R3
	MOVW 12(R8), R4
	MOVW 16(R8), R5

	// Initialise collision flag values.
	MOVB $0, 440(RSP)      // collision flag
	MOVB $0, ret+48(FP)    // return value

loop:
	MOVD R16, 432(RSP)
	MOVD 424(RSP), R21
	CMP R16, R21
	BLS end

	// Initialize hash iteration counter (0-based)
	MOVW $0, 444(RSP)

rehash:
	// Initialize working registers a, b, c, d, e.
	MOVW R1, R10
	MOVW R2, R11
	MOVW R3, R12
	MOVW R4, R13
	MOVW R5, R14

	// ROUND1 (steps 0-15)
	LOADCS(R10, R11, R12, R13, R14, 0)
	ROUND1(R10, R11, R12, R13, R14, 0)
	ROUND1(R14, R10, R11, R12, R13, 1)
	ROUND1(R13, R14, R10, R11, R12, 2)
	ROUND1(R12, R13, R14, R10, R11, 3)
	ROUND1(R11, R12, R13, R14, R10, 4)
	ROUND1(R10, R11, R12, R13, R14, 5)
	ROUND1(R14, R10, R11, R12, R13, 6)
	ROUND1(R13, R14, R10, R11, R12, 7)
	ROUND1(R12, R13, R14, R10, R11, 8)
	ROUND1(R11, R12, R13, R14, R10, 9)
	ROUND1(R10, R11, R12, R13, R14, 10)
	ROUND1(R14, R10, R11, R12, R13, 11)
	ROUND1(R13, R14, R10, R11, R12, 12)
	ROUND1(R12, R13, R14, R10, R11, 13)
	ROUND1(R11, R12, R13, R14, R10, 14)
	ROUND1(R10, R11, R12, R13, R14, 15)

	// ROUND1x (steps 16-19)
	ROUND1x(R14, R10, R11, R12, R13, 16)
	ROUND1x(R13, R14, R10, R11, R12, 17)
	ROUND1x(R12, R13, R14, R10, R11, 18)
	ROUND1x(R11, R12, R13, R14, R10, 19)

	// ROUND2 (steps 20-39)
	ROUND2(R10, R11, R12, R13, R14, 20)
	ROUND2(R14, R10, R11, R12, R13, 21)
	ROUND2(R13, R14, R10, R11, R12, 22)
	ROUND2(R12, R13, R14, R10, R11, 23)
	ROUND2(R11, R12, R13, R14, R10, 24)
	ROUND2(R10, R11, R12, R13, R14, 25)
	ROUND2(R14, R10, R11, R12, R13, 26)
	ROUND2(R13, R14, R10, R11, R12, 27)
	ROUND2(R12, R13, R14, R10, R11, 28)
	ROUND2(R11, R12, R13, R14, R10, 29)
	ROUND2(R10, R11, R12, R13, R14, 30)
	ROUND2(R14, R10, R11, R12, R13, 31)
	ROUND2(R13, R14, R10, R11, R12, 32)
	ROUND2(R12, R13, R14, R10, R11, 33)
	ROUND2(R11, R12, R13, R14, R10, 34)
	ROUND2(R10, R11, R12, R13, R14, 35)
	ROUND2(R14, R10, R11, R12, R13, 36)
	ROUND2(R13, R14, R10, R11, R12, 37)
	ROUND2(R12, R13, R14, R10, R11, 38)
	ROUND2(R11, R12, R13, R14, R10, 39)

	// ROUND3 (steps 40-59)
	ROUND3(R10, R11, R12, R13, R14, 40)
	ROUND3(R14, R10, R11, R12, R13, 41)
	ROUND3(R13, R14, R10, R11, R12, 42)
	ROUND3(R12, R13, R14, R10, R11, 43)
	ROUND3(R11, R12, R13, R14, R10, 44)
	ROUND3(R10, R11, R12, R13, R14, 45)
	ROUND3(R14, R10, R11, R12, R13, 46)
	ROUND3(R13, R14, R10, R11, R12, 47)
	ROUND3(R12, R13, R14, R10, R11, 48)
	ROUND3(R11, R12, R13, R14, R10, 49)
	ROUND3(R10, R11, R12, R13, R14, 50)
	ROUND3(R14, R10, R11, R12, R13, 51)
	ROUND3(R13, R14, R10, R11, R12, 52)
	ROUND3(R12, R13, R14, R10, R11, 53)
	ROUND3(R11, R12, R13, R14, R10, 54)
	ROUND3(R10, R11, R12, R13, R14, 55)
	ROUND3(R14, R10, R11, R12, R13, 56)
	ROUND3(R13, R14, R10, R11, R12, 57)

	LOADCS(R12, R13, R14, R10, R11, 1)
	ROUND3(R12, R13, R14, R10, R11, 58)
	ROUND3(R11, R12, R13, R14, R10, 59)

	// ROUND4 (steps 60-79)
	ROUND4(R10, R11, R12, R13, R14, 60)
	ROUND4(R14, R10, R11, R12, R13, 61)
	ROUND4(R13, R14, R10, R11, R12, 62)
	ROUND4(R12, R13, R14, R10, R11, 63)
	ROUND4(R11, R12, R13, R14, R10, 64)

	LOADCS(R10, R11, R12, R13, R14, 2)
	ROUND4(R10, R11, R12, R13, R14, 65)
	ROUND4(R14, R10, R11, R12, R13, 66)
	ROUND4(R13, R14, R10, R11, R12, 67)
	ROUND4(R12, R13, R14, R10, R11, 68)
	ROUND4(R11, R12, R13, R14, R10, 69)
	ROUND4(R10, R11, R12, R13, R14, 70)
	ROUND4(R14, R10, R11, R12, R13, 71)
	ROUND4(R13, R14, R10, R11, R12, 72)
	ROUND4(R12, R13, R14, R10, R11, 73)
	ROUND4(R11, R12, R13, R14, R10, 74)
	ROUND4(R10, R11, R12, R13, R14, 75)
	ROUND4(R14, R10, R11, R12, R13, 76)
	ROUND4(R13, R14, R10, R11, R12, 77)
	ROUND4(R12, R13, R14, R10, R11, 78)
	ROUND4(R11, R12, R13, R14, R10, 79)

	// Add working registers to hash state.
	ADDW R10, R1, R1
	ADDW R11, R2, R2
	ADDW R12, R3, R3
	ADDW R13, R4, R4
	ADDW R14, R5, R5

	// Increment hash iteration counter.
	MOVW 444(RSP), R10
	ADD $1, R10, R10
	MOVW R10, 444(RSP)

	// block hashed twice, another one to go.
	CMP $2, R10
	BEQ rehash

	CMP $3, R10
	BEQ next_chunk

	// h argument: copy from current hash state.
	MOVW R1, 388(RSP)
	MOVW R2, 392(RSP)
	MOVW R3, 396(RSP)
	MOVW R4, 400(RSP)
	MOVW R5, 404(RSP)
	
	SPILL_REGS(460)

	// Check stack layout comment for parameters.
	CALL ·checkCollision(SB)
	MOVB R0, 456(RSP) // save return pre-unspill.
	
	UNSPILL_REGS(460)

	MOVB 456(RSP), R0

	// If no collision found, move on to the next chunk.
	CMP $1, R0
	BNE next_chunk

store_rehash:
	// If a collision was found for a block, ensure that
	// the collision flag is permanently true for all
	// chunks.
	MOVB R0, 440(RSP)

	B rehash

next_chunk:
	MOVD 432(RSP), R16
	ADD $64, R16, R16
	B loop

end:
	// Update h with final hash values.
	MOVD h_base+0(FP), R8
	MOVW R1, (R8)
	MOVW R2, 4(R8)
	MOVW R3, 8(R8)
	MOVW R4, 12(R8)
	MOVW R5, 16(R8)

	MOVB 440(RSP), R0
	MOVB R0, ret+48(FP)
	
	RET
