// Copyright 2013 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build !noasm && gc && amd64
// +build !noasm,gc,amd64

#include "textflag.h"

// SHA-1 block routine. See sha1block.go for Go equivalent.
//
// There are 80 rounds of 4 types:
//   - rounds 0-15 are type 1 and load data (ROUND1 macro).
//   - rounds 16-19 are type 1 and do not load data (ROUND1x macro).
//   - rounds 20-39 are type 2 and do not load data (ROUND2 macro).
//   - rounds 40-59 are type 3 and do not load data (ROUND3 macro).
//   - rounds 60-79 are type 4 and do not load data (ROUND4 macro).
//
// Each round loads or shuffles the data, then computes a per-round
// function of b, c, d, and then mixes the result into and rotates the
// five registers a, b, c, d, e holding the intermediate results.
//
// The register rotation is implemented by rotating the arguments to
// the round macros instead of by explicit move instructions.

// TODO: document collision detection behaviour
//
// local variables and stack layout:
//    0(SP) w  	 [16]uint32 		(64)
//   64(SP) m1 	 [80]uint32 		(320)
//  384(SP) hi 	 uint 				(4)
//  388(SP) mask uint 				(4)
//  392(SP) cs 	 [80][5]uint32 		(1600)
// 1992(SP) dvi	 uint 				(4)
// 1998(SP) R11 	 				(8)
// 2006(SP) R12 	 				(8)
// 2014(SP) R13 	 				(8)
// 2022(SP) R14 	 				(8)
// 2030(SP) R15 	 				(8)

#define LOAD(index) \
	MOVL	(index*4)(SI), R10; \
	BSWAPL	R10; \
	MOVL	R10, w-(index*4)(SP)

#define STORE_CS(a, b, c, d, e, index) \
	MOVL a, cs-((index*5*4)+392)(SP); \
	MOVL b, cs-((index*5*4)+392+4)(SP); \
	MOVL c, cs-((index*5*4)+392+8)(SP); \
	MOVL d, cs-((index*5*4)+392+12)(SP); \
	MOVL e, cs-((index*5*4)+392+16)(SP);

#define LOADM1(index) \
	MOVL w-(index*4)(SP), R10; \
	MOVL R10, m1-((index*4)+64)(SP) // m1 starts at 64

#define SHUFFLE(index) \
	MOVL	w-(((index)&0xf)*4)(SP), R10; \
	XORL	w-(((index-3)&0xf)*4)(SP), R10; \
	XORL	w-(((index-8)&0xf)*4)(SP), R10; \
	XORL	w-(((index-14)&0xf)*4)(SP), R10; \
	ROLL	$1, R10; \
	MOVL	R10, w-(((index)&0xf)*4)(SP)

#define FUNC1(a, b, c, d, e) \
	MOVL	d, R9; \
	XORL	c, R9; \
	ANDL	b, R9; \
	XORL	d, R9

#define FUNC2(a, b, c, d, e) \
	MOVL	b, R9; \
	XORL	c, R9; \
	XORL	d, R9

#define FUNC3(a, b, c, d, e) \
	MOVL	b, R8; \
	ORL	c, R8; \
	ANDL	d, R8; \
	MOVL	b, R9; \
	ANDL	c, R9; \
	ORL	R8, R9

#define FUNC4 FUNC2

#define MIX(a, b, c, d, e, const) \
	ROLL	$30, b; \
	ADDL	R9, e; \
	MOVL	a, R8; \
	ROLL	$5, R8; \
	LEAL	const(e)(R10*1), e; \
	ADDL	R8, e

#define UNDO_MIX(a, b, c, d, e, const, index) \
	RORL	$30, b; \
	SUBL	R9, e; \ // f
	MOVL	a, R8; \
	ROLL	$5, R8; \ 
	SUBL	R8, e; \ // a
	LEAL	const(e)(R10*1), e; \ // TODO: is this subtracting from e?
	MOVL 	m1-((index*4)+64)(SP), R9; \ // m2 = m1[j] ^ dvs[i].Dm[j]
	LEAQ 	sha1_dvs(SB), R8; \
	MOVQ 	((index*4)+48)(R8), R10; \ // R8 = dvs[i].Dm
	XORL 	R9, R10; \ // R10 = m1[j] ^ dvs[i].Dm[j]
	SUBL 	R10, e;

#define ROUND1(a, b, c, d, e, index) \
	LOAD(index); \
	FUNC1(a, b, c, d, e); \
	MIX(a, b, c, d, e, 0x5A827999); \
	LOADM1(index)

#define ROUND1x(a, b, c, d, e, index) \
	SHUFFLE(index); \
	FUNC1(a, b, c, d, e); \
	MIX(a, b, c, d, e, 0x5A827999); \
	LOADM1(index)

#define ROUND2(a, b, c, d, e, index) \
	SHUFFLE(index); \
	FUNC2(a, b, c, d, e); \
	MIX(a, b, c, d, e, 0x6ED9EBA1); \
	LOADM1(index)

#define ROUND3(a, b, c, d, e, index) \
	SHUFFLE(index); \
	FUNC3(a, b, c, d, e); \
	MIX(a, b, c, d, e, 0x8F1BBCDC); \
	LOADM1(index)

#define ROUND4(a, b, c, d, e, index) \
	SHUFFLE(index); \
	FUNC4(a, b, c, d, e); \
	MIX(a, b, c, d, e, 0xCA62C1D6); \
	LOADM1(index)

#define UNDO_ROUND1(a, b, c, d, e, index) \
	FUNC1(a, b, c, d, e); \
	UNDO_MIX(a, b, c, d, e, 0x5A827999, index);

#define UNDO_ROUND2(a, b, c, d, e, index) \
	FUNC2(a, b, c, d, e); \
	UNDO_MIX(a, b, c, d, e, 0x6ED9EBA1, index);

#define UNDO_ROUND3(a, b, c, d, e, index) \
	FUNC3(a, b, c, d, e); \
	UNDO_MIX(a, b, c, d, e, 0x8F1BBCDC, index);

#define UNDO_ROUND4(a, b, c, d, e, index) \
	FUNC4(a, b, c, d, e); \
	UNDO_MIX(a, b, c, d, e, 0xCA62C1D6, index);

// TODO: check if this is correct
#define RECOMPRESS_ROUND1(a, b, c, d, e, index) \
	FUNC1(a, b, c, d, e); \
	MIX(a, b, c, d, e, 0x5A827999);

// TODO: check if this is correct
#define RECOMPRESS_ROUND2(a, b, c, d, e, index) \
	FUNC2(a, b, c, d, e); \
	MIX(a, b, c, d, e, 0x6ED9EBA1);

// TODO: check if this is correct
#define RECOMPRESS_ROUND3(a, b, c, d, e, index) \
	FUNC3(a, b, c, d, e); \
	MIX(a, b, c, d, e, 0x8F1BBCDC);

// TODO: check if this is correct
#define RECOMPRESS_ROUND4(a, b, c, d, e, index) \
	FUNC4(a, b, c, d, e); \
	MIX(a, b, c, d, e, 0xCA62C1D6);

// func blockAMD64(dig *digest, p []byte)
TEXT ·blockAMD64(SB), $2048-80
	MOVQ dig+0(FP), BP
	MOVQ p_base+8(FP), SI
	MOVQ p_len+16(FP), DX
	SHRQ $6, DX
	SHLQ $6, DX
	LEAQ (SI)(DX*1), DI

	// Load h0-h4 values straight into a, b, c, d, e.
	MOVL (BP), AX
	MOVL 4(BP), BX
	MOVL 8(BP), CX
	MOVL 12(BP), DX
	MOVL 16(BP), BP

	// len(p) >= chunk
	CMPQ DI, SI
	JEQ  end

loop:
	// Reset hashing iteration counter.
	MOVL $0, hi-384(SP)

