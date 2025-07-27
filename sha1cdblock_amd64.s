//go:build !noasm && gc && amd64 && !arm64

#include "textflag.h"
#include "funcdata.h"

#define RoundConst0 $1518500249 // 0x5A827999
#define RoundConst1 $1859775393 // 0x6ED9EBA1
#define RoundConst2 $2400959708 // 0x8F1BBCDC
#define RoundConst3 $3395469782 // 0xCA62C1D6

// FUNC1 f = (b & c) | ((~b) & d)
#define FUNC1(b, c, d) \
	MOVL d, R15; \
	XORL c, R15; \
	ANDL b, R15; \
	XORL d, R15

// FUNC2 f = b ^ c ^ d
#define FUNC2(b, c, d) \
	MOVL b, R15; \
	XORL c, R15; \
	XORL d, R15

// FUNC3 f = (b & c) | (b & d) | (c & d)
#define FUNC3(b, c, d) \
	MOVL b, R15; \
	ORL c, R15; \
	ANDL d, R15; \
	MOVL b, R14; \
	ANDL c, R14; \
	ORL R14, R15

#define FUNC4(b, c, d) FUNC2(b, c, d)

// bits.RotateLeft32(a, 5) + f + e + w[i&0xf] + K
// c = bits.RotateLeft32(b, 30)
#define MIX(a, b, c, d, e, k, index) \
	RORL $2, b; \
	ADDL R15, e; \
	MOVL a, R14; \
	RORL $27, R14; \
	ADDL k, e; \
	ADDL (460+(((index)&0xf)*4))(SP), e; \
	ADDL R14, e;

#define LOAD(index) \
	MOVL (index*4)(SI), DI; \
	BSWAPL DI; \
	MOVL DI, (460+(((index)&0xf)*4))(SP);

#define LOADCS(a, b, c, d, e, index) \
	LEAQ 320(SP), R15; \
	MOVL a, ((index*20))(R15); \
	MOVL b, ((index*20)+4)(R15); \
	MOVL c, ((index*20)+8)(R15); \
	MOVL d, ((index*20)+12)(R15); \
	MOVL e, ((index*20)+16)(R15);

// LOADM1 stores message word to m1 array.
#define LOADM1(index) \
	MOVL (460+(((index)&0xf)*4))(SP), DI; \
	MOVL DI, ((index)*4)(SP);

#define SHUFFLE(index) \
	MOVL (460+(((index)&0xf)*4))(SP), DI; \
	MOVL (460+(((index-3)&0xf)*4))(SP), R14; \
	XORL R14, DI; \
	MOVL (460+(((index-8)&0xf)*4))(SP), R14; \
	XORL R14, DI; \
	MOVL (460+(((index-14)&0xf)*4))(SP), R14; \
	XORL R14, DI; \
	RORL $31, DI; \
	MOVL DI, (460+(((index)&0xf)*4))(SP);

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
    MOVQ SI,  start+0(SP); \
    MOVQ R9,  start+8(SP); \
    MOVQ R10, start+16(SP); \
    MOVQ R11, start+24(SP); \
    MOVQ R12, start+32(SP); \
    MOVQ R13, start+40(SP);

#define UNSPILL_REGS(start) \
    MOVQ start+0(SP), SI; \
    MOVQ start+8(SP), R9; \
    MOVQ start+16(SP), R10; \
    MOVQ start+24(SP), R11; \
    MOVQ start+32(SP), R12; \
    MOVQ start+40(SP), R13;

// blockAMD64 Stack Frame Layout
// =====================================
//
// Function Arguments (checkCollision parameters):
// ┌───────────────────────────────────────────────────────────────┐
// │ Offset  │ Size │ Type        │ Description                    │
// ├─────────┼──────┼─────────────┼────────────────────────────────┤
// │ 0-319   │ 320B │ [80]uint32  │ m1 - message buffer 1          │
// │ 320-379 │  60B │ [3][5]uint32│ cs - chaining state array      │
// │ 380-399 │  20B │ [5]uint32   │ h - hash state values          │
// │ 400-423 │  24B │ (padding)   │ alignment/reserved space       │
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
// func blockAMD64(h []uint32, p []byte) bool
TEXT ·blockAMD64(SB), 0, $584-49
	NO_LOCAL_POINTERS

