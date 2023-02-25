//go:build ignore
// +build ignore

package main

import (
	. "github.com/mmcloughlin/avo/build"
	"github.com/mmcloughlin/avo/buildtags"
	. "github.com/mmcloughlin/avo/operand"
	. "github.com/mmcloughlin/avo/reg"
	shared "github.com/pjbgf/sha1cd/internal"
)

//go:generate go run sha1cdblock_amd64_asm.go -out sha1cdblock_amd64.s

func main() {
	Constraint(buildtags.Not("noasm").ToConstraint())
	Constraint(buildtags.Term("gc").ToConstraint())
	Constraint(buildtags.Term("amd64").ToConstraint())

	Package("github.com/pjbgf/sha1cd")

	TEXT("blockAMD64", NOSPLIT, "func(dig *digest, p []byte, m1 []uint32, cs [][5]uint32)")
	Doc("blockAMD64 hashes the message p into the current state in dig.",
		"Both m1 and cs are used to store intermediate results which are used by the collision detection logic.")

	// Using the same registers as the Go SHA1 implementation, for
	// easier comparison. In the future this will be reviewed.
	ax := GP32()
	cx := GP32()
	dx64 := GP64()
	bx := GP32()
	bp64 := GP64()
	di64 := GP64()
	si64 := GP64()

	r8 := GP32()
	r9 := GP32()
	r10 := GP32()
	r11 := GP32()
	r12 := GP32()
	r13 := GP32()
	r14 := GP32()
	r15 := GP32()

	dx := dx64.As32()
	bp := RBP.As32()

	dig := Load(Param("dig"), bp64)
	p_base := Load(Param("p").Base(), si64)
	p_len := Load(Param("p").Len(), dx64)
	SHRQ(I8(6), p_len)
	SHLQ(I8(6), p_len)

	LEAQ(Mem{Base: p_base, Index: p_len, Scale: 1}, di64)

	Comment("Load h0, h1, h2, h3, h4.")
	hash := [5]Register{ax, bx, cx, dx, bp}
	for i, r := range hash {
		MOVL(Mem{Base: dig}.Offset(4*i), r)
	}

	// Store message values on the stack.
	w := AllocLocal(shared.Chunk)
	W := func(r int) Mem { return w.Offset((r % 16) * 4) }

	Comment("len(p) >= chunk")
	CMPQ(p_base, di64)
	JEQ(LabelRef("end"))

	Label("loop")
	Comment("Initialize registers a, b, c, d, e.")

	a, b, c, d, e := r11, r12, r13, r14, r15
	for i, r := range []Register{a, b, c, d, e} {
		MOVL(hash[i], r)
	}

	LOAD := func(index int) {
		Comment("LOAD")

		MOVL(Mem{Base: si64}.Offset(4*index), r10)
		BSWAPL(r10)
		MOVL(r10, W(index))
	}

	SHUFFLE := func(index int) {
		Comment("SHUFFLE")
		sp := Mem{Base: StackPointer}
		MOVL(sp.Offset(((index)&0xf)*4), r10)
		XORL(sp.Offset(((index-3)&0xf)*4), r10)
		XORL(sp.Offset(((index-8)&0xf)*4), r10)
		XORL(sp.Offset(((index - 14) & 0xf * 4)), r10)
		ROLL(I8(1), r10)
		MOVL(r10, sp.Offset(((index)&0xf)*4))
	}

	FUNC1 := func(a, b, c, d, e GPVirtual) {
		Comment("FUNC1")
		MOVL(d, r9)
		XORL(c, r9)
		ANDL(b, r9)
		XORL(d, r9)
	}

	FUNC2 := func(a, b, c, d, e GPVirtual) {
		Comment("FUNC2")
		MOVL(b, r9)
		XORL(c, r9)
		XORL(d, r9)
	}

	FUNC3 := func(a, b, c, d, e GPVirtual) {
		Comment("FUNC3")
		MOVL(b, r8)
		ORL(c, r8)
		ANDL(d, r8)

		MOVL(b, r9)
		ANDL(c, r9)
		ORL(r8, r9)
	}

	FUNC4 := FUNC2

	MIX := func(a, b, c, d, e GPVirtual, k int) {
		Comment("MIX")
		ROLL(I8(30), b)
		ADDL(r9, e)
		MOVL(a, r8)
		ROLL(I8(5), r8)
		LEAL(Mem{Base: e, Disp: k, Index: r10, Scale: 1}, e)
		ADDL(r8, e)
	}

	LOADM1 := func(index int) {
		Comment("Load m1")
		m1_base := Load(Param("m1").Base(), R8)
		m1 := Mem{Base: m1_base, Scale: 1}
		MOVL(W(index&0xf), r10)
		MOVL(r10, m1.Offset(index*4))
	}

	csOffset := 0
	// Load the current compression state into cs, so it can be used later.
	// This must be done before shuffles or changes in to the buffer.
	LOADCS := func(a, b, c, d, e GPVirtual, index int) {
		Comment("Load cs")
		cs_base := Load(Param("cs").Base(), R8)
		cs := Mem{Base: cs_base, Scale: 1}

		MOVL(a, cs.Offset(csOffset))
		MOVL(b, cs.Offset(csOffset+4))
		MOVL(c, cs.Offset(csOffset+8))
		MOVL(d, cs.Offset(csOffset+12))
		MOVL(e, cs.Offset(csOffset+16))
		csOffset += 5 * 4
	}

	ROUND1 := func(a, b, c, d, e GPVirtual, index int) {
		Commentf("ROUND1(%d)", index)
		LOAD(index)
		FUNC1(a, b, c, d, e)
		MIX(a, b, c, d, e, shared.K0)
		LOADM1(index)
	}

	ROUND1x := func(a, b, c, d, e GPVirtual, index int) {
		Commentf("ROUND1x(%d)", index)
		SHUFFLE(index)
		FUNC1(a, b, c, d, e)
		MIX(a, b, c, d, e, shared.K0)
		LOADM1(index)
	}

	ROUND2 := func(a, b, c, d, e GPVirtual, index int) {
		Commentf("ROUND2(%d)", index)
		SHUFFLE(index)
		FUNC2(a, b, c, d, e)
		MIX(a, b, c, d, e, shared.K1)
		LOADM1(index)
	}

	ROUND3 := func(a, b, c, d, e GPVirtual, index int) {
		Commentf("ROUND3(%d)", index)
		SHUFFLE(index)
		FUNC3(a, b, c, d, e)
		MIX(a, b, c, d, e, shared.K2)
		LOADM1(index)
	}

	ROUND4 := func(a, b, c, d, e GPVirtual, index int) {
		Commentf("ROUND4(%d)", index)
		SHUFFLE(index)
		FUNC4(a, b, c, d, e)
		MIX(a, b, c, d, e, shared.K3)
		LOADM1(index)
	}

	Comment("ROUND1 (steps 0-15)")
	LOADCS(a, b, c, d, e, 0)
	ROUND1(a, b, c, d, e, 0)
	ROUND1(e, a, b, c, d, 1)
	ROUND1(d, e, a, b, c, 2)
	ROUND1(c, d, e, a, b, 3)
	ROUND1(b, c, d, e, a, 4)
	ROUND1(a, b, c, d, e, 5)
	ROUND1(e, a, b, c, d, 6)
	ROUND1(d, e, a, b, c, 7)
	ROUND1(c, d, e, a, b, 8)
	ROUND1(b, c, d, e, a, 9)
	ROUND1(a, b, c, d, e, 10)
	ROUND1(e, a, b, c, d, 11)
	ROUND1(d, e, a, b, c, 12)
	ROUND1(c, d, e, a, b, 13)
	ROUND1(b, c, d, e, a, 14)
	ROUND1(a, b, c, d, e, 15)

	Comment("ROUND1x (steps 16-19) - same as ROUND1 but with no data load.")
	ROUND1x(e, a, b, c, d, 16)
	ROUND1x(d, e, a, b, c, 17)
	ROUND1x(c, d, e, a, b, 18)
	ROUND1x(b, c, d, e, a, 19)

	Comment("ROUND2 (steps 20-39)")
	ROUND2(a, b, c, d, e, 20)
	ROUND2(e, a, b, c, d, 21)
	ROUND2(d, e, a, b, c, 22)
	ROUND2(c, d, e, a, b, 23)
	ROUND2(b, c, d, e, a, 24)
	ROUND2(a, b, c, d, e, 25)
	ROUND2(e, a, b, c, d, 26)
	ROUND2(d, e, a, b, c, 27)
	ROUND2(c, d, e, a, b, 28)
	ROUND2(b, c, d, e, a, 29)
	ROUND2(a, b, c, d, e, 30)
	ROUND2(e, a, b, c, d, 31)
	ROUND2(d, e, a, b, c, 32)
	ROUND2(c, d, e, a, b, 33)
	ROUND2(b, c, d, e, a, 34)
	ROUND2(a, b, c, d, e, 35)
	ROUND2(e, a, b, c, d, 36)
	ROUND2(d, e, a, b, c, 37)
	ROUND2(c, d, e, a, b, 38)
	ROUND2(b, c, d, e, a, 39)

	Comment("ROUND3 (steps 40-59)")
	ROUND3(a, b, c, d, e, 40)
	ROUND3(e, a, b, c, d, 41)
	ROUND3(d, e, a, b, c, 42)
	ROUND3(c, d, e, a, b, 43)
	ROUND3(b, c, d, e, a, 44)
	ROUND3(a, b, c, d, e, 45)
	ROUND3(e, a, b, c, d, 46)
	ROUND3(d, e, a, b, c, 47)
	ROUND3(c, d, e, a, b, 48)
	ROUND3(b, c, d, e, a, 49)
	ROUND3(a, b, c, d, e, 50)
	ROUND3(e, a, b, c, d, 51)
	ROUND3(d, e, a, b, c, 52)
	ROUND3(c, d, e, a, b, 53)
	ROUND3(b, c, d, e, a, 54)
	ROUND3(a, b, c, d, e, 55)
	ROUND3(e, a, b, c, d, 56)
	ROUND3(d, e, a, b, c, 57)

	LOADCS(c, d, e, a, b, 58)
	ROUND3(c, d, e, a, b, 58)
	ROUND3(b, c, d, e, a, 59)

	Comment("ROUND4 (steps 60-79)")
	ROUND4(a, b, c, d, e, 60)
	ROUND4(e, a, b, c, d, 61)
	ROUND4(d, e, a, b, c, 62)
	ROUND4(c, d, e, a, b, 63)
	ROUND4(b, c, d, e, a, 64)

	LOADCS(a, b, c, d, e, 65)
	ROUND4(a, b, c, d, e, 65)
	ROUND4(e, a, b, c, d, 66)
	ROUND4(d, e, a, b, c, 67)
	ROUND4(c, d, e, a, b, 68)
	ROUND4(b, c, d, e, a, 69)
	ROUND4(a, b, c, d, e, 70)
	ROUND4(e, a, b, c, d, 71)
	ROUND4(d, e, a, b, c, 72)
	ROUND4(c, d, e, a, b, 73)
	ROUND4(b, c, d, e, a, 74)
	ROUND4(a, b, c, d, e, 75)
	ROUND4(e, a, b, c, d, 76)
	ROUND4(d, e, a, b, c, 77)
	ROUND4(c, d, e, a, b, 78)
	ROUND4(b, c, d, e, a, 79)

	Comment("Add registers to temp hash.")
	for i, r := range []Register{a, b, c, d, e} {
		ADDL(r, hash[i])
	}

	ADDQ(I8(shared.Chunk), p_base)
	CMPQ(p_base, di64)
	JB(LabelRef("loop"))

	Label("end")
	dig = Load(Param("dig"), di64)
	for i, r := range hash {
		MOVL(r, Mem{Base: dig}.Offset(4*i))
	}

	RET()
	Generate()
}