// Collision attacks are thwarted by hashing a detected near-collision block 3 times.
// Think of it as extending SHA-1 from 80-steps to 240-steps for such blocks:
// 		The best collision attacks against SHA-1 have complexity about 2^60,
// 		thus for 240-steps an immediate lower-bound for the best cryptanalytic attacks would be 2^180.
// 		An attacker would be better off using a generic birthday search of complexity 2^80.
rehash:
	// Save state of h0, h1, h2, h3, h4.
	MOVL AX, R11
	MOVL BX, R12
	MOVL CX, R13
	MOVL DX, R14
	MOVL BP, R15
	
	INCL hi-384(SP)

	// ROUND1 (Steps 0-15).
	STORE_CS(AX, BX, CX, DX, BP, 0) // pre-state for round 0
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

	// ROUND1x (Steps 16-19) - same as ROUND1 but without data load.
	ROUND1x(BP, AX, BX, CX, DX, 16)
	ROUND1x(DX, BP, AX, BX, CX, 17)
	ROUND1x(CX, DX, BP, AX, BX, 18)
	ROUND1x(BX, CX, DX, BP, AX, 19)

	// ROUND2 (Steps 20-39).
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

	// ROUND3 (Steps 40-59).
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
	STORE_CS(CX, DX, BP, AX, BX, 1) // pre-state for round 58
	ROUND3(CX, DX, BP, AX, BX, 58)
	ROUND3(BX, CX, DX, BP, AX, 59)

	// ROUND4 (Steps 60-79).
	ROUND4(AX, BX, CX, DX, BP, 60)
	ROUND4(BP, AX, BX, CX, DX, 61)
	ROUND4(DX, BP, AX, BX, CX, 62)
	ROUND4(CX, DX, BP, AX, BX, 63)
	ROUND4(BX, CX, DX, BP, AX, 64)
	STORE_CS(AX, BX, CX, DX, BP, 2) // pre-state for round 65
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

	// Add (a, b, c, d, e) to (h0, h1, h2, h3, h4)\.
	ADDL R11, AX
	ADDL R12, BX
	ADDL R13, CX
	ADDL R14, DX
	ADDL R15, BP

	// Short-circuit ubc checks when in the rehashing loop.
	MOVL hi-384(SP), R10
	CMPL R10, $2 // already checked ubc
	JE rehash

	CMPL R10, $3 // done rehashing
	JE nextblock
	
	// For each block, we calculate the dv mask.
	// And based on the results we either go to the next block, or
	// we go further into checking for the unavoidable bit conditions.
	MOVL $0xffffffff, R8 // mask value

	// (((((W[44] ^ W[45]) >> 29) & 1) - 1) | ^(DV_I_48_0_bit | DV_I_51_0_bit | DV_I_52_0_bit | DV_II_45_0_bit | DV_II_46_0_bit | DV_II_50_0_bit | DV_II_51_0_bit))
	MOVL m1-((44*4)+64)(SP), R9
	MOVL m1-((45*4)+64)(SP), R10
	XORL R10, R9
	SHRL $0x1d, R9
	ANDL $0x00000001, R9
	DECL R9
	ORL  $0xfd7c5f7f, R9
	ANDL R9, R8

	// mask &= (((((W[49] ^ W[50]) >> 29) & 1) - 1) | ^(DV_I_46_0_bit | DV_II_45_0_bit | DV_II_50_0_bit | DV_II_51_0_bit | DV_II_55_0_bit | DV_II_56_0_bit))
	MOVL m1-((49*4)+64)(SP), R9
	MOVL m1-((50*4)+64)(SP), R10
	XORL R10, R9
	SHRL $0x1d, R9
	ANDL $0x00000001, R9
	DECL R9
	ORL  $0x3d7efff7, R9
	ANDL R9, R8

	// mask &= (((((W[48] ^ W[49]) >> 29) & 1) - 1) | ^(DV_I_45_0_bit | DV_I_52_0_bit | DV_II_49_0_bit | DV_II_50_0_bit | DV_II_54_0_bit | DV_II_55_0_bit))
	MOVL m1-((48*4)+64)(SP), R9
	MOVL m1-((49*4)+64)(SP), R10
	XORL R10, R9
	SHRL $0x1d, R9
	ANDL $0x00000001, R9
	DECL R9
	ORL  $0x9f5f7ffb, R9
	ANDL R9, R8

	// mask &= ((((W[47] ^ (W[50] >> 25)) & (1 << 4)) - (1 << 4)) | ^(DV_I_47_0_bit | DV_I_49_0_bit | DV_I_51_0_bit | DV_II_45_0_bit | DV_II_51_0_bit | DV_II_56_0_bit))
	MOVL m1-((47*4)+64)(SP), R9
	MOVL m1-((50*4)+64)(SP), R10
	SHRL $0x19, R10
	XORL R10, R9
	ANDL $0x00000010, R9
	SUBL $0x00000010, R9
	ORL  $0x7dfedddf, R9
	ANDL R9, R8

	// mask &= (((((W[47] ^ W[48]) >> 29) & 1) - 1) | ^(DV_I_44_0_bit | DV_I_51_0_bit | DV_II_48_0_bit | DV_II_49_0_bit | DV_II_53_0_bit | DV_II_54_0_bit))
	MOVL m1-((47*4)+64)(SP), R9
	MOVL m1-((48*4)+64)(SP), R10
	XORL R10, R9
	SHRL $0x1d, R9
	ANDL $0x00000001, R9
	DECL R9
	ORL  $0xcfcfdffd, R9
	ANDL R9, R8

	// mask &= (((((W[46] >> 4) ^ (W[49] >> 29)) & 1) - 1) | ^(DV_I_46_0_bit | DV_I_48_0_bit | DV_I_50_0_bit | DV_I_52_0_bit | DV_II_50_0_bit | DV_II_55_0_bit))
	MOVL m1-((46*4)+64)(SP), R9
	SHRL $0x04, R9
	MOVL m1-((49*4)+64)(SP), R10
	SHRL $0x1d, R10
	XORL R10, R9
	ANDL $0x00000001, R9
	DECL R9
	ORL  $0xbf7f7777, R9
	ANDL R9, R8

	// mask &= (((((W[46] ^ W[47]) >> 29) & 1) - 1) | ^(DV_I_43_0_bit | DV_I_50_0_bit | DV_II_47_0_bit | DV_II_48_0_bit | DV_II_52_0_bit | DV_II_53_0_bit))
	MOVL m1-((46*4)+64)(SP), R9
	MOVL m1-((47*4)+64)(SP), R10
	XORL R10, R9
	SHRL $0x1d, R9
	ANDL $0x00000001, R9
	DECL R9
	ORL  $0xe7e7f7fe, R9
	ANDL R9, R8

	// mask &= (((((W[45] >> 4) ^ (W[48] >> 29)) & 1) - 1) | ^(DV_I_45_0_bit | DV_I_47_0_bit | DV_I_49_0_bit | DV_I_51_0_bit | DV_II_49_0_bit | DV_II_54_0_bit))
	MOVL m1-((45*4)+64)(SP), R9
	SHRL $0x04, R9
	MOVL m1-((48*4)+64)(SP), R10
	SHRL $0x1d, R10
	XORL R10, R9
	ANDL $0x00000001, R9
	DECL R9
	ORL  $0xdfdfdddb, R9
	ANDL R9, R8

	// mask &= (((((W[45] ^ W[46]) >> 29) & 1) - 1) | ^(DV_I_49_0_bit | DV_I_52_0_bit | DV_II_46_0_bit | DV_II_47_0_bit | DV_II_51_0_bit | DV_II_52_0_bit))
	MOVL m1-((45*4)+64)(SP), R9
	MOVL m1-((46*4)+64)(SP), R10
	XORL R10, R9
	SHRL $0x1d, R9
	ANDL $0x00000001, R9
	DECL R9
	ORL  $0xf5f57dff, R9
	ANDL R9, R8

	// mask &= (((((W[44] >> 4) ^ (W[47] >> 29)) & 1) - 1) | ^(DV_I_44_0_bit | DV_I_46_0_bit | DV_I_48_0_bit | DV_I_50_0_bit | DV_II_48_0_bit | DV_II_53_0_bit))
	MOVL m1-((44*4)+64)(SP), R9
	SHRL $0x04, R9
	MOVL m1-((47*4)+64)(SP), R10
	SHRL $0x1d, R10
	XORL R10, R9
	ANDL $0x00000001, R9
	DECL R9
	ORL  $0xefeff775, R9
	ANDL R9, R8

	// mask &= (((((W[43] >> 4) ^ (W[46] >> 29)) & 1) - 1) | ^(DV_I_43_0_bit | DV_I_45_0_bit | DV_I_47_0_bit | DV_I_49_0_bit | DV_II_47_0_bit | DV_II_52_0_bit))
	MOVL m1-((43*4)+64)(SP), R9
	SHRL $0x04, R9
	MOVL m1-((46*4)+64)(SP), R10
	SHRL $0x1d, R10
	XORL R10, R9
	ANDL $0x00000001, R9
	DECL R9
	ORL  $0xf7f7fdda, R9
	ANDL R9, R8

	// mask &= (((((W[43] ^ W[44]) >> 29) & 1) - 1) | ^(DV_I_47_0_bit | DV_I_50_0_bit | DV_I_51_0_bit | DV_II_45_0_bit | DV_II_49_0_bit | DV_II_50_0_bit))
	MOVL m1-((43*4)+64)(SP), R9
	MOVL m1-((44*4)+64)(SP), R10
	XORL R10, R9
	SHRL $0x1d, R9
	ANDL $0x00000001, R9
	DECL R9
	ORL  $0xff5ed7df, R9
	ANDL R9, R8

	// mask &= (((((W[42] >> 4) ^ (W[45] >> 29)) & 1) - 1) | ^(DV_I_44_0_bit | DV_I_46_0_bit | DV_I_48_0_bit | DV_I_52_0_bit | DV_II_46_0_bit | DV_II_51_0_bit))
	MOVL m1-((42*4)+64)(SP), R9
	SHRL $0x04, R9
	MOVL m1-((45*4)+64)(SP), R10
	SHRL $0x1d, R10
	XORL R10, R9
	ANDL $0x00000001, R9
	DECL R9
	ORL  $0xfdfd7f75, R9
	ANDL R9, R8

	// mask &= (((((W[41] >> 4) ^ (W[44] >> 29)) & 1) - 1) | ^(DV_I_43_0_bit | DV_I_45_0_bit | DV_I_47_0_bit | DV_I_51_0_bit | DV_II_45_0_bit | DV_II_50_0_bit))
	MOVL m1-((41*4)+64)(SP), R9
	SHRL $0x04, R9
	MOVL m1-((44*4)+64)(SP), R10
	SHRL $0x1d, R10
	XORL R10, R9
	ANDL $0x00000001, R9
	DECL R9
	ORL  $0xff7edfda, R9
	ANDL R9, R8

	// mask &= (((((W[40] ^ W[41]) >> 29) & 1) - 1) | ^(DV_I_44_0_bit | DV_I_47_0_bit | DV_I_48_0_bit | DV_II_46_0_bit | DV_II_47_0_bit | DV_II_56_0_bit))
	MOVL m1-((40*4)+64)(SP), R9
	MOVL m1-((41*4)+64)(SP), R10
	XORL R10, R9
	SHRL $0x1d, R9
	ANDL $0x00000001, R9
	DECL R9
	ORL  $0x7ff5ff5d, R9
	ANDL R9, R8

	// mask &= (((((W[54] ^ W[55]) >> 29) & 1) - 1) | ^(DV_I_51_0_bit | DV_II_47_0_bit | DV_II_50_0_bit | DV_II_55_0_bit | DV_II_56_0_bit))
	MOVL m1-((54*4)+64)(SP), R9
	MOVL m1-((55*4)+64)(SP), R10
	XORL R10, R9
	SHRL $0x1d, R9
	ANDL $0x00000001, R9
	DECL R9
	ORL  $0x3f77dfff, R9
	ANDL R9, R8

	// mask &= (((((W[53] ^ W[54]) >> 29) & 1) - 1) | ^(DV_I_50_0_bit | DV_II_46_0_bit | DV_II_49_0_bit | DV_II_54_0_bit | DV_II_55_0_bit))
	MOVL m1-((53*4)+64)(SP), R9
	MOVL m1-((54*4)+64)(SP), R10
	XORL R10, R9
	SHRL $0x1d, R9
	ANDL $0x00000001, R9
	DECL R9
	ORL  $0x9fddf7ff, R9
	ANDL R9, R8

	// mask &= (((((W[52] ^ W[53]) >> 29) & 1) - 1) | ^(DV_I_49_0_bit | DV_II_45_0_bit | DV_II_48_0_bit | DV_II_53_0_bit | DV_II_54_0_bit))
	MOVL m1-((52*4)+64)(SP), R9
	MOVL m1-((53*4)+64)(SP), R10
	XORL R10, R9
	SHRL $0x1d, R9
	ANDL $0x00000001, R9
	DECL R9
	ORL  $0xcfeefdff, R9
	ANDL R9, R8

	// mask &= ((((W[50] ^ (W[53] >> 25)) & (1 << 4)) - (1 << 4)) | ^(DV_I_50_0_bit | DV_I_52_0_bit | DV_II_46_0_bit | DV_II_48_0_bit | DV_II_54_0_bit))
	MOVL m1-((50*4)+64)(SP), R9
	MOVL m1-((53*4)+64)(SP), R10
	SHRL $0x19, R10
	XORL R10, R9
	ANDL $0x00000010, R9
	SUBL $0x00000010, R9
	ORL  $0xdfed77ff, R9
	ANDL R9, R8

	// mask &= (((((W[50] ^ W[51]) >> 29) & 1) - 1) | ^(DV_I_47_0_bit | DV_II_46_0_bit | DV_II_51_0_bit | DV_II_52_0_bit | DV_II_56_0_bit))
	MOVL m1-((50*4)+64)(SP), R9
	MOVL m1-((51*4)+64)(SP), R10
	XORL R10, R9
	SHRL $0x1d, R9
	ANDL $0x00000001, R9
	DECL R9
	ORL  $0x75fdffdf, R9
	ANDL R9, R8

	// mask &= ((((W[49] ^ (W[52] >> 25)) & (1 << 4)) - (1 << 4)) | ^(DV_I_49_0_bit | DV_I_51_0_bit | DV_II_45_0_bit | DV_II_47_0_bit | DV_II_53_0_bit))
	MOVL m1-((49*4)+64)(SP), R9
	MOVL m1-((52*4)+64)(SP), R10
	SHRL $0x19, R10
	XORL R10, R9
	ANDL $0x00000010, R9
	SUBL $0x00000010, R9
	ORL  $0xeff6ddff, R9
	ANDL R9, R8

	// mask &= ((((W[48] ^ (W[51] >> 25)) & (1 << 4)) - (1 << 4)) | ^(DV_I_48_0_bit | DV_I_50_0_bit | DV_I_52_0_bit | DV_II_46_0_bit | DV_II_52_0_bit))
	MOVL m1-((48*4)+64)(SP), R9
	MOVL m1-((51*4)+64)(SP), R10
	SHRL $0x19, R10
	XORL R10, R9
	ANDL $0x00000010, R9
	SUBL $0x00000010, R9
	ORL  $0xf7fd777f, R9
	ANDL R9, R8

	// mask &= (((((W[42] ^ W[43]) >> 29) & 1) - 1) | ^(DV_I_46_0_bit | DV_I_49_0_bit | DV_I_50_0_bit | DV_II_48_0_bit | DV_II_49_0_bit))
	MOVL m1-((42*4)+64)(SP), R9
	MOVL m1-((43*4)+64)(SP), R10
	XORL R10, R9
	SHRL $0x1d, R9
	ANDL $0x00000001, R9
	DECL R9
	ORL  $0xffcff5f7, R9
	ANDL R9, R8

	// mask &= (((((W[41] ^ W[42]) >> 29) & 1) - 1) | ^(DV_I_45_0_bit | DV_I_48_0_bit | DV_I_49_0_bit | DV_II_47_0_bit | DV_II_48_0_bit))
	MOVL m1-((41*4)+64)(SP), R9
	MOVL m1-((42*4)+64)(SP), R10
	XORL R10, R9
	SHRL $0x1d, R9
	ANDL $0x00000001, R9
	DECL R9
	ORL  $0xffe7fd7b, R9
	ANDL R9, R8

	// mask &= (((((W[40] >> 4) ^ (W[43] >> 29)) & 1) - 1) | ^(DV_I_44_0_bit | DV_I_46_0_bit | DV_I_50_0_bit | DV_II_49_0_bit | DV_II_56_0_bit))
	MOVL m1-((40*4)+64)(SP), R9
	MOVL m1-((43*4)+64)(SP), R10
	SHRL $0x04, R9
	SHRL $0x1d, R10
	XORL R10, R9
	ANDL $0x00000001, R9
	DECL R9
	ORL  $0x7fdff7f5, R9
	ANDL R9, R8

	// mask &= (((((W[39] >> 4) ^ (W[42] >> 29)) & 1) - 1) | ^(DV_I_43_0_bit | DV_I_45_0_bit | DV_I_49_0_bit | DV_II_48_0_bit | DV_II_55_0_bit))
	MOVL m1-((39*4)+64)(SP), R9
	MOVL m1-((42*4)+64)(SP), R10
	SHRL $0x04, R9
	SHRL $0x1d, R10
	XORL R10, R9
	ANDL $0x00000001, R9
	DECL R9
	ORL  $0xbfeffdfa, R9
	ANDL R9, R8

	// if (mask & (DV_I_44_0_bit | DV_I_48_0_bit | DV_II_47_0_bit | DV_II_54_0_bit | DV_II_56_0_bit)) != 0 {
	//   mask &= (((((W[38] >> 4) ^ (W[41] >> 29)) & 1) - 1) | ^(DV_I_44_0_bit | DV_I_48_0_bit | DV_II_47_0_bit | DV_II_54_0_bit | DV_II_56_0_bit))
	// }
	TESTL $0xa0080082, R8
	JE    f1
	MOVL  m1-((38*4)+64)(SP), R9
	MOVL  m1-((41*4)+64)(SP), R10
	SHRL  $0x04, R9
	SHRL  $0x1d, R10
	XORL  R10, R9
	ANDL  $0x00000001, R9
	DECL  R9
	ORL   $0x5ff7ff7d, R9
	ANDL  R9, R8

