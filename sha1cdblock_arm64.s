//go:build !noasm && gc && arm64 && !amd64

#include "textflag.h"

// func blockARM64(dig *digest, p []byte, m1 []uint32, cs [][5]uint32)
TEXT ·blockARM64(SB), NOSPLIT, $64-80
    MOVD    dig+0(FP), R8
    MOVD    p_base+8(FP), R16
    MOVD    p_len+16(FP), R10

    // Round down length to multiple of 64 bytes
    LSR     $6, R10, R10               // R10 >>= 6
    LSL     $6, R10, R10               // R10 <<= 6
    ADD     R16, R10, R11              // R11 = p_base + rounded_len

    // Load h0-h4 into R0–R4
    MOVW    (R8), R0                   // R0 = h0
    MOVW    4(R8), R1                  // R1 = h1
    MOVW    8(R8), R2                  // R2 = h2
    MOVW    12(R8), R3                 // R3 = h3
    MOVW    16(R8), R4                 // R4 = h4

    // len(p) >= chunk
    CMP     R16, R11
    BEQ     end

loop:
	// Initialize registers a, b, c, d, e.
	MOVW R0, R10
	MOVW R1, R11
	MOVW R2, R12
	MOVW R3, R13
	MOVW R4, R14

	// Add registers to temp hash.
	ADDW R10, R0
	ADDW R11, R1
	ADDW R12, R2
	ADDW R13, R3
	ADDW R14, R4
	ADD  $64, R16
	CMP  R16, R11
	BLO  loop

end:
	MOVD dig+0(FP), R8
	MOVW R0, (R8)
	MOVW R1, 4(R8)
	MOVW R2, 8(R8)
	MOVW R3, 12(R8)
	MOVW R4, 16(R8)
	RET