start:
	MOVQ h_base+0(FP), R8
	MOVQ p_base+24(FP), SI
	MOVQ p_len+32(FP), DX
	
	// Calculate end pointer for complete chunks only.
	SHRQ $6, DX
	SHLQ $6, DX
	ADDQ SI, DX
	MOVQ DX, 424(SP)
	
	// Load h0-h4 into R9-R13.
	MOVL (R8), R9
	MOVL 4(R8), R10
	MOVL 8(R8), R11
	MOVL 12(R8), R12
	MOVL 16(R8), R13

	// Initialise collision flag values.
	MOVB $0, 440(SP)      // collision flag
	MOVB $0, ret+48(FP)   // return value

loop:
	MOVQ SI, 432(SP)
	CMPQ SI, 424(SP)
	JNB end

	// Initialize hash iteration counter (0-based)
	MOVL $0, 444(SP)

rehash:
	// Initialize working registers a, b, c, d, e.
	MOVL R9, AX
	MOVL R10, BX
	MOVL R11, CX
	MOVL R12, DX
	MOVL R13, BP

	// ROUND1 (steps 0-15)
	LOADCS(AX, BX, CX, DX, BP, 0)
	ROUND1(AX, BX, CX, DX, BP, 0)
	ROUND1(BP, AX, BX, CX, DX, 1)
	ROUND1(DX, BP, AX, BX, CX, 2)
	ROUND1(CX, DX, BP, AX, BX, 3)
	ROUND1(BX, CX, DX, BP, AX, 4)
	ROUND1(AX, BX, CX, DX, BP, 5)
	ROUND1(BP, AX, BX, CX, DX, 6)
	ROUND1(DX, BP, AX, BX, CX, 7)
	ROUND1(CX, DX, BP, AX, BX, 8)
	ROUND1(BX, CX, DX, BP, AX, 9)
	ROUND1(AX, BX, CX, DX, BP, 10)
	ROUND1(BP, AX, BX, CX, DX, 11)
	ROUND1(DX, BP, AX, BX, CX, 12)
	ROUND1(CX, DX, BP, AX, BX, 13)
	ROUND1(BX, CX, DX, BP, AX, 14)
	ROUND1(AX, BX, CX, DX, BP, 15)

	// ROUND1x (steps 16-19)
	ROUND1x(BP, AX, BX, CX, DX, 16)
	ROUND1x(DX, BP, AX, BX, CX, 17)
	ROUND1x(CX, DX, BP, AX, BX, 18)
	ROUND1x(BX, CX, DX, BP, AX, 19)

	// ROUND2 (steps 20-39)
	ROUND2(AX, BX, CX, DX, BP, 20)
	ROUND2(BP, AX, BX, CX, DX, 21)
	ROUND2(DX, BP, AX, BX, CX, 22)
	ROUND2(CX, DX, BP, AX, BX, 23)
	ROUND2(BX, CX, DX, BP, AX, 24)
	ROUND2(AX, BX, CX, DX, BP, 25)
	ROUND2(BP, AX, BX, CX, DX, 26)
	ROUND2(DX, BP, AX, BX, CX, 27)
	ROUND2(CX, DX, BP, AX, BX, 28)
	ROUND2(BX, CX, DX, BP, AX, 29)
	ROUND2(AX, BX, CX, DX, BP, 30)
	ROUND2(BP, AX, BX, CX, DX, 31)
	ROUND2(DX, BP, AX, BX, CX, 32)
	ROUND2(CX, DX, BP, AX, BX, 33)
	ROUND2(BX, CX, DX, BP, AX, 34)
	ROUND2(AX, BX, CX, DX, BP, 35)
	ROUND2(BP, AX, BX, CX, DX, 36)
	ROUND2(DX, BP, AX, BX, CX, 37)
	ROUND2(CX, DX, BP, AX, BX, 38)
	ROUND2(BX, CX, DX, BP, AX, 39)

	// ROUND3 (steps 40-59)
	ROUND3(AX, BX, CX, DX, BP, 40)
	ROUND3(BP, AX, BX, CX, DX, 41)
	ROUND3(DX, BP, AX, BX, CX, 42)
	ROUND3(CX, DX, BP, AX, BX, 43)
	ROUND3(BX, CX, DX, BP, AX, 44)
	ROUND3(AX, BX, CX, DX, BP, 45)
	ROUND3(BP, AX, BX, CX, DX, 46)
	ROUND3(DX, BP, AX, BX, CX, 47)
	ROUND3(CX, DX, BP, AX, BX, 48)
	ROUND3(BX, CX, DX, BP, AX, 49)
	ROUND3(AX, BX, CX, DX, BP, 50)
	ROUND3(BP, AX, BX, CX, DX, 51)
	ROUND3(DX, BP, AX, BX, CX, 52)
	ROUND3(CX, DX, BP, AX, BX, 53)
	ROUND3(BX, CX, DX, BP, AX, 54)
	ROUND3(AX, BX, CX, DX, BP, 55)
	ROUND3(BP, AX, BX, CX, DX, 56)
	ROUND3(DX, BP, AX, BX, CX, 57)

	LOADCS(CX, DX, BP, AX, BX, 1)
	ROUND3(CX, DX, BP, AX, BX, 58)
	ROUND3(BX, CX, DX, BP, AX, 59)

	// ROUND4 (steps 60-79)
	ROUND4(AX, BX, CX, DX, BP, 60)
	ROUND4(BP, AX, BX, CX, DX, 61)
	ROUND4(DX, BP, AX, BX, CX, 62)
	ROUND4(CX, DX, BP, AX, BX, 63)
	ROUND4(BX, CX, DX, BP, AX, 64)

	LOADCS(AX, BX, CX, DX, BP, 2)
	ROUND4(AX, BX, CX, DX, BP, 65)
	ROUND4(BP, AX, BX, CX, DX, 66)
	ROUND4(DX, BP, AX, BX, CX, 67)
	ROUND4(CX, DX, BP, AX, BX, 68)
	ROUND4(BX, CX, DX, BP, AX, 69)
	ROUND4(AX, BX, CX, DX, BP, 70)
	ROUND4(BP, AX, BX, CX, DX, 71)
	ROUND4(DX, BP, AX, BX, CX, 72)
	ROUND4(CX, DX, BP, AX, BX, 73)
	ROUND4(BX, CX, DX, BP, AX, 74)
	ROUND4(AX, BX, CX, DX, BP, 75)
	ROUND4(BP, AX, BX, CX, DX, 76)
	ROUND4(DX, BP, AX, BX, CX, 77)
	ROUND4(CX, DX, BP, AX, BX, 78)
	ROUND4(BX, CX, DX, BP, AX, 79)

	// Add working registers to hash state.
	ADDL AX, R9
	ADDL BX, R10
	ADDL CX, R11
	ADDL DX, R12
	ADDL BP, R13

	// Increment hash iteration counter.
	MOVL 444(SP), AX
	INCL AX
	MOVL AX, 444(SP)

	// block hashed twice, another one to go.
	CMPL AX, $2
	JE rehash

	CMPL AX, $3
	JE next_chunk

	// h argument: copy from current hash state.
	MOVL    R9,  380(SP)
	MOVL    R10, 384(SP)
	MOVL    R11, 388(SP)
	MOVL    R12, 392(SP)
	MOVL    R13, 396(SP)
	
	SPILL_REGS(460)

	// Check stack layout comment for parameters.
	CALL ·checkCollision(SB)
	MOVB AL, 456(SP) // save return pre-unspill.
	
	UNSPILL_REGS(460)

	MOVB 456(SP), AL

	// If no collision found, move on to the next chunk.
	CMPB AL, $1
	JNE next_chunk

store_rehash:
	// If a collision was found for a block, ensure that
	// the collision flag is permanently true for all
	// chunks.
	MOVB AL, 440(SP)

	JMP rehash

next_chunk:
	MOVQ 432(SP), SI
	ADDQ $64, SI
	JMP loop

end:
	// Update h with final hash values.
	MOVQ h_base+0(FP), R8
	MOVL R9, (R8)
	MOVL R10, 4(R8)
	MOVL R11, 8(R8)
	MOVL R12, 12(R8)
	MOVL R13, 16(R8)

	MOVB 440(SP), AL
	MOVB AL, ret+48(FP)
	
	RET