f1:
	// mask &= (((((W[37] >> 4) ^ (W[40] >> 29)) & 1) - 1) | ^(DV_I_43_0_bit | DV_I_47_0_bit | DV_II_46_0_bit | DV_II_53_0_bit | DV_II_55_0_bit))
	MOVL m1-((37*4)+64)(SP), R9
	MOVL m1-((40*4)+64)(SP), R10
	SHRL $0x04, R9
	SHRL $0x1d, R10
	XORL R10, R9
	ANDL $0x00000001, R9
	DECL R9
	ORL  $0xaffdffde, R9
	ANDL R9, R8

	// if (mask & (DV_I_52_0_bit | DV_II_48_0_bit | DV_II_51_0_bit | DV_II_56_0_bit)) != 0 {
	//   mask &= (((((W[55] ^ W[56]) >> 29) & 1) - 1) | ^(DV_I_52_0_bit | DV_II_48_0_bit | DV_II_51_0_bit | DV_II_56_0_bit))
	// }
	TESTL $0x82108000, R8
	JE    f2
	MOVL  m1-((55*4)+64)(SP), R9
	MOVL  m1-((56*4)+64)(SP), R10
	XORL  R10, R9
	SHRL  $0x1d, R9
	ANDL  $0x00000001, R9
	DECL  R9
	ORL   $0x7def7fff, R9
	ANDL  R9, R8

f2:
	// if (mask & (DV_I_52_0_bit | DV_II_48_0_bit | DV_II_50_0_bit | DV_II_56_0_bit)) != 0 {
	//   mask &= ((((W[52] ^ (W[55] >> 25)) & (1 << 4)) - (1 << 4)) | ^(DV_I_52_0_bit | DV_II_48_0_bit | DV_II_50_0_bit | DV_II_56_0_bit))
	// }
	TESTL $0x80908000, R8
	JE    f3
	MOVL  m1-((52*4)+64)(SP), R9
	MOVL  m1-((55*4)+64)(SP), R10
	SHRL  $0x19, R10
	XORL  R10, R9
	ANDL  $0x00000010, R9
	SUBL  $0x00000010, R9
	ORL   $0x7f6f7fff, R9
	ANDL  R9, R8

f3:
	// if (mask & (DV_I_51_0_bit | DV_II_47_0_bit | DV_II_49_0_bit | DV_II_55_0_bit)) != 0 {
	//   mask &= ((((W[51] ^ (W[54] >> 25)) & (1 << 4)) - (1 << 4)) | ^(DV_I_51_0_bit | DV_II_47_0_bit | DV_II_49_0_bit | DV_II_55_0_bit))
	// }
	TESTL $0x40282000, R8
	JE    f4
	MOVL  m1-((51*4)+64)(SP), R9
	MOVL  m1-((54*4)+64)(SP), R10
	SHRL  $0x19, R10
	XORL  R10, R9
	ANDL  $0x00000010, R9
	SUBL  $0x00000010, R9
	ORL   $0xbfd7dfff, R9
	ANDL  R9, R8

f4:
	// if (mask & (DV_I_48_0_bit | DV_II_47_0_bit | DV_II_52_0_bit | DV_II_53_0_bit)) != 0 {
	//   mask &= (((((W[51] ^ W[52]) >> 29) & 1) - 1) | ^(DV_I_48_0_bit | DV_II_47_0_bit | DV_II_52_0_bit | DV_II_53_0_bit))
	// }
	TESTL $0x18080080, R8
	JE    f5
	MOVL  m1-((51*4)+64)(SP), R9
	MOVL  m1-((52*4)+64)(SP), R10
	XORL  R10, R9
	SHRL  $0x1d, R9
	ANDL  $0x00000001, R9
	DECL  R9
	ORL   $0xe7f7ff7f, R9
	ANDL  R9, R8

f5:
	// if (mask & (DV_I_46_0_bit | DV_I_49_0_bit | DV_II_45_0_bit | DV_II_48_0_bit)) != 0 {
	//   mask &= (((((W[36] >> 4) ^ (W[40] >> 29)) & 1) - 1) | ^(DV_I_46_0_bit | DV_I_49_0_bit | DV_II_45_0_bit | DV_II_48_0_bit))
	// }
	TESTL $0x00110208, R8
	JE    f6
	MOVL  m1-((36*4)+64)(SP), R9
	SHRL  $0x04, R9
	MOVL  m1-((40*4)+64)(SP), R10
	SHRL  $0x1d, R10
	XORL  R10, R9
	ANDL  $0x00000001, R9
	DECL  R9
	ORL   $0xffeefdf7, R9
	ANDL  R9, R8

f6:
	// if (mask & (DV_I_52_0_bit | DV_II_48_0_bit | DV_II_49_0_bit)) != 0 {
	//   mask &= ((0 - (((W[53] ^ W[56]) >> 29) & 1)) | ^(DV_I_52_0_bit | DV_II_48_0_bit | DV_II_49_0_bit))
	// }
	TESTL $0x00308000, R8
	JE    f7
	MOVL  m1-((53*4)+64)(SP), R9
	MOVL  m1-((56*4)+64)(SP), R10
	XORL  R10, R9
	SHRL  $0x1d, R9
	ANDL  $0x00000001, R9
	NEGL  R9
	ORL   $0xffcf7fff, R9
	ANDL  R9, R8

f7:
	// if (mask & (DV_I_50_0_bit | DV_II_46_0_bit | DV_II_47_0_bit)) != 0 {
	// 	mask &= ((0 - (((W[51] ^ W[54]) >> 29) & 1)) | ^(DV_I_50_0_bit | DV_II_46_0_bit | DV_II_47_0_bit))
	// }
	TESTL $0x000a0800, R8
	JE    f8
	MOVL  m1-((51*4)+64)(SP), R9
	MOVL  m1-((54*4)+64)(SP), R10
	XORL  R10, R9
	SHRL  $0x1d, R9
	ANDL  $0x00000001, R9
	NEGL  R9
	ORL   $0xfff5f7ff, R9
	ANDL  R9, R8

f8:
	// if (mask & (DV_I_49_0_bit | DV_I_51_0_bit | DV_II_45_0_bit)) != 0 {
	// 	mask &= ((0 - (((W[50] ^ W[52]) >> 29) & 1)) | ^(DV_I_49_0_bit | DV_I_51_0_bit | DV_II_45_0_bit))
	// }
	TESTL $0x00012200, R8
	JE    f9
	MOVL  m1-((50*4)+64)(SP), R9
	MOVL  m1-((52*4)+64)(SP), R10
	XORL  R10, R9
	SHRL  $0x1d, R9
	ANDL  $0x00000001, R9
	NEGL  R9
	ORL   $0xfffeddff, R9
	ANDL  R9, R8

f9:
	// if (mask & (DV_I_48_0_bit | DV_I_50_0_bit | DV_I_52_0_bit)) != 0 {
	// 	mask &= ((0 - (((W[49] ^ W[51]) >> 29) & 1)) | ^(DV_I_48_0_bit | DV_I_50_0_bit | DV_I_52_0_bit))
	// }
	TESTL $0x00008880, R8
	JE    f10
	MOVL  m1-((49*4)+64)(SP), R9
	MOVL  m1-((51*4)+64)(SP), R10
	XORL  R10, R9
	SHRL  $0x1d, R9
	ANDL  $0x00000001, R9
	NEGL  R9
	ORL   $0xffff777f, R9
	ANDL  R9, R8

f10:
	// if (mask & (DV_I_47_0_bit | DV_I_49_0_bit | DV_I_51_0_bit)) != 0 {
	// 	mask &= ((0 - (((W[48] ^ W[50]) >> 29) & 1)) | ^(DV_I_47_0_bit | DV_I_49_0_bit | DV_I_51_0_bit))
	// }
	TESTL $0x00002220, R8
	JE    f11
	MOVL  m1-((48*4)+64)(SP), R9
	MOVL  m1-((50*4)+64)(SP), R10
	XORL  R10, R9
	SHRL  $0x1d, R9
	ANDL  $0x00000001, R9
	NEGL  R9
	ORL   $0xffffdddf, R9
	ANDL  R9, R8

f11:
	// if (mask & (DV_I_46_0_bit | DV_I_48_0_bit | DV_I_50_0_bit)) != 0 {
	// 	mask &= ((0 - (((W[47] ^ W[49]) >> 29) & 1)) | ^(DV_I_46_0_bit | DV_I_48_0_bit | DV_I_50_0_bit))
	// }
	TESTL $0x00000888, R8
	JE    f12
	MOVL  m1-((47*4)+64)(SP), R9
	MOVL  m1-((49*4)+64)(SP), R10
	XORL  R10, R9
	SHRL  $0x1d, R9
	ANDL  $0x00000001, R9
	NEGL  R9
	ORL   $0xfffff777, R9
	ANDL  R9, R8

f12:
	// if (mask & (DV_I_45_0_bit | DV_I_47_0_bit | DV_I_49_0_bit)) != 0 {
	// 	mask &= ((0 - (((W[46] ^ W[48]) >> 29) & 1)) | ^(DV_I_45_0_bit | DV_I_47_0_bit | DV_I_49_0_bit))
	// }
	TESTL $0x00000224, R8
	JE    f13
	MOVL  m1-((46*4)+64)(SP), R9
	MOVL  m1-((48*4)+64)(SP), R10
	XORL  R10, R9
	SHRL  $0x1d, R9
	ANDL  $0x00000001, R9
	NEGL  R9
	ORL   $0xfffffddb, R9
	ANDL  R9, R8

f13:
	// mask &= ((((W[45] ^ W[47]) & (1 << 6)) - (1 << 6)) | ^(DV_I_47_2_bit | DV_I_49_2_bit | DV_I_51_2_bit))
	MOVL m1-((45*4)+64)(SP), R9
	MOVL m1-((47*4)+64)(SP), R10
	XORL R10, R9
	ANDL $0x00000040, R9
	SUBL $0x00000040, R9
	ORL  $0xffffbbbf, R9
	ANDL R9, R8

	// if (mask & (DV_I_44_0_bit | DV_I_46_0_bit | DV_I_48_0_bit)) != 0 {
	// 	mask &= ((0 - (((W[45] ^ W[47]) >> 29) & 1)) | ^(DV_I_44_0_bit | DV_I_46_0_bit | DV_I_48_0_bit))
	// }
	TESTL $0x0000008a, R8
	JE    f14
	MOVL  m1-((45*4)+64)(SP), R9
	MOVL  m1-((47*4)+64)(SP), R10
	XORL  R10, R9
	SHRL  $0x1d, R9
	ANDL  $0x00000001, R9
	NEGL  R9
	ORL   $0xffffff75, R9
	ANDL  R9, R8

f14:
	// mask &= (((((W[44] ^ W[46]) >> 6) & 1) - 1) | ^(DV_I_46_2_bit | DV_I_48_2_bit | DV_I_50_2_bit))
	MOVL m1-((44*4)+64)(SP), R9
	MOVL m1-((46*4)+64)(SP), R10
	XORL R10, R9
	SHRL $0x06, R9
	ANDL $0x00000001, R9
	DECL R9
	ORL  $0xffffeeef, R9
	ANDL R9, R8

	// if (mask & (DV_I_43_0_bit | DV_I_45_0_bit | DV_I_47_0_bit)) != 0 {
	// 	mask &= ((0 - (((W[44] ^ W[46]) >> 29) & 1)) | ^(DV_I_43_0_bit | DV_I_45_0_bit | DV_I_47_0_bit))
	// }
	TESTL $0x00000025, R8
	JE    f15
	MOVL  m1-((44*4)+64)(SP), R9
	MOVL  m1-((46*4)+64)(SP), R10
	XORL  R10, R9
	SHRL  $0x1d, R9
	ANDL  $0x00000001, R9
	NEGL  R9
	ORL   $0xffffffda, R9
	ANDL  R9, R8

f15:
	// mask &= ((0 - ((W[41] ^ (W[42] >> 5)) & (1 << 1))) | ^(DV_I_48_2_bit | DV_II_46_2_bit | DV_II_51_2_bit))
	MOVL m1-((41*4)+64)(SP), R9
	MOVL m1-((42*4)+64)(SP), R10
	SHRL $0x05, R10
	XORL R10, R9
	ANDL $0x00000002, R9
	NEGL R9
	ORL  $0xfbfbfeff, R9
	ANDL R9, R8

	// mask &= ((0 - ((W[40] ^ (W[41] >> 5)) & (1 << 1))) | ^(DV_I_47_2_bit | DV_I_51_2_bit | DV_II_50_2_bit))
	MOVL m1-((40*4)+64)(SP), R9
	MOVL m1-((41*4)+64)(SP), R10
	SHRL $0x05, R10
	XORL R10, R9
	ANDL $0x00000002, R9
	NEGL R9
	ORL  $0xfeffbfbf, R9
	ANDL R9, R8

	// if (mask & (DV_I_44_0_bit | DV_I_46_0_bit | DV_II_56_0_bit)) != 0 {
	// 	mask &= ((0 - (((W[40] ^ W[42]) >> 4) & 1)) | ^(DV_I_44_0_bit | DV_I_46_0_bit | DV_II_56_0_bit))
	// }
	TESTL $0x8000000a, R8
	JE    f16
	MOVL  m1-((40*4)+64)(SP), R9
	MOVL  m1-((42*4)+64)(SP), R10
	XORL  R10, R9
	SHRL  $0x04, R9
	ANDL  $0x00000001, R9
	NEGL  R9
	ORL   $0x7ffffff5, R9
	ANDL  R9, R8

f16:
	// mask &= ((0 - ((W[39] ^ (W[40] >> 5)) & (1 << 1))) | ^(DV_I_46_2_bit | DV_I_50_2_bit | DV_II_49_2_bit))
	MOVL m1-((39*4)+64)(SP), R9
	MOVL m1-((40*4)+64)(SP), R10
	SHRL $0x05, R10
	XORL R10, R9
	ANDL $0x00000002, R9
	NEGL R9
	ORL  $0xffbfefef, R9
	ANDL R9, R8

	// if (mask & (DV_I_43_0_bit | DV_I_45_0_bit | DV_II_55_0_bit)) != 0 {
	// 	mask &= ((0 - (((W[39] ^ W[41]) >> 4) & 1)) | ^(DV_I_43_0_bit | DV_I_45_0_bit | DV_II_55_0_bit))
	// }
	TESTL $0x40000005, R8
	JE    f17
	MOVL  m1-((39*4)+64)(SP), R9
	MOVL  m1-((41*4)+64)(SP), R10
	XORL  R10, R9
	SHRL  $0x04, R9
	ANDL  $0x00000001, R9
	NEGL  R9
	ORL   $0xbffffffa, R9
	ANDL  R9, R8

f17:
	// if (mask & (DV_I_44_0_bit | DV_II_54_0_bit | DV_II_56_0_bit)) != 0 {
	// 	mask &= ((0 - (((W[38] ^ W[40]) >> 4) & 1)) | ^(DV_I_44_0_bit | DV_II_54_0_bit | DV_II_56_0_bit))
	// }
	TESTL $0xa0000002, R8
	JE    f18
	MOVL  m1-((38*4)+64)(SP), R9
	MOVL  m1-((40*4)+64)(SP), R10
	XORL  R10, R9
	SHRL  $0x04, R9
	ANDL  $0x00000001, R9
	NEGL  R9
	ORL   $0x5ffffffd, R9
	ANDL  R9, R8

f18:
	// if (mask & (DV_I_43_0_bit | DV_II_53_0_bit | DV_II_55_0_bit)) != 0 {
	// 	mask &= ((0 - (((W[37] ^ W[39]) >> 4) & 1)) | ^(DV_I_43_0_bit | DV_II_53_0_bit | DV_II_55_0_bit))
	// }
	TESTL $0x50000001, R8
	JE    f19
	MOVL  m1-((37*4)+64)(SP), R9
	MOVL  m1-((39*4)+64)(SP), R10
	XORL  R10, R9
	SHRL  $0x04, R9
	ANDL  $0x00000001, R9
	NEGL  R9
	ORL   $0xaffffffe, R9
	ANDL  R9, R8

f19:
	// mask &= ((0 - ((W[36] ^ (W[37] >> 5)) & (1 << 1))) | ^(DV_I_47_2_bit | DV_I_50_2_bit | DV_II_46_2_bit))
	MOVL m1-((36*4)+64)(SP), R9
	MOVL m1-((37*4)+64)(SP), R10
	SHRL $0x05, R10
	XORL R10, R9
	ANDL $0x00000002, R9
	NEGL R9
	ORL  $0xfffbefbf, R9
	ANDL R9, R8

	// if (mask & (DV_I_45_0_bit | DV_I_48_0_bit | DV_II_47_0_bit)) != 0 {
	// 	mask &= (((((W[35] >> 4) ^ (W[39] >> 29)) & 1) - 1) | ^(DV_I_45_0_bit | DV_I_48_0_bit | DV_II_47_0_bit))
	// }
	TESTL $0x00080084, R8
	JE    f20
	MOVL  m1-((35*4)+64)(SP), R9
	MOVL  m1-((39*4)+64)(SP), R10
	SHRL  $0x04, R9
	SHRL  $0x1d, R10
	XORL  R10, R9
	ANDL  $0x00000001, R9
	SUBL  $0x00000001, R9
	ORL   $0xfff7ff7b, R9
	ANDL  R9, R8

f20:
	// if (mask & (DV_I_48_0_bit | DV_II_48_0_bit)) != 0 {
	// 	mask &= ((0 - ((W[63] ^ (W[64] >> 5)) & (1 << 0))) | ^(DV_I_48_0_bit | DV_II_48_0_bit))
	// }
	TESTL $0x00100080, R8
	JE    f21
	MOVL  m1-((63*4)+64)(SP), R9
	MOVL  m1-((64*4)+64)(SP), R10
	SHRL  $0x05, R10
	XORL  R10, R9
	ANDL  $0x00000001, R9
	NEGL  R9
	ORL   $0xffefff7f, R9
	ANDL  R9, R8

f21:
	// if (mask & (DV_I_45_0_bit | DV_II_45_0_bit)) != 0 {
	// 	mask &= ((0 - ((W[63] ^ (W[64] >> 5)) & (1 << 1))) | ^(DV_I_45_0_bit | DV_II_45_0_bit))
	// }
	TESTL $0x00010004, R8
	JE    f22
	MOVL  m1-((63*4)+64)(SP), R9
	MOVL  m1-((64*4)+64)(SP), R10
	SHRL  $0x05, R10
	XORL  R10, R9
	ANDL  $0x00000002, R9
	NEGL  R9
	ORL   $0xfffefffb, R9
	ANDL  R9, R8

f22:
	// if (mask & (DV_I_47_0_bit | DV_II_47_0_bit)) != 0 {
	// 	mask &= ((0 - ((W[62] ^ (W[63] >> 5)) & (1 << 0))) | ^(DV_I_47_0_bit | DV_II_47_0_bit))
	// }
	TESTL $0x00080020, R8
	JE    f23
	MOVL  m1-((62*4)+64)(SP), R9
	MOVL  m1-((63*4)+64)(SP), R10
	SHRL  $0x05, R10
	XORL  R10, R9
	ANDL  $0x00000001, R9
	NEGL  R9
	ORL   $0xfff7ffdf, R9
	ANDL  R9, R8

f23:
	// if (mask & (DV_I_46_0_bit | DV_II_46_0_bit)) != 0 {
	// 	mask &= ((0 - ((W[61] ^ (W[62] >> 5)) & (1 << 0))) | ^(DV_I_46_0_bit | DV_II_46_0_bit))
	// }
	TESTL $0x00020008, R8
	JE    f24
	MOVL  m1-((61*4)+64)(SP), R9
	MOVL  m1-((62*4)+64)(SP), R10
	SHRL  $0x05, R10
	XORL  R10, R9
	ANDL  $0x00000001, R9
	NEGL  R9
	ORL   $0xfffdfff7, R9
	ANDL  R9, R8

f24:
	// mask &= ((0 - ((W[61] ^ (W[62] >> 5)) & (1 << 2))) | ^(DV_I_46_2_bit | DV_II_46_2_bit))
	MOVL m1-((61*4)+64)(SP), R9
	MOVL m1-((62*4)+64)(SP), R10
	SHRL $0x05, R10
	XORL R10, R9
	ANDL $0x00000004, R9
	NEGL R9
	ORL  $0xfffbffef, R9
	ANDL R9, R8

	// if (mask & (DV_I_45_0_bit | DV_II_45_0_bit)) != 0 {
	// 	mask &= ((0 - ((W[60] ^ (W[61] >> 5)) & (1 << 0))) | ^(DV_I_45_0_bit | DV_II_45_0_bit))
	// }
	TESTL $0x00010004, R8
	JE    f25
	MOVL  m1-((60*4)+64)(SP), R9
	MOVL  m1-((61*4)+64)(SP), R10
	SHRL  $0x05, R10
	XORL  R10, R9
	ANDL  $0x00000001, R9
	NEGL  R9
	ORL   $0xfffefffb, R9
	ANDL  R9, R8

f25:
	// if (mask & (DV_II_51_0_bit | DV_II_54_0_bit)) != 0 {
	// 	mask &= (((((W[58] ^ W[59]) >> 29) & 1) - 1) | ^(DV_II_51_0_bit | DV_II_54_0_bit))
	// }
	TESTL $0x22000000, R8
	JE    f26
	MOVL  m1-((58*4)+64)(SP), R9
	MOVL  m1-((59*4)+64)(SP), R10
	XORL  R10, R9
	SHRL  $0x1d, R9
	ANDL  $0x00000001, R9
	SUBL  $0x00000001, R9
	ORL   $0xddffffff, R9
	ANDL  R9, R8

f26:
	// if (mask & (DV_II_50_0_bit | DV_II_53_0_bit)) != 0 {
	// 	mask &= (((((W[57] ^ W[58]) >> 29) & 1) - 1) | ^(DV_II_50_0_bit | DV_II_53_0_bit))
	// }
	TESTL $0x10800000, R8
	JE    f27
	MOVL  m1-((57*4)+64)(SP), R9
	MOVL  m1-((58*4)+64)(SP), R10
	XORL  R10, R9
	SHRL  $0x1d, R9
	ANDL  $0x00000001, R9
	SUBL  $0x00000001, R9
	ORL   $0xef7fffff, R9
	ANDL  R9, R8

f27:
	// if (mask & (DV_II_52_0_bit | DV_II_54_0_bit)) != 0 {
	// 	mask &= ((((W[56] ^ (W[59] >> 25)) & (1 << 4)) - (1 << 4)) | ^(DV_II_52_0_bit | DV_II_54_0_bit))
	// }
	TESTL $0x28000000, R8
	JE    f28
	MOVL  m1-((56*4)+64)(SP), R9
	MOVL  m1-((59*4)+64)(SP), R10
	SHRL  $0x19, R10
	XORL  R10, R9
	ANDL  $0x00000010, R9
	SUBL  $0x00000010, R9
	ORL   $0xd7ffffff, R9
	ANDL  R9, R8

f28:
	// if (mask & (DV_II_51_0_bit | DV_II_52_0_bit)) != 0 {
	// 	mask &= ((0 - (((W[56] ^ W[59]) >> 29) & 1)) | ^(DV_II_51_0_bit | DV_II_52_0_bit))
	// }
	TESTL $0x0a000000, R8
	JE    f29
	MOVL  m1-((56*4)+64)(SP), R9
	MOVL  m1-((59*4)+64)(SP), R10
	XORL  R10, R9
	SHRL  $0x1d, R9
	ANDL  $0x00000001, R9
	NEGL  R9
	ORL   $0xf5ffffff, R9
	ANDL  R9, R8

f29:
	// if (mask & (DV_II_49_0_bit | DV_II_52_0_bit)) != 0 {
	// 	mask &= (((((W[56] ^ W[57]) >> 29) & 1) - 1) | ^(DV_II_49_0_bit | DV_II_52_0_bit))
	// }
	TESTL $0x08200000, R8
	JE    f30
	MOVL  m1-((56*4)+64)(SP), R9
	MOVL  m1-((57*4)+64)(SP), R10
	XORL  R10, R9
	SHRL  $0x1d, R9
	ANDL  $0x00000001, R9
	SUBL  $0x00000001, R9
	ORL   $0xf7dfffff, R9
	ANDL  R9, R8

f30:
	// if (mask & (DV_II_51_0_bit | DV_II_53_0_bit)) != 0 {
	// 	mask &= ((((W[55] ^ (W[58] >> 25)) & (1 << 4)) - (1 << 4)) | ^(DV_II_51_0_bit | DV_II_53_0_bit))
	// }
	TESTL $0x12000000, R8
	JE    f31
	MOVL  m1-((55*4)+64)(SP), R9
	MOVL  m1-((58*4)+64)(SP), R10
	SHRL  $0x19, R10
	XORL  R10, R9
	ANDL  $0x00000010, R9
	SUBL  $0x00000010, R9
	ORL   $0xedffffff, R9
	ANDL  R9, R8

f31:
	// if (mask & (DV_II_50_0_bit | DV_II_52_0_bit)) != 0 {
	// 	mask &= ((((W[54] ^ (W[57] >> 25)) & (1 << 4)) - (1 << 4)) | ^(DV_II_50_0_bit | DV_II_52_0_bit))
	// }
	TESTL $0x08800000, R8
	JE    f32
	MOVL  m1-((54*4)+64)(SP), R9
	MOVL  m1-((57*4)+64)(SP), R10
	SHRL  $0x19, R10
	XORL  R10, R9
	ANDL  $0x00000010, R9
	SUBL  $0x00000010, R9
	ORL   $0xf77fffff, R9
	ANDL  R9, R8

f32:
	// if (mask & (DV_II_49_0_bit | DV_II_51_0_bit)) != 0 {
	// 	mask &= ((((W[53] ^ (W[56] >> 25)) & (1 << 4)) - (1 << 4)) | ^(DV_II_49_0_bit | DV_II_51_0_bit))
	// }
	TESTL $0x02200000, R8
	JE    f33
	MOVL  m1-((53*4)+64)(SP), R9
	MOVL  m1-((56*4)+64)(SP), R10
	SHRL  $0x19, R10
	XORL  R10, R9
	ANDL  $0x00000010, R9
	SUBL  $0x00000010, R9
	ORL   $0xfddfffff, R9
	ANDL  R9, R8

f33:
	// mask &= ((((W[51] ^ (W[50] >> 5)) & (1 << 1)) - (1 << 1)) | ^(DV_I_50_2_bit | DV_II_46_2_bit))
	MOVL m1-((51*4)+64)(SP), R9
	MOVL m1-((50*4)+64)(SP), R10
	SHRL $0x05, R10
	XORL R10, R9
	ANDL $0x00000002, R9
	SUBL $0x00000002, R9
	ORL  $0xfffbefff, R9
	ANDL R9, R8

	// mask &= ((((W[48] ^ W[50]) & (1 << 6)) - (1 << 6)) | ^(DV_I_50_2_bit | DV_II_46_2_bit))
	MOVL m1-((48*4)+64)(SP), R9
	MOVL m1-((50*4)+64)(SP), R10
	XORL R10, R9
	ANDL $0x00000040, R9
	SUBL $0x00000040, R9
	ORL  $0xfffbefff, R9
	ANDL R9, R8

	// if (mask & (DV_I_51_0_bit | DV_I_52_0_bit)) != 0 {
	// 	mask &= ((0 - (((W[48] ^ W[55]) >> 29) & 1)) | ^(DV_I_51_0_bit | DV_I_52_0_bit))
	// }
	TESTL $0x0000a000, R8
	JE    f34
	MOVL  m1-((48*4)+64)(SP), R9
	MOVL  m1-((55*4)+64)(SP), R10
	XORL  R10, R9
	SHRL  $0x1d, R9
	ANDL  $0x00000001, R9
	NEGL  R9
	ORL   $0xffff5fff, R9
	ANDL  R9, R8

f34:
	// mask &= ((((W[47] ^ W[49]) & (1 << 6)) - (1 << 6)) | ^(DV_I_49_2_bit | DV_I_51_2_bit))
	MOVL m1-((47*4)+64)(SP), R9
	MOVL m1-((49*4)+64)(SP), R10
	XORL R10, R9
	ANDL $0x00000040, R9
	SUBL $0x00000040, R9
	ORL  $0xffffbbff, R9
	ANDL R9, R8

	// mask &= ((((W[48] ^ (W[47] >> 5)) & (1 << 1)) - (1 << 1)) | ^(DV_I_47_2_bit | DV_II_51_2_bit))
	MOVL m1-((48*4)+64)(SP), R9
	MOVL m1-((47*4)+64)(SP), R10
	SHRL $0x05, R10
	XORL R10, R9
	ANDL $0x00000002, R9
	SUBL $0x00000002, R9
	ORL  $0xfbffffbf, R9
	ANDL R9, R8

	// mask &= ((((W[46] ^ W[48]) & (1 << 6)) - (1 << 6)) | ^(DV_I_48_2_bit | DV_I_50_2_bit))
	MOVL m1-((46*4)+64)(SP), R9
	MOVL m1-((48*4)+64)(SP), R10
	XORL R10, R9
	ANDL $0x00000040, R9
	SUBL $0x00000040, R9
	ORL  $0xffffeeff, R9
	ANDL R9, R8

	// mask &= ((((W[47] ^ (W[46] >> 5)) & (1 << 1)) - (1 << 1)) | ^(DV_I_46_2_bit | DV_II_50_2_bit))
	MOVL m1-((47*4)+64)(SP), R9
	MOVL m1-((46*4)+64)(SP), R10
	SHRL $0x05, R10
	XORL R10, R9
	ANDL $0x00000002, R9
	SUBL $0x00000002, R9
	ORL  $0xfeffffef, R9
	ANDL R9, R8

	// mask &= ((0 - ((W[44] ^ (W[45] >> 5)) & (1 << 1))) | ^(DV_I_51_2_bit | DV_II_49_2_bit))
	MOVL m1-((44*4)+64)(SP), R9
	MOVL m1-((45*4)+64)(SP), R10
	SHRL $0x05, R10
	XORL R10, R9
	ANDL $0x00000002, R9
	NEGL R9
	ORL  $0xffbfbfff, R9
	ANDL R9, R8

	// mask &= ((((W[43] ^ W[45]) & (1 << 6)) - (1 << 6)) | ^(DV_I_47_2_bit | DV_I_49_2_bit))
	MOVL m1-((43*4)+64)(SP), R9
	MOVL m1-((45*4)+64)(SP), R10
	XORL R10, R9
	ANDL $0x00000040, R9
	SUBL $0x00000040, R9
	ORL  $0xfffffbbf, R9
	ANDL R9, R8

	// mask &= (((((W[42] ^ W[44]) >> 6) & 1) - 1) | ^(DV_I_46_2_bit | DV_I_48_2_bit))
	MOVL m1-((42*4)+64)(SP), R9
	MOVL m1-((44*4)+64)(SP), R10
	XORL R10, R9
	SHRL $0x06, R9
	ANDL $0x00000001, R9
	SUBL $0x00000001, R9
	ORL  $0xfffffeef, R9
	ANDL R9, R8

	// mask &= ((((W[43] ^ (W[42] >> 5)) & (1 << 1)) - (1 << 1)) | ^(DV_II_46_2_bit | DV_II_51_2_bit))
	MOVL m1-((43*4)+64)(SP), R9
	MOVL m1-((42*4)+64)(SP), R10
	SHRL $0x05, R10
	XORL R10, R9
	ANDL $0x00000002, R9
	SUBL $0x00000002, R9
	ORL  $0xfbfbffff, R9
	ANDL R9, R8

	// mask &= ((((W[42] ^ (W[41] >> 5)) & (1 << 1)) - (1 << 1)) | ^(DV_I_51_2_bit | DV_II_50_2_bit))
	MOVL m1-((42*4)+64)(SP), R9
	MOVL m1-((41*4)+64)(SP), R10
	SHRL $0x05, R10
	XORL R10, R9
	ANDL $0x00000002, R9
	SUBL $0x00000002, R9
	ORL  $0xfeffbfff, R9
	ANDL R9, R8

	// mask &= ((((W[41] ^ (W[40] >> 5)) & (1 << 1)) - (1 << 1)) | ^(DV_I_50_2_bit | DV_II_49_2_bit))
	MOVL m1-((41*4)+64)(SP), R9
	MOVL m1-((40*4)+64)(SP), R10
	SHRL $0x05, R10
	XORL R10, R9
	ANDL $0x00000002, R9
	SUBL $0x00000002, R9
	ORL  $0xffbfefff, R9
	ANDL R9, R8

	// if (mask & (DV_I_52_0_bit | DV_II_51_0_bit)) != 0 {
	// 	mask &= ((((W[39] ^ (W[43] >> 25)) & (1 << 4)) - (1 << 4)) | ^(DV_I_52_0_bit | DV_II_51_0_bit))
	// }
	TESTL $0x02008000, R8
	JE    f35
	MOVL  m1-((39*4)+64)(SP), R9
	MOVL  m1-((43*4)+64)(SP), R10
	SHRL  $0x19, R10
	XORL  R10, R9
	ANDL  $0x00000010, R9
	SUBL  $0x00000010, R9
	ORL   $0xfdff7fff, R9
	ANDL  R9, R8

f35:
	// if (mask & (DV_I_51_0_bit | DV_II_50_0_bit)) != 0 {
	// 	mask &= ((((W[38] ^ (W[42] >> 25)) & (1 << 4)) - (1 << 4)) | ^(DV_I_51_0_bit | DV_II_50_0_bit))
	// }
	TESTL $0x00802000, R8
	JE    f36
	MOVL  m1-((38*4)+64)(SP), R9
	MOVL  m1-((42*4)+64)(SP), R10
	SHRL  $0x19, R10
	XORL  R10, R9
	ANDL  $0x00000010, R9
	SUBL  $0x00000010, R9
	ORL   $0xff7fdfff, R9
	ANDL  R9, R8

f36:
	// if (mask & (DV_I_48_2_bit | DV_I_51_2_bit)) != 0 {
	// 	mask &= ((0 - ((W[37] ^ (W[38] >> 5)) & (1 << 1))) | ^(DV_I_48_2_bit | DV_I_51_2_bit))
	// }
	TESTL $0x00004100, R8
	JE    f37
	MOVL  m1-((37*4)+64)(SP), R9
	MOVL  m1-((38*4)+64)(SP), R10
	SHRL  $0x05, R10
	XORL  R10, R9
	ANDL  $0x00000002, R9
	NEGL  R9
	ORL   $0xffffbeff, R9
	ANDL  R9, R8

f37:
	// if (mask & (DV_I_50_0_bit | DV_II_49_0_bit)) != 0 {
	// 	mask &= ((((W[37] ^ (W[41] >> 25)) & (1 << 4)) - (1 << 4)) | ^(DV_I_50_0_bit | DV_II_49_0_bit))
	// }
	TESTL $0x00200800, R8
	JE    f38
	MOVL  m1-((37*4)+64)(SP), R9
	MOVL  m1-((41*4)+64)(SP), R10
	SHRL  $0x19, R10
	XORL  R10, R9
	ANDL  $0x00000010, R9
	SUBL  $0x00000010, R9
	ORL   $0xffdff7ff, R9
	ANDL  R9, R8

f38:
	// if (mask & (DV_II_52_0_bit | DV_II_54_0_bit)) != 0 {
	// 	mask &= ((0 - ((W[36] ^ W[38]) & (1 << 4))) | ^(DV_II_52_0_bit | DV_II_54_0_bit))
	// }
	TESTL $0x28000000, R8
	JE    f39
	MOVL  m1-((36*4)+64)(SP), R9
	MOVL  m1-((38*4)+64)(SP), R10
	XORL  R10, R9
	ANDL  $0x00000010, R9
	NEGL  R9
	ORL   $0xd7ffffff, R9
	ANDL  R9, R8

f39:
	// mask &= ((0 - ((W[35] ^ (W[36] >> 5)) & (1 << 1))) | ^(DV_I_46_2_bit | DV_I_49_2_bit))
	MOVL m1-((35*4)+64)(SP), R9
	MOVL m1-((36*4)+64)(SP), R10
	SHRL $0x05, R10
	XORL R10, R9
	ANDL $0x00000002, R9
	NEGL R9
	ORL  $0xfffffbef, R9
	ANDL R9, R8

	// if (mask & (DV_I_51_0_bit | DV_II_47_0_bit)) != 0 {
	// 	mask &= ((((W[35] ^ (W[39] >> 25)) & (1 << 3)) - (1 << 3)) | ^(DV_I_51_0_bit | DV_II_47_0_bit))
	// }
	TESTL $0x00082000, R8
	JE    f40
	MOVL  m1-((35*4)+64)(SP), R9
	MOVL  m1-((39*4)+64)(SP), R10
	SHRL  $0x19, R10
	XORL  R10, R9
	ANDL  $0x00000008, R9
	SUBL  $0x00000008, R9
	ORL   $0xfff7dfff, R9
	ANDL  R9, R8

f40:
	// if mask != 0
	TESTL $0x00000000, R8
	JNE   f64_skip

	// if (mask & DV_I_43_0_bit) != 0 {
	// 	if not((W[61]^(W[62]>>5))&(1<<1)) != 0 ||
	// 		not(not((W[59]^(W[63]>>25))&(1<<5))) != 0 ||
	// 		not((W[58]^(W[63]>>30))&(1<<0)) != 0 {
	// 		mask &= ^DV_I_43_0_bit
	// 	}
	// }
	BTL  $0x00, R8
	JNC  f41_skip
	MOVL m1-((61*4)+64)(SP), R9
	MOVL m1-((62*4)+64)(SP), R10
	SHRL $0x05, R10
	XORL R10, R9
	ANDL $0x00000002, R9
	NEGL R9
	CMPL R9, $0x00000000
	JE   f41_in
	MOVL m1-((59*4)+64)(SP), R9
	MOVL m1-((63*4)+64)(SP), R10
	SHRL $0x19, R10
	XORL R10, R9
	ANDL $0x00000020, R9
	CMPL R9, $0x00000000
	JNE  f41_in
	MOVL m1-((58*4)+64)(SP), R9
	MOVL m1-((63*4)+64)(SP), R10
	SHRL $0x1e, R10
	XORL R10, R9
	ANDL $0x00000001, R9
	NEGL R9
	CMPL R9, $0x00000000
	JE   f41_in
	JMP  f41_skip

f41_in:
	ANDL $0xfffffffe, R8

f41_skip:
	// if (mask & DV_I_44_0_bit) != 0 {
	// 	if not((W[62]^(W[63]>>5))&(1<<1)) != 0 ||
	// 		not(not((W[60]^(W[64]>>25))&(1<<5))) != 0 ||
	// 		not((W[59]^(W[64]>>30))&(1<<0)) != 0 {
	// 		mask &= ^DV_I_44_0_bit
	// 	}
	// }
	BTL  $0x01, R8
	JNC  f42_skip
	MOVL m1-((62*4)+64)(SP), R9
	MOVL m1-((63*4)+64)(SP), R10
	SHRL $0x05, R10
	XORL R10, R9
	ANDL $0x00000002, R9
	NEGL R9
	CMPL R9, $0x00000000
	JE   f42_in
	MOVL m1-((60*4)+64)(SP), R9
	MOVL m1-((64*4)+64)(SP), R10
	SHRL $0x19, R10
	XORL R10, R9
	ANDL $0x00000020, R9
	CMPL R9, $0x00000000
	JNE  f42_in
	MOVL m1-((59*4)+64)(SP), R9
	MOVL m1-((64*4)+64)(SP), R10
	SHRL $0x1e, R10
	XORL R10, R9
	ANDL $0x00000001, R9
	NEGL R9
	CMPL R9, $0x00000000
	JE   f42_in
	JMP  f42_skip

f42_in:
	ANDL $0xfffffffd, R8

f42_skip:
	// if (mask & DV_I_46_2_bit) != 0 {
	// 	mask &= ((^((W[40] ^ W[42]) >> 2)) | ^DV_I_46_2_bit)
	// }
	BTL  $0x04, R8
	JNC  f43
	MOVL m1-((40*4)+64)(SP), R9
	MOVL m1-((42*4)+64)(SP), R10
	XORL R10, R9
	SHRL $0x02, R9
	NOTL R9
	ORL  $0xffffffef, R9
	ANDL R9, R8

f43:
	// if (mask & DV_I_47_2_bit) != 0 {
	// 	if not((W[62]^(W[63]>>5))&(1<<2)) != 0 ||
	// 		not(not((W[41]^W[43])&(1<<6))) != 0 {
	// 		mask &= ^DV_I_47_2_bit
	// 	}
	// }
	BTL  $0x06, R8
	JNC  f44_skip
	MOVL m1-((62*4)+64)(SP), R9
	MOVL m1-((63*4)+64)(SP), R10
	SHRL $0x05, R10
	XORL R10, R9
	ANDL $0x00000004, R9
	NEGL R9
	CMPL R9, $0x00000000
	JE   f44_in
	MOVL m1-((41*4)+64)(SP), R9
	MOVL m1-((43*4)+64)(SP), R10
	XORL R10, R9
	ANDL $0x00000040, R9
	CMPL R9, $0x00000000
	JNE  f44_in
	JMP  f44_skip

f44_in:
	ANDL $0xffffffbf, R8

f44_skip:
	// if (mask & DV_I_48_2_bit) != 0 {
	// 	if not((W[63]^(W[64]>>5))&(1<<2)) != 0 ||
	// 		not(not((W[48]^(W[49]<<5))&(1<<6))) != 0 {
	// 		mask &= ^DV_I_48_2_bit
	// 	}
	// }
	BTL  $0x08, R8
	JNC  f45_skip
	MOVL m1-((63*4)+64)(SP), R9
	MOVL m1-((64*4)+64)(SP), R10
	SHRL $0x05, R10
	XORL R10, R9
	ANDL $0x00000004, R9
	NEGL R9
	CMPL R9, $0x00000000
	JE   f45_in
	MOVL m1-((48*4)+64)(SP), R9
	MOVL m1-((49*4)+64)(SP), R10
	SHLL $0x05, R10
	XORL R10, R9
	ANDL $0x00000040, R9
	CMPL R9, $0x00000000
	JNE  f45_in
	JMP  f45_skip

f45_in:
	ANDL $0xfffffeff, R8

f45_skip:
	// if (mask & DV_I_49_2_bit) != 0 {
	// 	if not(not((W[49]^(W[50]<<5))&(1<<6))) != 0 ||
	// 		not((W[42]^W[50])&(1<<1)) != 0 ||
	// 		not(not((W[39]^(W[40]<<5))&(1<<6))) != 0 ||
	// 		not((W[38]^W[40])&(1<<1)) != 0 {
	// 		mask &= ^DV_I_49_2_bit
	// 	}
	// }
	BTL  $0x0a, R8
	JNC  f46_skip
	MOVL m1-((49*4)+64)(SP), R9
	MOVL m1-((50*4)+64)(SP), R10
	SHLL $0x05, R10
	XORL R10, R9
	ANDL $0x00000040, R9
	CMPL R9, $0x00000000
	JNE  f46_in
	MOVL m1-((42*4)+64)(SP), R9
	MOVL m1-((50*4)+64)(SP), R10
	XORL R10, R9
	ANDL $0x00000002, R9
	CMPL R9, $0x00000000
	JE   f46_in
	MOVL m1-((39*4)+64)(SP), R9
	MOVL m1-((40*4)+64)(SP), R10
	SHLL $0x05, R10
	XORL R10, R9
	ANDL $0x00000040, R9
	CMPL R9, $0x00000000
	JNE  f46_in
	MOVL m1-((38*4)+64)(SP), R9
	MOVL m1-((40*4)+64)(SP), R10
	XORL R10, R9
	ANDL $0x00000002, R9
	CMPL R9, $0x00000000
	JE   f46_in
	JMP  f46_skip

f46_in:
	ANDL $0xfffffbff, R8

f46_skip:
	// if (mask & DV_I_50_0_bit) != 0 {
	// 	mask &= (((W[36] ^ W[37]) << 7) | ^DV_I_50_0_bit)
	// }
	BTL  $0x0b, R8
	JNC  f47
	MOVL m1-((36*4)+64)(SP), R9
	MOVL m1-((37*4)+64)(SP), R10
	XORL R10, R9
	SHLL $0x07, R9
	ORL  $0xfffff7ff, R9
	ANDL R9, R8

f47:
	// if (mask & DV_I_50_2_bit) != 0 {
	// 	mask &= (((W[43] ^ W[51]) << 11) | ^DV_I_50_2_bit)
	// }
	BTL  $0x0c, R8
	JNC  f48
	MOVL m1-((43*4)+64)(SP), R9
	MOVL m1-((51*4)+64)(SP), R10
	XORL R10, R9
	SHLL $0x0b, R9
	ORL  $0xffffefff, R9
	ANDL R9, R8

f48:
	// if (mask & DV_I_51_0_bit) != 0 {
	// 	mask &= (((W[37] ^ W[38]) << 9) | ^DV_I_51_0_bit)
	// }
	BTL  $0x0d, R8
	JNC  f49
	MOVL m1-((37*4)+64)(SP), R9
	MOVL m1-((38*4)+64)(SP), R10
	XORL R10, R9
	SHLL $0x09, R9
	ORL  $0xffffdfff, R9
	ANDL R9, R8

f49:
	// if (mask & DV_I_51_2_bit) != 0 {
	// 	if not(not((W[51]^(W[52]<<5))&(1<<6))) != 0 ||
	// 		not(not((W[49]^W[51])&(1<<6))) != 0 ||
	// 		not(not((W[37]^(W[37]>>5))&(1<<1))) != 0 ||
	// 		not(not((W[35]^(W[39]>>25))&(1<<5))) != 0 {
	// 		mask &= ^DV_I_51_2_bit
	// 	}
	// }
	BTL  $0x0e, R8
	JNC  f50_skip
	MOVL m1-((51*4)+64)(SP), R9
	MOVL m1-((52*4)+64)(SP), R10
	SHLL $0x05, R10
	XORL R10, R9
	ANDL $0x00000040, R9
	CMPL R9, $0x00000000
	JNE  f50_in
	MOVL m1-((49*4)+64)(SP), R9
	MOVL m1-((51*4)+64)(SP), R10
	XORL R10, R9
	ANDL $0x00000040, R9
	CMPL R9, $0x00000000
	JNE  f50_in
	MOVL m1-((37*4)+64)(SP), R9
	MOVL m1-((37*4)+64)(SP), R10
	SHRL $0x05, R10
	XORL R10, R9
	ANDL $0x00000002, R9
	CMPL R9, $0x00000000
	JNE  f50_in
	MOVL m1-((35*4)+64)(SP), R9
	MOVL m1-((39*4)+64)(SP), R10
	SHRL $0x19, R10
	XORL R10, R9
	ANDL $0x00000020, R9
	CMPL R9, $0x00000000
	JNE  f50_in
	JMP  f50_skip

f50_in:
	ANDL $0xffffbfff, R8

f50_skip:
	// if (mask & DV_I_52_0_bit) != 0 {
	// 	mask &= (((W[38] ^ W[39]) << 11) | ^DV_I_52_0_bit)
	// }
	BTL  $0x0f, R8
	JNC  f51
	MOVL m1-((38*4)+64)(SP), R9
	MOVL m1-((39*4)+64)(SP), R10
	XORL R10, R9
	SHLL $0x0b, R9
	ORL  $0xffff7fff, R9
	ANDL R9, R8

f51:
	// if (mask & DV_II_46_2_bit) != 0 {
	// 	mask &= (((W[47] ^ W[51]) << 17) | ^DV_II_46_2_bit)
	// }
	TESTL $0x00040000, R8
	BTL   $0x12, R8
	JNC   f52
	MOVL  m1-((47*4)+64)(SP), R9
	MOVL  m1-((51*4)+64)(SP), R10
	XORL  R10, R9
	SHLL  $0x11, R9
	ORL   $0xfffbffff, R9
	ANDL  R9, R8

f52:
	// if (mask & DV_II_48_0_bit) != 0 {
	// 	if not(not((W[36]^(W[40]>>25))&(1<<3))) != 0 ||
	// 		not((W[35]^(W[40]<<2))&(1<<30)) != 0 {
	// 		mask &= ^DV_II_48_0_bit
	// 	}
	// }
	BTL  $0x14, R8
	JNC  f53_skip
	MOVL m1-((36*4)+64)(SP), R9
	MOVL m1-((40*4)+64)(SP), R10
	SHRL $0x19, R10
	XORL R10, R9
	ANDL $0x00000008, R9
	CMPL R9, $0x00000000
	JNE  f53_in
	MOVL m1-((35*4)+64)(SP), R9
	MOVL m1-((40*4)+64)(SP), R10
	SHLL $0x02, R10
	XORL R10, R9
	ANDL $0x40000000, R9
	CMPL R9, $0x00000000
	JNE  f53_in
	JMP  f53_skip

f53_in:
	ANDL $0xffefffff, R8

f53_skip:
	// if (mask & DV_II_49_0_bit) != 0 {
	// 	if not(not((W[37]^(W[41]>>25))&(1<<3))) != 0 ||
	// 		not((W[36]^(W[41]<<2))&(1<<30)) != 0 {
	// 		mask &= ^DV_II_49_0_bit
	// 	}
	// }
	BTL  $0x15, R8
	JNC  f54_skip
	MOVL m1-((37*4)+64)(SP), R9
	MOVL m1-((41*4)+64)(SP), R10
	SHRL $0x19, R10
	XORL R10, R9
	ANDL $0x00000008, R9
	CMPL R9, $0x00000000
	JNE  f54_in
	MOVL m1-((36*4)+64)(SP), R9
	MOVL m1-((41*4)+64)(SP), R10
	SHLL $0x02, R10
	XORL R10, R9
	ANDL $0x40000000, R9
	CMPL R9, $0x00000000
	JNE  f54_in
	JMP  f54_skip

f54_in:
	ANDL $0xffdfffff, R8

f54_skip:
	// if (mask & DV_II_49_2_bit) != 0 {
	// 	if not(not((W[53]^(W[54]<<5))&(1<<6))) != 0 ||
	// 		not(not((W[51]^W[53])&(1<<6))) != 0 ||
	// 		not((W[50]^W[54])&(1<<1)) != 0 ||
	// 		not(not((W[45]^(W[46]<<5))&(1<<6))) != 0 ||
	// 		not(not((W[37]^(W[41]>>25))&(1<<5))) != 0 ||
	// 		not((W[36]^(W[41]>>30))&(1<<0)) != 0 {
	// 		mask &= ^DV_II_49_2_bit
	// 	}
	// }
	BTL  $0x16, R8
	JNC  f55_skip
	MOVL m1-((53*4)+64)(SP), R9
	MOVL m1-((54*4)+64)(SP), R10
	SHLL $0x05, R10
	XORL R10, R9
	ANDL $0x00000040, R9
	CMPL R9, $0x00000000
	JNE  f55_in
	MOVL m1-((51*4)+64)(SP), R9
	MOVL m1-((53*4)+64)(SP), R10
	XORL R10, R9
	ANDL $0x00000040, R9
	CMPL R9, $0x00000000
	JNE  f55_in
	MOVL m1-((50*4)+64)(SP), R9
	MOVL m1-((54*4)+64)(SP), R10
	XORL R10, R9
	ANDL $0x00000002, R9
	NEGL R9
	CMPL R9, $0x00000000
	JE   f55_in
	MOVL m1-((45*4)+64)(SP), R9
	MOVL m1-((46*4)+64)(SP), R10
	SHLL $0x05, R10
	XORL R10, R9
	ANDL $0x00000040, R9
	CMPL R9, $0x00000000
	JNE  f55_in
	MOVL m1-((37*4)+64)(SP), R9
	MOVL m1-((41*4)+64)(SP), R10
	SHRL $0x19, R10
	XORL R10, R9
	ANDL $0x00000020, R9
	CMPL R9, $0x00000000
	JNE  f55_in
	MOVL m1-((36*4)+64)(SP), R9
	MOVL m1-((41*4)+64)(SP), R10
	SHRL $0x1e, R10
	XORL R10, R9
	ANDL $0x00000001, R9
	NEGL R9
	CMPL R9, $0x00000000
	JE   f55_in
	JMP  f55_skip

f55_in:
	ANDL $0xffbfffff, R8

f55_skip:
	// if (mask & DV_II_50_0_bit) != 0 {
	// 	if not((W[55]^W[58])&(1<<29)) != 0 ||
	// 		not(not((W[38]^(W[42]>>25))&(1<<3))) != 0 ||
	// 		not((W[37]^(W[42]<<2))&(1<<30)) != 0 {
	// 		mask &= ^DV_II_50_0_bit
	// 	}
	// }
	BTL  $0x17, R8
	JNC  f56_skip
	MOVL m1-((55*4)+64)(SP), R9
	MOVL m1-((58*4)+64)(SP), R10
	XORL R10, R9
	ANDL $0x20000000, R9
	NEGL R9
	CMPL R9, $0x00000000
	JE   f56_in
	MOVL m1-((38*4)+64)(SP), R9
	MOVL m1-((42*4)+64)(SP), R10
	SHRL $0x19, R10
	XORL R10, R9
	ANDL $0x00000008, R9
	CMPL R9, $0x00000000
	JNE  f56_in
	MOVL m1-((37*4)+64)(SP), R9
	MOVL m1-((42*4)+64)(SP), R10
	SHRL $0x02, R10
	XORL R10, R9
	ANDL $0x40000000, R9
	NEGL R9
	CMPL R9, $0x00000000
	JE   f56_in
	JMP  f56_skip

f56_in:
	ANDL $0xff7fffff, R8

f56_skip:
	// if (mask & DV_II_50_2_bit) != 0 {
	// 	if not(not((W[54]^(W[55]<<5))&(1<<6))) != 0 ||
	// 		not(not((W[52]^W[54])&(1<<6))) != 0 ||
	// 		not((W[51]^W[55])&(1<<1)) != 0 ||
	// 		not((W[45]^W[47])&(1<<1)) != 0 ||
	// 		not(not((W[38]^(W[42]>>25))&(1<<5))) != 0 ||
	// 		not((W[37]^(W[42]>>30))&(1<<0)) != 0 {
	// 		mask &= ^DV_II_50_2_bit
	// 	}
	// }
	BTL  $0x18, R8
	JNC  f57_skip
	MOVL m1-((54*4)+64)(SP), R9
	MOVL m1-((55*4)+64)(SP), R10
	SHLL $0x05, R10
	XORL R10, R9
	ANDL $0x00000040, R9
	CMPL R9, $0x00000000
	JNE  f57_in
	MOVL m1-((52*4)+64)(SP), R9
	MOVL m1-((54*4)+64)(SP), R10
	XORL R10, R9
	ANDL $0x00000040, R9
	CMPL R9, $0x00000000
	JNE  f57_in
	MOVL m1-((51*4)+64)(SP), R9
	MOVL m1-((55*4)+64)(SP), R10
	XORL R10, R9
	ANDL $0x00000002, R9
	NEGL R9
	CMPL R9, $0x00000000
	JE   f57_in
	MOVL m1-((45*4)+64)(SP), R9
	MOVL m1-((47*4)+64)(SP), R10
	XORL R10, R9
	ANDL $0x00000002, R9
	NEGL R9
	CMPL R9, $0x00000000
	JE   f57_in
	MOVL m1-((38*4)+64)(SP), R9
	MOVL m1-((42*4)+64)(SP), R10
	SHRL $0x19, R10
	XORL R10, R9
	ANDL $0x00000020, R9
	CMPL R9, $0x00000000
	JNE  f57_in
	MOVL m1-((37*4)+64)(SP), R9
	MOVL m1-((42*4)+64)(SP), R10
	SHRL $0x1e, R10
	XORL R10, R9
	ANDL $0x00000001, R9
	NEGL R9
	CMPL R9, $0x00000000
	JE   f57_in
	JMP  f57_skip

f57_in:
	ANDL $0xfeffffff, R8

f57_skip:
	// if (mask & DV_II_51_0_bit) != 0 {
	// 	if not(not((W[39]^(W[43]>>25))&(1<<3))) != 0 ||
	// 		not((W[38]^(W[43]<<2))&(1<<30)) != 0 {
	// 		mask &= ^DV_II_51_0_bit
	// 	}
	// }
	BTL  $0x19, R8
	JNC  f58_skip
	MOVL m1-((39*4)+64)(SP), R9
	MOVL m1-((43*4)+64)(SP), R10
	SHRL $0x19, R10
	XORL R10, R9
	ANDL $0x00000008, R9
	CMPL R9, $0x00000000
	JNE  f58_in
	MOVL m1-((38*4)+64)(SP), R9
	MOVL m1-((43*4)+64)(SP), R10
	SHLL $0x02, R10
	XORL R10, R9
	ANDL $0x40000000, R9
	NEGL R9
	CMPL R9, $0x00000000
	JE   f58_in
	JMP  f58_skip

f58_in:
	ANDL $0xfdffffff, R8

f58_skip:
	// if (mask & DV_II_51_2_bit) != 0 {
	// 	if not(not((W[55]^(W[56]<<5))&(1<<6))) != 0 ||
	// 		not(not((W[53]^W[55])&(1<<6))) != 0 ||
	// 		not((W[52]^W[56])&(1<<1)) != 0 ||
	// 		not((W[46]^W[48])&(1<<1)) != 0 ||
	// 		not(not((W[39]^(W[43]>>25))&(1<<5))) != 0 ||
	// 		not((W[38]^(W[43]>>30))&(1<<0)) != 0 {
	// 		mask &= ^DV_II_51_2_bit
	// 	}
	// }
	BTL  $0x1a, R8
	JNC  f59_skip
	MOVL m1-((55*4)+64)(SP), R9
	MOVL m1-((56*4)+64)(SP), R10
	SHLL $0x05, R10
	XORL R10, R9
	ANDL $0x00000040, R9
	CMPL R9, $0x00000000
	JNE  f59_in
	MOVL m1-((53*4)+64)(SP), R9
	MOVL m1-((55*4)+64)(SP), R10
	XORL R10, R9
	ANDL $0x00000040, R9
	CMPL R9, $0x00000000
	JNE  f59_in
	MOVL m1-((52*4)+64)(SP), R9
	MOVL m1-((56*4)+64)(SP), R10
	XORL R10, R9
	ANDL $0x00000002, R9
	NEGL R9
	CMPL R9, $0x00000000
	JE   f59_in
	MOVL m1-((46*4)+64)(SP), R9
	MOVL m1-((48*4)+64)(SP), R10
	XORL R10, R9
	ANDL $0x00000002, R9
	NEGL R9
	CMPL R9, $0x00000000
	JE   f59_in
	MOVL m1-((39*4)+64)(SP), R9
	MOVL m1-((43*4)+64)(SP), R10
	SHRL $0x19, R10
	XORL R10, R9
	ANDL $0x00000020, R9
	CMPL R9, $0x00000000
	JNE  f59_in
	MOVL m1-((38*4)+64)(SP), R9
	MOVL m1-((43*4)+64)(SP), R10
	SHRL $0x1e, R10
	XORL R10, R9
	ANDL $0x00000001, R9
	NEGL R9
	CMPL R9, $0x00000000
	JE   f59_in
	JMP  f59_skip

f59_in:
	ANDL $0xfbffffff, R8

f59_skip:
	// if (mask & DV_II_52_0_bit) != 0 {
	// 	if not(not((W[59]^W[60])&(1<<29))) != 0 ||
	// 		not(not((W[40]^(W[44]>>25))&(1<<3))) != 0 ||
	// 		not(not((W[40]^(W[44]>>25))&(1<<4))) != 0 ||
	// 		not((W[39]^(W[44]<<2))&(1<<30)) != 0 {
	// 		mask &= ^DV_II_52_0_bit
	// 	}
	// }
	BTL  $0x1b, R8
	JNC  f60_skip
	MOVL m1-((59*4)+64)(SP), R9
	MOVL m1-((60*4)+64)(SP), R10
	XORL R10, R9
	ANDL $0x20000000, R9
	CMPL R9, $0x00000000
	JNE  f60_in
	MOVL m1-((40*4)+64)(SP), R9
	MOVL m1-((44*4)+64)(SP), R10
	SHRL $0x19, R10
	XORL R10, R9
	ANDL $0x00000008, R9
	CMPL R9, $0x00000000
	JNE  f60_in
	MOVL m1-((40*4)+64)(SP), R9
	MOVL m1-((44*4)+64)(SP), R10
	SHRL $0x19, R10
	XORL R10, R9
	ANDL $0x00000010, R9
	CMPL R9, $0x00000000
	JNE  f60_in
	MOVL m1-((39*4)+64)(SP), R9
	MOVL m1-((44*4)+64)(SP), R10
	SHLL $0x02, R10
	XORL R10, R9
	ANDL $0x40000000, R9
	NEGL R9
	CMPL R9, $0x00000000
	JE   f60_in
	JMP  f60_skip

f60_in:
	ANDL $0xf7ffffff, R8

f60_skip:
	// if (mask & DV_II_53_0_bit) != 0 {
	// 	if not((W[58]^W[61])&(1<<29)) != 0 ||
	// 		not(not((W[57]^(W[61]>>25))&(1<<4))) != 0 ||
	// 		not(not((W[41]^(W[45]>>25))&(1<<3))) != 0 ||
	// 		not(not((W[41]^(W[45]>>25))&(1<<4))) != 0 {
	// 		mask &= ^DV_II_53_0_bit
	// 	}
	// }
	BTL  $0x1c, R8
	JNC  f61_skip
	MOVL m1-((58*4)+64)(SP), R9
	MOVL m1-((61*4)+64)(SP), R10
	XORL R10, R9
	ANDL $0x20000000, R9
	NEGL R9
	CMPL R9, $0x00000000
	JE   f61_in
	MOVL m1-((57*4)+64)(SP), R9
	MOVL m1-((61*4)+64)(SP), R10
	SHRL $0x19, R10
	XORL R10, R9
	ANDL $0x00000010, R9
	CMPL R9, $0x00000000
	JNE  f61_in
	MOVL m1-((41*4)+64)(SP), R9
	MOVL m1-((45*4)+64)(SP), R10
	SHRL $0x19, R10
	XORL R10, R9
	ANDL $0x00000008, R9
	CMPL R9, $0x00000000
	JNE  f61_in
	MOVL m1-((41*4)+64)(SP), R9
	MOVL m1-((45*4)+64)(SP), R10
	SHRL $0x19, R10
	XORL R10, R9
	ANDL $0x00000010, R9
	CMPL R9, $0x00000000
	JNE  f61_in
	JMP  f61_skip

f61_in:
	ANDL $0xefffffff, R8

f61_skip:
	// if (mask & DV_II_54_0_bit) != 0 {
	// 	if not(not((W[58]^(W[62]>>25))&(1<<4))) != 0 ||
	// 		not(not((W[42]^(W[46]>>25))&(1<<3))) != 0 ||
	// 		not(not((W[42]^(W[46]>>25))&(1<<4))) != 0 {
	// 		mask &= ^DV_II_54_0_bit
	// 	}
	// }
	BTL  $0x1d, R8
	JNC  f62_skip
	MOVL m1-((58*4)+64)(SP), R9
	MOVL m1-((62*4)+64)(SP), R10
	SHRL $0x19, R10
	XORL R10, R9
	ANDL $0x00000010, R9
	CMPL R9, $0x00000000
	JNE  f62_in
	MOVL m1-((42*4)+64)(SP), R9
	MOVL m1-((46*4)+64)(SP), R10
	SHRL $0x19, R10
	XORL R10, R9
	ANDL $0x00000008, R9
	CMPL R9, $0x00000000
	JNE  f62_in
	MOVL m1-((42*4)+64)(SP), R9
	MOVL m1-((46*4)+64)(SP), R10
	SHRL $0x19, R10
	XORL R10, R9
	ANDL $0x00000010, R9
	CMPL R9, $0x00000000
	JNE  f62_in
	JMP  f62_skip

f62_in:
	ANDL $0xdfffffff, R8

f62_skip:
	// if (mask & DV_II_55_0_bit) != 0 {
	// 	if not(not((W[59]^(W[63]>>25))&(1<<4))) != 0 ||
	// 		not(not((W[57]^(W[59]>>25))&(1<<4))) != 0 ||
	// 		not(not((W[43]^(W[47]>>25))&(1<<3))) != 0 ||
	// 		not(not((W[43]^(W[47]>>25))&(1<<4))) != 0 {
	// 		mask &= ^DV_II_55_0_bit
	// 	}
	// }
	BTL  $0x1e, R8
	JNC  f63_skip
	MOVL m1-((59*4)+64)(SP), R9
	MOVL m1-((63*4)+64)(SP), R10
	SHRL $0x19, R10
	XORL R10, R9
	ANDL $0x00000010, R9
	CMPL R9, $0x00000000
	JNE  f63_in
	MOVL m1-((57*4)+64)(SP), R9
	MOVL m1-((59*4)+64)(SP), R10
	SHRL $0x19, R10
	XORL R10, R9
	ANDL $0x00000010, R9
	CMPL R9, $0x00000000
	JNE  f63_in
	MOVL m1-((43*4)+64)(SP), R9
	MOVL m1-((47*4)+64)(SP), R10
	SHRL $0x19, R10
	XORL R10, R9
	ANDL $0x00000008, R9
	CMPL R9, $0x00000000
	JNE  f63_in
	MOVL m1-((43*4)+64)(SP), R9
	MOVL m1-((47*4)+64)(SP), R10
	SHRL $0x19, R10
	XORL R10, R9
	ANDL $0x00000010, R9
	CMPL R9, $0x00000000
	JNE  f63_in
	JMP  f63_skip

f63_in:
	ANDL $0xbfffffff, R8

f63_skip:
	// if (mask & DV_II_56_0_bit) != 0 {
	// 	if not(not((W[60]^(W[64]>>25))&(1<<4))) != 0 ||
	// 		not(not((W[44]^(W[48]>>25))&(1<<3))) != 0 ||
	// 		not(not((W[44]^(W[48]>>25))&(1<<4))) != 0 {
	// 		mask &= ^DV_II_56_0_bit
	// 	}
	// }
	BTL  $0x1f, R8
	JNC  f64_skip
	MOVL m1-((60*4)+64)(SP), R9
	MOVL m1-((64*4)+64)(SP), R10
	SHRL $0x19, R10
	XORL R10, R9
	ANDL $0x00000010, R9
	CMPL R9, $0x00000000
	JNE  f64_in
	MOVL m1-((44*4)+64)(SP), R9
	MOVL m1-((48*4)+64)(SP), R10
	SHRL $0x19, R10
	XORL R10, R9
	ANDL $0x00000008, R9
	CMPL R9, $0x00000000
	JNE  f64_in
	MOVL m1-((44*4)+64)(SP), R9
	MOVL m1-((48*4)+64)(SP), R10
	SHRL $0x19, R10
	XORL R10, R9
	ANDL $0x00000010, R9
	CMPL R9, $0x00000000
	JNE  f64_in
	JMP  f64_skip

f64_in:
	ANDL $0x7fffffff, R8 // TODO: Move direct to memory?
	
f64_skip:
	// if mask := ubc.CalculateDvMask(m1); mask != 0
	MOVL R8, mask-388(SP)

	CMPL R8, $0
	JNE checkubc

// Back to the main loop
nextblock:
	ADDQ $64, SI
	CMPQ SI, DI
	JB   loop

end:
	MOVQ dig+0(FP), DI
	MOVL AX, (DI)
	MOVL BX, 4(DI)
	MOVL CX, 8(DI)
	MOVL DX, 12(DI)
	MOVL BP, 16(DI)	
	RET

checkubc:
	// There is a total of 33 DvInfo instances in the sha1_dvs array (344 bytes each).
	MOVL $0, dvi-1992(SP)

	// TODO: the JMP below is to avoid running the checkubc code that is currently
	// not working.
	JMP nextblock

dv_loop:
	MOVL dvi-1992(SP), R8
	MOVL $344, CX	// 344 bytes per DvInfo
	MULL CX			// calculate offset for current index
	ADDQ $12, AX 	// add offset for TestT

	//  0 DvType uint32
	//  4 DvK    uint32
	//  8 DvB    uint32
	// 12 TestT  uint32
	// 16 MaskI  uint32
	// 20 MaskB  uint32
	// 24 Dm 	[80]uint32
	LEAQ sha1_dvs(SB), R8 // MaskB from current index dv

	ADDQ AX, R8
	MOVL (R8), R11 // TestT
	ADDQ $8, R8
	MOVL (R8), CX // MaskB

	// if (mask & ((uint32)(1) << uint32(dvs[i].MaskB))) != 0 {
	MOVL mask-388(SP), R10
	MOVL $1, R9
    SHLL CX, R9
	ANDL R10, R9
	CMPL R9, $0
	JE next_dv

	// Calculate the offset for the current CS.
	LEAQ cs-392(SP), R10
	MOVL R11, AX
	MOVL $20, CX	// 20 bytes per cs entry
	MULL CX			
	ADDQ AX, R10 	// add offset for MaskB

	// Load a, b, c, d, e from cs.
	MOVL (R10), AX
	MOVL 4(R10), BX
	MOVL 8(R10), CX
	MOVL 12(R10), DX
	MOVL 16(R10), BP

	// Undo compression in reverse order.

	// UNDO_ROUND4 (Steps 64-60).
	// No unavoidable bit conditions currently defined for theses above 65.
undo_from_step_65: // step > i
	UNDO_ROUND4(BX, CX, DX, BP, AX, 64)
	UNDO_ROUND4(CX, DX, BP, AX, BX, 63)
	UNDO_ROUND4(DX, BP, AX, BX, CX, 62)
	UNDO_ROUND4(BP, AX, BX, CX, DX, 61)
	UNDO_ROUND4(AX, BX, CX, DX, BP, 60)

	// UNDO_ROUND3 (Steps 59-40).
	UNDO_ROUND3(BX, CX, DX, BP, AX, 59)
	UNDO_ROUND3(CX, DX, BP, AX, BX, 58)
undo_from_step_58: // step > i
	UNDO_ROUND3(DX, BP, AX, BX, CX, 57)
	UNDO_ROUND3(BP, AX, BX, CX, DX, 56)
	UNDO_ROUND3(AX, BX, CX, DX, BP, 55)
	UNDO_ROUND3(BX, CX, DX, BP, AX, 54)
	UNDO_ROUND3(CX, DX, BP, AX, BX, 53)
	UNDO_ROUND3(DX, BP, AX, BX, CX, 52)
	UNDO_ROUND3(BP, AX, BX, CX, DX, 51)
	UNDO_ROUND3(AX, BX, CX, DX, BP, 50)
	UNDO_ROUND3(BX, CX, DX, BP, AX, 49)
	UNDO_ROUND3(CX, DX, BP, AX, BX, 48)
	UNDO_ROUND3(DX, BP, AX, BX, CX, 47)
	UNDO_ROUND3(BP, AX, BX, CX, DX, 46)
	UNDO_ROUND3(AX, BX, CX, DX, BP, 45)
	UNDO_ROUND3(BX, CX, DX, BP, AX, 44)
	UNDO_ROUND3(CX, DX, BP, AX, BX, 43)
	UNDO_ROUND3(DX, BP, AX, BX, CX, 42)
	UNDO_ROUND3(BP, AX, BX, CX, DX, 41)
	UNDO_ROUND3(AX, BX, CX, DX, BP, 40)

	// ROUND2 (Steps 39-20).
	UNDO_ROUND2(BX, CX, DX, BP, AX, 39)
	UNDO_ROUND2(CX, DX, BP, AX, BX, 38)
	UNDO_ROUND2(DX, BP, AX, BX, CX, 37)
	UNDO_ROUND2(BP, AX, BX, CX, DX, 36)
	UNDO_ROUND2(AX, BX, CX, DX, BP, 35)
	UNDO_ROUND2(BX, CX, DX, BP, AX, 34)
	UNDO_ROUND2(CX, DX, BP, AX, BX, 33)
	UNDO_ROUND2(DX, BP, AX, BX, CX, 32)
	UNDO_ROUND2(BP, AX, BX, CX, DX, 31)
	UNDO_ROUND2(AX, BX, CX, DX, BP, 30)
	UNDO_ROUND2(BX, CX, DX, BP, AX, 29)
	UNDO_ROUND2(CX, DX, BP, AX, BX, 28)
	UNDO_ROUND2(DX, BP, AX, BX, CX, 27)
	UNDO_ROUND2(BP, AX, BX, CX, DX, 26)
	UNDO_ROUND2(AX, BX, CX, DX, BP, 25)
	UNDO_ROUND2(BX, CX, DX, BP, AX, 24)
	UNDO_ROUND2(CX, DX, BP, AX, BX, 23)
	UNDO_ROUND2(DX, BP, AX, BX, CX, 22)
	UNDO_ROUND2(BP, AX, BX, CX, DX, 21)
	UNDO_ROUND2(AX, BX, CX, DX, BP, 20)

	// UNDO_ROUND1 (Steps 19-0).
	UNDO_ROUND1(BX, CX, DX, BP, AX, 19)
	UNDO_ROUND1(CX, DX, BP, AX, BX, 18)
	UNDO_ROUND1(DX, BP, AX, BX, CX, 17)
	UNDO_ROUND1(BP, AX, BX, CX, DX, 16)
	UNDO_ROUND1(AX, BX, CX, DX, BP, 15)
	UNDO_ROUND1(BX, CX, DX, BP, AX, 14)
	UNDO_ROUND1(CX, DX, BP, AX, BX, 13)
	UNDO_ROUND1(DX, BP, AX, BX, CX, 12)
	UNDO_ROUND1(BP, AX, BX, CX, DX, 11)
	UNDO_ROUND1(AX, BX, CX, DX, BP, 10)
	UNDO_ROUND1(BX, CX, DX, BP, AX, 9)
	UNDO_ROUND1(CX, DX, BP, AX, BX, 8)
	UNDO_ROUND1(DX, BP, AX, BX, CX, 7)
	UNDO_ROUND1(BP, AX, BX, CX, DX, 6)
	UNDO_ROUND1(AX, BX, CX, DX, BP, 5)
	UNDO_ROUND1(BX, CX, DX, BP, AX, 4)
	UNDO_ROUND1(CX, DX, BP, AX, BX, 3)
	UNDO_ROUND1(DX, BP, AX, BX, CX, 2)
	UNDO_ROUND1(BP, AX, BX, CX, DX, 1)
	UNDO_ROUND1(AX, BX, CX, DX, BP, 0)

	// Store a, b, c, d, e so they can later be used after recompression.
	MOVQ R11, r11-1998(SP)
	MOVQ R12, r12-2006(SP)
	MOVQ R13, r13-2014(SP)
	MOVQ R14, r14-2022(SP)
	MOVQ R15, r15-2030(SP)
	MOVL AX, R11
	MOVL BX, R12
	MOVL CX, R13
	MOVL DX, R14
	MOVL BP, R15

	//TODO: review duplicate code
	// Load a, b, c, d, e from cs.
	MOVL dvi-1992(SP), AX
	MOVL $344, CX	// 344 bytes per DvInfo
	MULL CX			// calculate offset for current index
	ADDQ $12, AX 	// add offset for TestT

	LEAQ sha1_dvs(SB), R8 // MaskB from current index dv
	ADDQ AX, R8
	MOVL (R8), R9 // TestT

	// Calculate the offset for the current CS.
	LEAQ cs-392(SP), R10
	MOVL R9, AX
	MOVL $20, CX	// 20 bytes per cs entry
	MULL CX			
	ADDQ AX, R10 	// add offset for MaskB

	// Load a, b, c, d, e from cs.
	// TODO: Use a macro for this.
	MOVL (R10), AX
	MOVL 4(R10), BX
	MOVL 8(R10), CX
	MOVL 12(R10), DX
	MOVL 16(R10), BP

// redo_from_step_58: // step <= i
	RECOMPRESS_ROUND3(CX, DX, BP, AX, BX, 58)
	RECOMPRESS_ROUND3(BX, CX, DX, BP, AX, 59)

	// RECOMPRESS_ROUND4 (Steps 60-79).
	RECOMPRESS_ROUND4(AX, BX, CX, DX, BP, 60)
	RECOMPRESS_ROUND4(BP, AX, BX, CX, DX, 61)
	RECOMPRESS_ROUND4(DX, BP, AX, BX, CX, 62)
	RECOMPRESS_ROUND4(CX, DX, BP, AX, BX, 63)
	RECOMPRESS_ROUND4(BX, CX, DX, BP, AX, 64)
redo_from_step_65: // step <= i
	RECOMPRESS_ROUND4(AX, BX, CX, DX, BP, 65)
	RECOMPRESS_ROUND4(BP, AX, BX, CX, DX, 66)
	RECOMPRESS_ROUND4(DX, BP, AX, BX, CX, 67)
	RECOMPRESS_ROUND4(CX, DX, BP, AX, BX, 68)
	RECOMPRESS_ROUND4(BX, CX, DX, BP, AX, 69)
	RECOMPRESS_ROUND4(AX, BX, CX, DX, BP, 70)
	RECOMPRESS_ROUND4(BP, AX, BX, CX, DX, 71)
	RECOMPRESS_ROUND4(DX, BP, AX, BX, CX, 72)
	RECOMPRESS_ROUND4(CX, DX, BP, AX, BX, 73)
	RECOMPRESS_ROUND4(BX, CX, DX, BP, AX, 74)
	RECOMPRESS_ROUND4(AX, BX, CX, DX, BP, 75)
	RECOMPRESS_ROUND4(BP, AX, BX, CX, DX, 76)
	RECOMPRESS_ROUND4(DX, BP, AX, BX, CX, 77)
	RECOMPRESS_ROUND4(CX, DX, BP, AX, BX, 78)
	RECOMPRESS_ROUND4(BX, CX, DX, BP, AX, 79)

	ADDL R11, AX
	ADDL R12, BX
	ADDL R13, CX
	ADDL R14, DX
	ADDL R15, BP

	MOVQ r11-1998(SP), R11
	MOVQ r12-2006(SP), R12
	MOVQ r13-2014(SP), R13
	MOVQ r14-2022(SP), R14
	MOVQ r15-2030(SP), R15

// //TODO: final check if collision has been confirmed
// if 0 == ((dig.ihvtmp[0] ^ h0) | (dig.ihvtmp[1] ^ h1) |
// (dig.ihvtmp[2] ^ h2) | (dig.ihvtmp[3] ^ h3) | (dig.ihvtmp[4] ^ h4)) {
	MOVL R11, R9
	XORL AX, R9
	MOVL R12, R8
	XORL BX, R8
	ORL R9, R8

	MOVL R13, R9
	XORL CX, R9
	ORL R8, R9

	MOVL R14, R8
	XORL DX, R8
	ORL R9, R8

	MOVL R15, R9
	XORL BP, R9
	ORL R8, R9
	CMPL R9, $0
	JNE next_dv

	// TODO: if collided, shortcircuit dv_loop and reshash block.
	// MOVQ dig+0(FP), AX
	// MOVB $1, 20+64+12+8(AX) // set collision flag, refer to digest struct.
	// JMP rehash

next_dv:
	MOVL dvi-1992(SP), R9
	INCL R9
	MOVL R9, dvi-1992(SP)
	CMPL R9, $33
	JNE dv_loop

	JMP nextblock
