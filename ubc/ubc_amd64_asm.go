//go:build ignore
// +build ignore

package main

import (
	. "github.com/mmcloughlin/avo/build"
	"github.com/mmcloughlin/avo/buildtags"
	. "github.com/mmcloughlin/avo/operand"
	"github.com/pjbgf/sha1cd/ubc"
)

//go:generate go run ubc_amd64_asm.go -out ubc_amd64.s

func main() {
	Constraint(buildtags.Not("noasm").ToConstraint())
	Constraint(buildtags.Term("gc").ToConstraint())
	Constraint(buildtags.Term("amd64").ToConstraint())

	TEXT("CalculateDvMaskAMD64", NOSPLIT, "func(W [80]uint32) uint32")

	mask := GP32()
	MOVL(U32(0xFFFFFFFF), mask)

	r1 := GP32()
	r2 := GP32()

	Comment("(((((W[44] ^ W[45]) >> 29) & 1) - 1) | ^(DV_I_48_0_bit | DV_I_51_0_bit | DV_I_52_0_bit | DV_II_45_0_bit | DV_II_46_0_bit | DV_II_50_0_bit | DV_II_51_0_bit))")
	Load(Param("W").Index(44), r1)
	Load(Param("W").Index(45), r2)
	XORL(r2, r1)
	SHRL(U8(29), r1)
	ANDL(U32(1), r1)
	DECL(r1)
	ORL(U32(^(ubc.DV_I_48_0_bit | ubc.DV_I_51_0_bit | ubc.DV_I_52_0_bit | ubc.DV_II_45_0_bit | ubc.DV_II_46_0_bit | ubc.DV_II_50_0_bit | ubc.DV_II_51_0_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= (((((W[49] ^ W[50]) >> 29) & 1) - 1) | ^(DV_I_46_0_bit | DV_II_45_0_bit | DV_II_50_0_bit | DV_II_51_0_bit | DV_II_55_0_bit | DV_II_56_0_bit))")
	Load(Param("W").Index(49), r1)
	Load(Param("W").Index(50), r2)
	XORL(r2, r1)
	SHRL(U8(29), r1)
	ANDL(U32(1), r1)
	DECL(r1)
	ORL(U32(^(ubc.DV_I_46_0_bit | ubc.DV_II_45_0_bit | ubc.DV_II_50_0_bit | ubc.DV_II_51_0_bit | ubc.DV_II_55_0_bit | ubc.DV_II_56_0_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= (((((W[48] ^ W[49]) >> 29) & 1) - 1) | ^(DV_I_45_0_bit | DV_I_52_0_bit | DV_II_49_0_bit | DV_II_50_0_bit | DV_II_54_0_bit | DV_II_55_0_bit))")
	Load(Param("W").Index(48), r1)
	Load(Param("W").Index(49), r2)
	XORL(r2, r1)
	SHRL(U8(29), r1)
	ANDL(U32(1), r1)
	DECL(r1)
	ORL(U32(^(ubc.DV_I_45_0_bit | ubc.DV_I_52_0_bit | ubc.DV_II_49_0_bit | ubc.DV_II_50_0_bit | ubc.DV_II_54_0_bit | ubc.DV_II_55_0_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= ((((W[47] ^ (W[50] >> 25)) & (1 << 4)) - (1 << 4)) | ^(DV_I_47_0_bit | DV_I_49_0_bit | DV_I_51_0_bit | DV_II_45_0_bit | DV_II_51_0_bit | DV_II_56_0_bit))")
	Load(Param("W").Index(47), r1)
	Load(Param("W").Index(50), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<4), r1)
	SUBL(U32(1<<4), r1)
	ORL(U32(^(ubc.DV_I_47_0_bit | ubc.DV_I_49_0_bit | ubc.DV_I_51_0_bit | ubc.DV_II_45_0_bit | ubc.DV_II_51_0_bit | ubc.DV_II_56_0_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= (((((W[47] ^ W[48]) >> 29) & 1) - 1) | ^(DV_I_44_0_bit | DV_I_51_0_bit | DV_II_48_0_bit | DV_II_49_0_bit | DV_II_53_0_bit | DV_II_54_0_bit))")
	Load(Param("W").Index(47), r1)
	Load(Param("W").Index(48), r2)
	XORL(r2, r1)
	SHRL(U8(29), r1)
	ANDL(U32(1), r1)
	DECL(r1)
	ORL(U32(^(ubc.DV_I_44_0_bit | ubc.DV_I_51_0_bit | ubc.DV_II_48_0_bit | ubc.DV_II_49_0_bit | ubc.DV_II_53_0_bit | ubc.DV_II_54_0_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= (((((W[46] >> 4) ^ (W[49] >> 29)) & 1) - 1) | ^(DV_I_46_0_bit | DV_I_48_0_bit | DV_I_50_0_bit | DV_I_52_0_bit | DV_II_50_0_bit | DV_II_55_0_bit))")
	Load(Param("W").Index(46), r1)
	SHRL(U8(4), r1)
	Load(Param("W").Index(49), r2)
	SHRL(U8(29), r2)
	XORL(r2, r1)
	ANDL(U32(1), r1)
	DECL(r1)
	ORL(U32(^(ubc.DV_I_46_0_bit | ubc.DV_I_48_0_bit | ubc.DV_I_50_0_bit | ubc.DV_I_52_0_bit | ubc.DV_II_50_0_bit | ubc.DV_II_55_0_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= (((((W[46] ^ W[47]) >> 29) & 1) - 1) | ^(DV_I_43_0_bit | DV_I_50_0_bit | DV_II_47_0_bit | DV_II_48_0_bit | DV_II_52_0_bit | DV_II_53_0_bit))")
	Load(Param("W").Index(46), r1)
	Load(Param("W").Index(47), r2)
	XORL(r2, r1)
	SHRL(U8(29), r1)
	ANDL(U32(1), r1)
	DECL(r1)
	ORL(U32(^(ubc.DV_I_43_0_bit | ubc.DV_I_50_0_bit | ubc.DV_II_47_0_bit | ubc.DV_II_48_0_bit | ubc.DV_II_52_0_bit | ubc.DV_II_53_0_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= (((((W[45] >> 4) ^ (W[48] >> 29)) & 1) - 1) | ^(DV_I_45_0_bit | DV_I_47_0_bit | DV_I_49_0_bit | DV_I_51_0_bit | DV_II_49_0_bit | DV_II_54_0_bit))")
	Load(Param("W").Index(45), r1)
	SHRL(U8(4), r1)
	Load(Param("W").Index(48), r2)
	SHRL(U8(29), r2)
	XORL(r2, r1)
	ANDL(U32(1), r1)
	DECL(r1)
	ORL(U32(^(ubc.DV_I_45_0_bit | ubc.DV_I_47_0_bit | ubc.DV_I_49_0_bit | ubc.DV_I_51_0_bit | ubc.DV_II_49_0_bit | ubc.DV_II_54_0_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= (((((W[45] ^ W[46]) >> 29) & 1) - 1) | ^(DV_I_49_0_bit | DV_I_52_0_bit | DV_II_46_0_bit | DV_II_47_0_bit | DV_II_51_0_bit | DV_II_52_0_bit))")
	Load(Param("W").Index(45), r1)
	Load(Param("W").Index(46), r2)
	XORL(r2, r1)
	SHRL(U8(29), r1)
	ANDL(U32(1), r1)
	DECL(r1)
	ORL(U32(^(ubc.DV_I_49_0_bit | ubc.DV_I_52_0_bit | ubc.DV_II_46_0_bit | ubc.DV_II_47_0_bit | ubc.DV_II_51_0_bit | ubc.DV_II_52_0_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= (((((W[44] >> 4) ^ (W[47] >> 29)) & 1) - 1) | ^(DV_I_44_0_bit | DV_I_46_0_bit | DV_I_48_0_bit | DV_I_50_0_bit | DV_II_48_0_bit | DV_II_53_0_bit))")
	Load(Param("W").Index(44), r1)
	SHRL(U8(4), r1)
	Load(Param("W").Index(47), r2)
	SHRL(U8(29), r2)
	XORL(r2, r1)
	ANDL(U32(1), r1)
	DECL(r1)
	ORL(U32(^(ubc.DV_I_44_0_bit | ubc.DV_I_46_0_bit | ubc.DV_I_48_0_bit | ubc.DV_I_50_0_bit | ubc.DV_II_48_0_bit | ubc.DV_II_53_0_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= (((((W[43] >> 4) ^ (W[46] >> 29)) & 1) - 1) | ^(DV_I_43_0_bit | DV_I_45_0_bit | DV_I_47_0_bit | DV_I_49_0_bit | DV_II_47_0_bit | DV_II_52_0_bit))")
	Load(Param("W").Index(43), r1)
	SHRL(U8(4), r1)
	Load(Param("W").Index(46), r2)
	SHRL(U8(29), r2)
	XORL(r2, r1)
	ANDL(U32(1), r1)
	DECL(r1)
	ORL(U32(^(ubc.DV_I_43_0_bit | ubc.DV_I_45_0_bit | ubc.DV_I_47_0_bit | ubc.DV_I_49_0_bit | ubc.DV_II_47_0_bit | ubc.DV_II_52_0_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= (((((W[43] ^ W[44]) >> 29) & 1) - 1) | ^(DV_I_47_0_bit | DV_I_50_0_bit | DV_I_51_0_bit | DV_II_45_0_bit | DV_II_49_0_bit | DV_II_50_0_bit))")
	Load(Param("W").Index(43), r1)
	Load(Param("W").Index(44), r2)
	XORL(r2, r1)
	SHRL(U8(29), r1)
	ANDL(U32(1), r1)
	DECL(r1)
	ORL(U32(^(ubc.DV_I_47_0_bit | ubc.DV_I_50_0_bit | ubc.DV_I_51_0_bit | ubc.DV_II_45_0_bit | ubc.DV_II_49_0_bit | ubc.DV_II_50_0_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= (((((W[42] >> 4) ^ (W[45] >> 29)) & 1) - 1) | ^(DV_I_44_0_bit | DV_I_46_0_bit | DV_I_48_0_bit | DV_I_52_0_bit | DV_II_46_0_bit | DV_II_51_0_bit))")
	Load(Param("W").Index(42), r1)
	SHRL(U8(4), r1)
	Load(Param("W").Index(45), r2)
	SHRL(U8(29), r2)
	XORL(r2, r1)
	ANDL(U32(1), r1)
	DECL(r1)
	ORL(U32(^(ubc.DV_I_44_0_bit | ubc.DV_I_46_0_bit | ubc.DV_I_48_0_bit | ubc.DV_I_52_0_bit | ubc.DV_II_46_0_bit | ubc.DV_II_51_0_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= (((((W[41] >> 4) ^ (W[44] >> 29)) & 1) - 1) | ^(DV_I_43_0_bit | DV_I_45_0_bit | DV_I_47_0_bit | DV_I_51_0_bit | DV_II_45_0_bit | DV_II_50_0_bit))")
	Load(Param("W").Index(41), r1)
	SHRL(U8(4), r1)
	Load(Param("W").Index(44), r2)
	SHRL(U8(29), r2)
	XORL(r2, r1)
	ANDL(U32(1), r1)
	DECL(r1)
	ORL(U32(^(ubc.DV_I_43_0_bit | ubc.DV_I_45_0_bit | ubc.DV_I_47_0_bit | ubc.DV_I_51_0_bit | ubc.DV_II_45_0_bit | ubc.DV_II_50_0_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= (((((W[40] ^ W[41]) >> 29) & 1) - 1) | ^(DV_I_44_0_bit | DV_I_47_0_bit | DV_I_48_0_bit | DV_II_46_0_bit | DV_II_47_0_bit | DV_II_56_0_bit))")
	Load(Param("W").Index(40), r1)
	Load(Param("W").Index(41), r2)
	XORL(r2, r1)
	SHRL(U8(29), r1)
	ANDL(U32(1), r1)
	DECL(r1)
	ORL(U32(^(ubc.DV_I_44_0_bit | ubc.DV_I_47_0_bit | ubc.DV_I_48_0_bit | ubc.DV_II_46_0_bit | ubc.DV_II_47_0_bit | ubc.DV_II_56_0_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= (((((W[54] ^ W[55]) >> 29) & 1) - 1) | ^(DV_I_51_0_bit | DV_II_47_0_bit | DV_II_50_0_bit | DV_II_55_0_bit | DV_II_56_0_bit))")
	Load(Param("W").Index(54), r1)
	Load(Param("W").Index(55), r2)
	XORL(r2, r1)
	SHRL(U8(29), r1)
	ANDL(U32(1), r1)
	DECL(r1)
	ORL(U32(^(ubc.DV_I_51_0_bit | ubc.DV_II_47_0_bit | ubc.DV_II_50_0_bit | ubc.DV_II_55_0_bit | ubc.DV_II_56_0_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= (((((W[53] ^ W[54]) >> 29) & 1) - 1) | ^(DV_I_50_0_bit | DV_II_46_0_bit | DV_II_49_0_bit | DV_II_54_0_bit | DV_II_55_0_bit))")
	Load(Param("W").Index(53), r1)
	Load(Param("W").Index(54), r2)
	XORL(r2, r1)
	SHRL(U8(29), r1)
	ANDL(U32(1), r1)
	DECL(r1)
	ORL(U32(^(ubc.DV_I_50_0_bit | ubc.DV_II_46_0_bit | ubc.DV_II_49_0_bit | ubc.DV_II_54_0_bit | ubc.DV_II_55_0_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= (((((W[52] ^ W[53]) >> 29) & 1) - 1) | ^(DV_I_49_0_bit | DV_II_45_0_bit | DV_II_48_0_bit | DV_II_53_0_bit | DV_II_54_0_bit))")
	Load(Param("W").Index(52), r1)
	Load(Param("W").Index(53), r2)
	XORL(r2, r1)
	SHRL(U8(29), r1)
	ANDL(U32(1), r1)
	DECL(r1)
	ORL(U32(^(ubc.DV_I_49_0_bit | ubc.DV_II_45_0_bit | ubc.DV_II_48_0_bit | ubc.DV_II_53_0_bit | ubc.DV_II_54_0_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= ((((W[50] ^ (W[53] >> 25)) & (1 << 4)) - (1 << 4)) | ^(DV_I_50_0_bit | DV_I_52_0_bit | DV_II_46_0_bit | DV_II_48_0_bit | DV_II_54_0_bit))")
	Load(Param("W").Index(50), r1)
	Load(Param("W").Index(53), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<4), r1)
	SUBL(U32(1<<4), r1)
	ORL(U32(^(ubc.DV_I_50_0_bit | ubc.DV_I_52_0_bit | ubc.DV_II_46_0_bit | ubc.DV_II_48_0_bit | ubc.DV_II_54_0_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= (((((W[50] ^ W[51]) >> 29) & 1) - 1) | ^(DV_I_47_0_bit | DV_II_46_0_bit | DV_II_51_0_bit | DV_II_52_0_bit | DV_II_56_0_bit))")
	Load(Param("W").Index(50), r1)
	Load(Param("W").Index(51), r2)
	XORL(r2, r1)
	SHRL(U8(29), r1)
	ANDL(U32(1), r1)
	DECL(r1)
	ORL(U32(^(ubc.DV_I_47_0_bit | ubc.DV_II_46_0_bit | ubc.DV_II_51_0_bit | ubc.DV_II_52_0_bit | ubc.DV_II_56_0_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= ((((W[49] ^ (W[52] >> 25)) & (1 << 4)) - (1 << 4)) | ^(DV_I_49_0_bit | DV_I_51_0_bit | DV_II_45_0_bit | DV_II_47_0_bit | DV_II_53_0_bit))")
	Load(Param("W").Index(49), r1)
	Load(Param("W").Index(52), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<4), r1)
	SUBL(U32(1<<4), r1)
	ORL(U32(^(ubc.DV_I_49_0_bit | ubc.DV_I_51_0_bit | ubc.DV_II_45_0_bit | ubc.DV_II_47_0_bit | ubc.DV_II_53_0_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= ((((W[48] ^ (W[51] >> 25)) & (1 << 4)) - (1 << 4)) | ^(DV_I_48_0_bit | DV_I_50_0_bit | DV_I_52_0_bit | DV_II_46_0_bit | DV_II_52_0_bit))")
	Load(Param("W").Index(48), r1)
	Load(Param("W").Index(51), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<4), r1)
	SUBL(U32(1<<4), r1)
	ORL(U32(^(ubc.DV_I_48_0_bit | ubc.DV_I_50_0_bit | ubc.DV_I_52_0_bit | ubc.DV_II_46_0_bit | ubc.DV_II_52_0_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= (((((W[42] ^ W[43]) >> 29) & 1) - 1) | ^(DV_I_46_0_bit | DV_I_49_0_bit | DV_I_50_0_bit | DV_II_48_0_bit | DV_II_49_0_bit))")
	Load(Param("W").Index(42), r1)
	Load(Param("W").Index(43), r2)
	XORL(r2, r1)
	SHRL(U8(29), r1)
	ANDL(U32(1), r1)
	DECL(r1)
	ORL(U32(^(ubc.DV_I_46_0_bit | ubc.DV_I_49_0_bit | ubc.DV_I_50_0_bit | ubc.DV_II_48_0_bit | ubc.DV_II_49_0_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= (((((W[41] ^ W[42]) >> 29) & 1) - 1) | ^(DV_I_45_0_bit | DV_I_48_0_bit | DV_I_49_0_bit | DV_II_47_0_bit | DV_II_48_0_bit))")
	Load(Param("W").Index(41), r1)
	Load(Param("W").Index(42), r2)
	XORL(r2, r1)
	SHRL(U8(29), r1)
	ANDL(U32(1), r1)
	DECL(r1)
	ORL(U32(^(ubc.DV_I_45_0_bit | ubc.DV_I_48_0_bit | ubc.DV_I_49_0_bit | ubc.DV_II_47_0_bit | ubc.DV_II_48_0_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= (((((W[40] >> 4) ^ (W[43] >> 29)) & 1) - 1) | ^(DV_I_44_0_bit | DV_I_46_0_bit | DV_I_50_0_bit | DV_II_49_0_bit | DV_II_56_0_bit))")
	Load(Param("W").Index(40), r1)
	Load(Param("W").Index(43), r2)
	SHRL(U8(4), r1)
	SHRL(U8(29), r2)
	XORL(r2, r1)
	ANDL(U32(1), r1)
	DECL(r1)
	ORL(U32(^(ubc.DV_I_44_0_bit | ubc.DV_I_46_0_bit | ubc.DV_I_50_0_bit | ubc.DV_II_49_0_bit | ubc.DV_II_56_0_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= (((((W[39] >> 4) ^ (W[42] >> 29)) & 1) - 1) | ^(DV_I_43_0_bit | DV_I_45_0_bit | DV_I_49_0_bit | DV_II_48_0_bit | DV_II_55_0_bit))")
	Load(Param("W").Index(39), r1)
	Load(Param("W").Index(42), r2)
	SHRL(U8(4), r1)
	SHRL(U8(29), r2)
	XORL(r2, r1)
	ANDL(U32(1), r1)
	DECL(r1)
	ORL(U32(^(ubc.DV_I_43_0_bit | ubc.DV_I_45_0_bit | ubc.DV_I_49_0_bit | ubc.DV_II_48_0_bit | ubc.DV_II_55_0_bit)), r1)
	ANDL(r1, mask)

	Comment(
		"if (mask & (DV_I_44_0_bit | DV_I_48_0_bit | DV_II_47_0_bit | DV_II_54_0_bit | DV_II_56_0_bit)) != 0 {",
		"  mask &= (((((W[38] >> 4) ^ (W[41] >> 29)) & 1) - 1) | ^(DV_I_44_0_bit | DV_I_48_0_bit | DV_II_47_0_bit | DV_II_54_0_bit | DV_II_56_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_I_44_0_bit|ubc.DV_I_48_0_bit|ubc.DV_II_47_0_bit|ubc.DV_II_54_0_bit|ubc.DV_II_56_0_bit), mask) // TODO: confirm this is correct
	JE(LabelRef("f1"))
	Load(Param("W").Index(38), r1)
	Load(Param("W").Index(41), r2)
	SHRL(U8(4), r1)
	SHRL(U8(29), r2)
	XORL(r2, r1)
	ANDL(U32(1), r1)
	DECL(r1)
	ORL(U32(^(ubc.DV_I_44_0_bit | ubc.DV_I_48_0_bit | ubc.DV_II_47_0_bit | ubc.DV_II_54_0_bit | ubc.DV_II_56_0_bit)), r1)
	ANDL(r1, mask)

	Label("f1")
	Comment("mask &= (((((W[37] >> 4) ^ (W[40] >> 29)) & 1) - 1) | ^(DV_I_43_0_bit | DV_I_47_0_bit | DV_II_46_0_bit | DV_II_53_0_bit | DV_II_55_0_bit))")
	Load(Param("W").Index(37), r1)
	Load(Param("W").Index(40), r2)
	SHRL(U8(4), r1)
	SHRL(U8(29), r2)
	XORL(r2, r1)
	ANDL(U32(1), r1)
	DECL(r1)
	ORL(U32(^(ubc.DV_I_43_0_bit | ubc.DV_I_47_0_bit | ubc.DV_II_46_0_bit | ubc.DV_II_53_0_bit | ubc.DV_II_55_0_bit)), r1)
	ANDL(r1, mask)

	Comment(
		"if (mask & (DV_I_52_0_bit | DV_II_48_0_bit | DV_II_51_0_bit | DV_II_56_0_bit)) != 0 {",
		"  mask &= (((((W[55] ^ W[56]) >> 29) & 1) - 1) | ^(DV_I_52_0_bit | DV_II_48_0_bit | DV_II_51_0_bit | DV_II_56_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_I_52_0_bit|ubc.DV_II_48_0_bit|ubc.DV_II_51_0_bit|ubc.DV_II_56_0_bit), mask) // TODO: confirm this is correct
	JE(LabelRef("f2"))
	Load(Param("W").Index(55), r1)
	Load(Param("W").Index(56), r2)
	XORL(r2, r1)
	SHRL(U8(29), r1)
	ANDL(U32(1), r1)
	DECL(r1)
	ORL(U32(^(ubc.DV_I_52_0_bit | ubc.DV_II_48_0_bit | ubc.DV_II_51_0_bit | ubc.DV_II_56_0_bit)), r1)
	ANDL(r1, mask)

	Label("f2")
	Comment(
		"if (mask & (DV_I_52_0_bit | DV_II_48_0_bit | DV_II_50_0_bit | DV_II_56_0_bit)) != 0 {",
		"  mask &= ((((W[52] ^ (W[55] >> 25)) & (1 << 4)) - (1 << 4)) | ^(DV_I_52_0_bit | DV_II_48_0_bit | DV_II_50_0_bit | DV_II_56_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_I_52_0_bit|ubc.DV_II_48_0_bit|ubc.DV_II_50_0_bit|ubc.DV_II_56_0_bit), mask) // TODO: confirm this is correct
	JE(LabelRef("f3"))
	Load(Param("W").Index(52), r1)
	Load(Param("W").Index(55), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<4), r1)
	SUBL(U32(1<<4), r1)
	ORL(U32(^(ubc.DV_I_52_0_bit | ubc.DV_II_48_0_bit | ubc.DV_II_50_0_bit | ubc.DV_II_56_0_bit)), r1)
	ANDL(r1, mask)

	Label("f3")
	Comment(
		"if (mask & (DV_I_51_0_bit | DV_II_47_0_bit | DV_II_49_0_bit | DV_II_55_0_bit)) != 0 {",
		"  mask &= ((((W[51] ^ (W[54] >> 25)) & (1 << 4)) - (1 << 4)) | ^(DV_I_51_0_bit | DV_II_47_0_bit | DV_II_49_0_bit | DV_II_55_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_I_51_0_bit|ubc.DV_II_47_0_bit|ubc.DV_II_49_0_bit|ubc.DV_II_55_0_bit), mask) // TODO: confirm this is correct
	JE(LabelRef("f4"))
	Load(Param("W").Index(51), r1)
	Load(Param("W").Index(54), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<4), r1)
	SUBL(U32(1<<4), r1)
	ORL(U32(^(ubc.DV_I_51_0_bit | ubc.DV_II_47_0_bit | ubc.DV_II_49_0_bit | ubc.DV_II_55_0_bit)), r1)
	ANDL(r1, mask)

	Label("f4")
	Comment(
		"if (mask & (DV_I_48_0_bit | DV_II_47_0_bit | DV_II_52_0_bit | DV_II_53_0_bit)) != 0 {",
		"  mask &= (((((W[51] ^ W[52]) >> 29) & 1) - 1) | ^(DV_I_48_0_bit | DV_II_47_0_bit | DV_II_52_0_bit | DV_II_53_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_I_48_0_bit|ubc.DV_II_47_0_bit|ubc.DV_II_52_0_bit|ubc.DV_II_53_0_bit), mask) // TODO: confirm this is correct
	JE(LabelRef("f5"))
	Load(Param("W").Index(51), r1)
	Load(Param("W").Index(52), r2)
	XORL(r2, r1)
	SHRL(U8(29), r1)
	ANDL(U32(1), r1)
	DECL(r1)
	ORL(U32(^(ubc.DV_I_48_0_bit | ubc.DV_II_47_0_bit | ubc.DV_II_52_0_bit | ubc.DV_II_53_0_bit)), r1)
	ANDL(r1, mask)

	Label("f5")
	Comment(
		"if (mask & (DV_I_46_0_bit | DV_I_49_0_bit | DV_II_45_0_bit | DV_II_48_0_bit)) != 0 {",
		"  mask &= (((((W[36] >> 4) ^ (W[40] >> 29)) & 1) - 1) | ^(DV_I_46_0_bit | DV_I_49_0_bit | DV_II_45_0_bit | DV_II_48_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_I_46_0_bit|ubc.DV_I_49_0_bit|ubc.DV_II_45_0_bit|ubc.DV_II_48_0_bit), mask) // TODO: confirm this is correct
	JE(LabelRef("f6"))
	Load(Param("W").Index(36), r1)
	SHRL(U8(4), r1)
	Load(Param("W").Index(40), r2)
	SHRL(U8(29), r2)
	XORL(r2, r1)
	ANDL(U32(1), r1)
	DECL(r1)
	ORL(U32(^(ubc.DV_I_46_0_bit | ubc.DV_I_49_0_bit | ubc.DV_II_45_0_bit | ubc.DV_II_48_0_bit)), r1)
	ANDL(r1, mask)

	Label("f6")
	Comment(
		"if (mask & (DV_I_52_0_bit | DV_II_48_0_bit | DV_II_49_0_bit)) != 0 {",
		"  mask &= ((0 - (((W[53] ^ W[56]) >> 29) & 1)) | ^(DV_I_52_0_bit | DV_II_48_0_bit | DV_II_49_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_I_52_0_bit|ubc.DV_II_48_0_bit|ubc.DV_II_49_0_bit), mask) // TODO: confirm this is correct
	JE(LabelRef("f7"))
	Load(Param("W").Index(53), r1)
	Load(Param("W").Index(56), r2)
	XORL(r2, r1)
	SHRL(U8(29), r1)
	ANDL(U32(1), r1)
	NEGL(r1)
	ORL(U32(^(ubc.DV_I_52_0_bit | ubc.DV_II_48_0_bit | ubc.DV_II_49_0_bit)), r1)
	ANDL(r1, mask)

	Label("f7")
	Comment(
		"if (mask & (DV_I_50_0_bit | DV_II_46_0_bit | DV_II_47_0_bit)) != 0 {",
		"	mask &= ((0 - (((W[51] ^ W[54]) >> 29) & 1)) | ^(DV_I_50_0_bit | DV_II_46_0_bit | DV_II_47_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_I_50_0_bit|ubc.DV_II_46_0_bit|ubc.DV_II_47_0_bit), mask) // TODO: confirm this is correct
	JE(LabelRef("f8"))
	Load(Param("W").Index(51), r1)
	Load(Param("W").Index(54), r2)
	XORL(r2, r1)
	SHRL(U8(29), r1)
	ANDL(U32(1), r1)
	NEGL(r1)
	ORL(U32(^(ubc.DV_I_50_0_bit | ubc.DV_II_46_0_bit | ubc.DV_II_47_0_bit)), r1)
	ANDL(r1, mask)

	Label("f8")
	Comment(
		"if (mask & (DV_I_49_0_bit | DV_I_51_0_bit | DV_II_45_0_bit)) != 0 {",
		"	mask &= ((0 - (((W[50] ^ W[52]) >> 29) & 1)) | ^(DV_I_49_0_bit | DV_I_51_0_bit | DV_II_45_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_I_49_0_bit|ubc.DV_I_51_0_bit|ubc.DV_II_45_0_bit), mask) // TODO: confirm this is correct
	JE(LabelRef("f9"))
	Load(Param("W").Index(50), r1)
	Load(Param("W").Index(52), r2)
	XORL(r2, r1)
	SHRL(U8(29), r1)
	ANDL(U32(1), r1)
	NEGL(r1)
	ORL(U32(^(ubc.DV_I_49_0_bit | ubc.DV_I_51_0_bit | ubc.DV_II_45_0_bit)), r1)
	ANDL(r1, mask)

	Label("f9")
	Comment(
		"if (mask & (DV_I_48_0_bit | DV_I_50_0_bit | DV_I_52_0_bit)) != 0 {",
		"	mask &= ((0 - (((W[49] ^ W[51]) >> 29) & 1)) | ^(DV_I_48_0_bit | DV_I_50_0_bit | DV_I_52_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_I_48_0_bit|ubc.DV_I_50_0_bit|ubc.DV_I_52_0_bit), mask) // TODO: confirm this is correct
	JE(LabelRef("f10"))
	Load(Param("W").Index(49), r1)
	Load(Param("W").Index(51), r2)
	XORL(r2, r1)
	SHRL(U8(29), r1)
	ANDL(U32(1), r1)
	NEGL(r1)
	ORL(U32(^(ubc.DV_I_48_0_bit | ubc.DV_I_50_0_bit | ubc.DV_I_52_0_bit)), r1)
	ANDL(r1, mask)

	Label("f10")
	Comment(
		"if (mask & (DV_I_47_0_bit | DV_I_49_0_bit | DV_I_51_0_bit)) != 0 {",
		"	mask &= ((0 - (((W[48] ^ W[50]) >> 29) & 1)) | ^(DV_I_47_0_bit | DV_I_49_0_bit | DV_I_51_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_I_47_0_bit|ubc.DV_I_49_0_bit|ubc.DV_I_51_0_bit), mask) // TODO: confirm this is correct
	JE(LabelRef("f11"))
	Load(Param("W").Index(48), r1)
	Load(Param("W").Index(50), r2)
	XORL(r2, r1)
	SHRL(U8(29), r1)
	ANDL(U32(1), r1)
	NEGL(r1)
	ORL(U32(^(ubc.DV_I_47_0_bit | ubc.DV_I_49_0_bit | ubc.DV_I_51_0_bit)), r1)
	ANDL(r1, mask)

	Label("f11")
	Comment(
		"if (mask & (DV_I_46_0_bit | DV_I_48_0_bit | DV_I_50_0_bit)) != 0 {",
		"	mask &= ((0 - (((W[47] ^ W[49]) >> 29) & 1)) | ^(DV_I_46_0_bit | DV_I_48_0_bit | DV_I_50_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_I_46_0_bit|ubc.DV_I_48_0_bit|ubc.DV_I_50_0_bit), mask) // TODO: confirm this is correct
	JE(LabelRef("f12"))
	Load(Param("W").Index(47), r1)
	Load(Param("W").Index(49), r2)
	XORL(r2, r1)
	SHRL(U8(29), r1)
	ANDL(U32(1), r1)
	NEGL(r1)
	ORL(U32(^(ubc.DV_I_46_0_bit | ubc.DV_I_48_0_bit | ubc.DV_I_50_0_bit)), r1)
	ANDL(r1, mask)

	Label("f12")
	Comment(
		"if (mask & (DV_I_45_0_bit | DV_I_47_0_bit | DV_I_49_0_bit)) != 0 {",
		"	mask &= ((0 - (((W[46] ^ W[48]) >> 29) & 1)) | ^(DV_I_45_0_bit | DV_I_47_0_bit | DV_I_49_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_I_45_0_bit|ubc.DV_I_47_0_bit|ubc.DV_I_49_0_bit), mask) // TODO: confirm this is correct
	JE(LabelRef("f13"))
	Load(Param("W").Index(46), r1)
	Load(Param("W").Index(48), r2)
	XORL(r2, r1)
	SHRL(U8(29), r1)
	ANDL(U32(1), r1)
	NEGL(r1)
	ORL(U32(^(ubc.DV_I_45_0_bit | ubc.DV_I_47_0_bit | ubc.DV_I_49_0_bit)), r1)
	ANDL(r1, mask)

	Label("f13")
	Comment("mask &= ((((W[45] ^ W[47]) & (1 << 6)) - (1 << 6)) | ^(DV_I_47_2_bit | DV_I_49_2_bit | DV_I_51_2_bit))")
	Load(Param("W").Index(45), r1)
	Load(Param("W").Index(47), r2)
	XORL(r2, r1)
	ANDL(U32(1<<6), r1)
	SUBL(U32(1<<6), r1)
	ORL(U32(^(ubc.DV_I_47_2_bit | ubc.DV_I_49_2_bit | ubc.DV_I_51_2_bit)), r1)
	ANDL(r1, mask)

	Comment(
		"if (mask & (DV_I_44_0_bit | DV_I_46_0_bit | DV_I_48_0_bit)) != 0 {",
		"	mask &= ((0 - (((W[45] ^ W[47]) >> 29) & 1)) | ^(DV_I_44_0_bit | DV_I_46_0_bit | DV_I_48_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_I_44_0_bit|ubc.DV_I_46_0_bit|ubc.DV_I_48_0_bit), mask) // TODO: confirm this is correct
	JE(LabelRef("f14"))
	Load(Param("W").Index(45), r1)
	Load(Param("W").Index(47), r2)
	XORL(r2, r1)
	SHRL(U8(29), r1)
	ANDL(U32(1), r1)
	NEGL(r1)
	ORL(U32(^(ubc.DV_I_44_0_bit | ubc.DV_I_46_0_bit | ubc.DV_I_48_0_bit)), r1)
	ANDL(r1, mask)

	Label("f14")
	Comment("mask &= (((((W[44] ^ W[46]) >> 6) & 1) - 1) | ^(DV_I_46_2_bit | DV_I_48_2_bit | DV_I_50_2_bit))")
	Load(Param("W").Index(44), r1)
	Load(Param("W").Index(46), r2)
	XORL(r2, r1)
	SHRL(U8(6), r1)
	ANDL(U32(1), r1)
	DECL(r1)
	ORL(U32(^(ubc.DV_I_46_2_bit | ubc.DV_I_48_2_bit | ubc.DV_I_50_2_bit)), r1)
	ANDL(r1, mask)

	Comment(
		"if (mask & (DV_I_43_0_bit | DV_I_45_0_bit | DV_I_47_0_bit)) != 0 {",
		"	mask &= ((0 - (((W[44] ^ W[46]) >> 29) & 1)) | ^(DV_I_43_0_bit | DV_I_45_0_bit | DV_I_47_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_I_43_0_bit|ubc.DV_I_45_0_bit|ubc.DV_I_47_0_bit), mask) // TODO: confirm this is correct
	JE(LabelRef("f15"))
	Load(Param("W").Index(44), r1)
	Load(Param("W").Index(46), r2)
	XORL(r2, r1)
	SHRL(U8(29), r1)
	ANDL(U32(1), r1)
	NEGL(r1)
	ORL(U32(^(ubc.DV_I_43_0_bit | ubc.DV_I_45_0_bit | ubc.DV_I_47_0_bit)), r1)
	ANDL(r1, mask)

	Label("f15")
	Comment("mask &= ((0 - ((W[41] ^ (W[42] >> 5)) & (1 << 1))) | ^(DV_I_48_2_bit | DV_II_46_2_bit | DV_II_51_2_bit))")
	Load(Param("W").Index(41), r1)
	Load(Param("W").Index(42), r2)
	SHRL(U8(5), r2)
	XORL(r2, r1)
	ANDL(U32(1<<1), r1)
	NEGL(r1)
	ORL(U32(^(ubc.DV_I_48_2_bit | ubc.DV_II_46_2_bit | ubc.DV_II_51_2_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= ((0 - ((W[40] ^ (W[41] >> 5)) & (1 << 1))) | ^(DV_I_47_2_bit | DV_I_51_2_bit | DV_II_50_2_bit))")
	Load(Param("W").Index(40), r1)
	Load(Param("W").Index(41), r2)
	SHRL(U8(5), r2)
	XORL(r2, r1)
	ANDL(U32(1<<1), r1)
	NEGL(r1)
	ORL(U32(^(ubc.DV_I_47_2_bit | ubc.DV_I_51_2_bit | ubc.DV_II_50_2_bit)), r1)
	ANDL(r1, mask)

	Comment(
		"if (mask & (DV_I_44_0_bit | DV_I_46_0_bit | DV_II_56_0_bit)) != 0 {",
		"	mask &= ((0 - (((W[40] ^ W[42]) >> 4) & 1)) | ^(DV_I_44_0_bit | DV_I_46_0_bit | DV_II_56_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_I_44_0_bit|ubc.DV_I_46_0_bit|ubc.DV_II_56_0_bit), mask) // TODO: confirm this is correct
	JE(LabelRef("f16"))
	Load(Param("W").Index(40), r1)
	Load(Param("W").Index(42), r2)
	XORL(r2, r1)
	SHRL(U8(4), r1)
	ANDL(U32(1), r1)
	NEGL(r1)
	ORL(U32(^(ubc.DV_I_44_0_bit | ubc.DV_I_46_0_bit | ubc.DV_II_56_0_bit)), r1)
	ANDL(r1, mask)

	Label("f16")
	Comment("mask &= ((0 - ((W[39] ^ (W[40] >> 5)) & (1 << 1))) | ^(DV_I_46_2_bit | DV_I_50_2_bit | DV_II_49_2_bit))")
	Load(Param("W").Index(39), r1)
	Load(Param("W").Index(40), r2)
	SHRL(U8(5), r2)
	XORL(r2, r1)
	ANDL(U32(1<<1), r1)
	NEGL(r1)
	ORL(U32(^(ubc.DV_I_46_2_bit | ubc.DV_I_50_2_bit | ubc.DV_II_49_2_bit)), r1)
	ANDL(r1, mask)

	Comment(
		"if (mask & (DV_I_43_0_bit | DV_I_45_0_bit | DV_II_55_0_bit)) != 0 {",
		"	mask &= ((0 - (((W[39] ^ W[41]) >> 4) & 1)) | ^(DV_I_43_0_bit | DV_I_45_0_bit | DV_II_55_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_I_43_0_bit|ubc.DV_I_45_0_bit|ubc.DV_II_55_0_bit), mask) // TODO: confirm this is correct
	JE(LabelRef("f17"))
	Load(Param("W").Index(39), r1)
	Load(Param("W").Index(41), r2)
	XORL(r2, r1)
	SHRL(U8(4), r1)
	ANDL(U32(1), r1)
	NEGL(r1)
	ORL(U32(^(ubc.DV_I_43_0_bit | ubc.DV_I_45_0_bit | ubc.DV_II_55_0_bit)), r1)
	ANDL(r1, mask)

	Label("f17")
	Comment(
		"if (mask & (DV_I_44_0_bit | DV_II_54_0_bit | DV_II_56_0_bit)) != 0 {",
		"	mask &= ((0 - (((W[38] ^ W[40]) >> 4) & 1)) | ^(DV_I_44_0_bit | DV_II_54_0_bit | DV_II_56_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_I_44_0_bit|ubc.DV_II_54_0_bit|ubc.DV_II_56_0_bit), mask) // TODO: confirm this is correct
	JE(LabelRef("f18"))
	Load(Param("W").Index(38), r1)
	Load(Param("W").Index(40), r2)
	XORL(r2, r1)
	SHRL(U8(4), r1)
	ANDL(U32(1), r1)
	NEGL(r1)
	ORL(U32(^(ubc.DV_I_44_0_bit | ubc.DV_II_54_0_bit | ubc.DV_II_56_0_bit)), r1)
	ANDL(r1, mask)

	Label("f18")
	Comment(
		"if (mask & (DV_I_43_0_bit | DV_II_53_0_bit | DV_II_55_0_bit)) != 0 {",
		"	mask &= ((0 - (((W[37] ^ W[39]) >> 4) & 1)) | ^(DV_I_43_0_bit | DV_II_53_0_bit | DV_II_55_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_I_43_0_bit|ubc.DV_II_53_0_bit|ubc.DV_II_55_0_bit), mask) // TODO: confirm this is correct
	JE(LabelRef("f19"))
	Load(Param("W").Index(37), r1)
	Load(Param("W").Index(39), r2)
	XORL(r2, r1)
	SHRL(U8(4), r1)
	ANDL(U32(1), r1)
	NEGL(r1)
	ORL(U32(^(ubc.DV_I_43_0_bit | ubc.DV_II_53_0_bit | ubc.DV_II_55_0_bit)), r1)
	ANDL(r1, mask)

	Label("f19")
	Comment("mask &= ((0 - ((W[36] ^ (W[37] >> 5)) & (1 << 1))) | ^(DV_I_47_2_bit | DV_I_50_2_bit | DV_II_46_2_bit))")
	Load(Param("W").Index(36), r1)
	Load(Param("W").Index(37), r2)
	SHRL(U8(5), r2)
	XORL(r2, r1)
	ANDL(U32(1<<1), r1)
	NEGL(r1)
	ORL(U32(^(ubc.DV_I_47_2_bit | ubc.DV_I_50_2_bit | ubc.DV_II_46_2_bit)), r1)
	ANDL(r1, mask)

	Comment(
		"if (mask & (DV_I_45_0_bit | DV_I_48_0_bit | DV_II_47_0_bit)) != 0 {",
		"	mask &= (((((W[35] >> 4) ^ (W[39] >> 29)) & 1) - 1) | ^(DV_I_45_0_bit | DV_I_48_0_bit | DV_II_47_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_I_45_0_bit|ubc.DV_I_48_0_bit|ubc.DV_II_47_0_bit), mask) // TODO: confirm this is correct
	JE(LabelRef("f20"))
	Load(Param("W").Index(35), r1)
	Load(Param("W").Index(39), r2)
	SHRL(U8(4), r1)
	SHRL(U8(29), r2)
	XORL(r2, r1)
	ANDL(U32(1), r1)
	SUBL(U32(1), r1)
	ORL(U32(^(ubc.DV_I_45_0_bit | ubc.DV_I_48_0_bit | ubc.DV_II_47_0_bit)), r1)
	ANDL(r1, mask)

	Label("f20")
	Comment(
		"if (mask & (DV_I_48_0_bit | DV_II_48_0_bit)) != 0 {",
		"	mask &= ((0 - ((W[63] ^ (W[64] >> 5)) & (1 << 0))) | ^(DV_I_48_0_bit | DV_II_48_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_I_48_0_bit|ubc.DV_II_48_0_bit), mask) // TODO: confirm this is correct
	JE(LabelRef("f21"))
	Load(Param("W").Index(63), r1)
	Load(Param("W").Index(64), r2)
	SHRL(U8(5), r2)
	XORL(r2, r1)
	ANDL(U32(1<<0), r1)
	NEGL(r1)
	ORL(U32(^(ubc.DV_I_48_0_bit | ubc.DV_II_48_0_bit)), r1)
	ANDL(r1, mask)

	Label("f21")
	Comment(
		"if (mask & (DV_I_45_0_bit | DV_II_45_0_bit)) != 0 {",
		"	mask &= ((0 - ((W[63] ^ (W[64] >> 5)) & (1 << 1))) | ^(DV_I_45_0_bit | DV_II_45_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_I_45_0_bit|ubc.DV_II_45_0_bit), mask) // TODO: confirm this is correct
	JE(LabelRef("f22"))
	Load(Param("W").Index(63), r1)
	Load(Param("W").Index(64), r2)
	SHRL(U8(5), r2)
	XORL(r2, r1)
	ANDL(U32(1<<1), r1)
	NEGL(r1)
	ORL(U32(^(ubc.DV_I_45_0_bit | ubc.DV_II_45_0_bit)), r1)
	ANDL(r1, mask)

	Label("f22")
	Comment(
		"if (mask & (DV_I_47_0_bit | DV_II_47_0_bit)) != 0 {",
		"	mask &= ((0 - ((W[62] ^ (W[63] >> 5)) & (1 << 0))) | ^(DV_I_47_0_bit | DV_II_47_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_I_47_0_bit|ubc.DV_II_47_0_bit), mask)
	JE(LabelRef("f23"))
	Load(Param("W").Index(62), r1)
	Load(Param("W").Index(63), r2)
	SHRL(U8(5), r2)
	XORL(r2, r1)
	ANDL(U32(1<<0), r1)
	NEGL(r1)
	ORL(U32(^(ubc.DV_I_47_0_bit | ubc.DV_II_47_0_bit)), r1)
	ANDL(r1, mask)

	Label("f23")
	Comment(
		"if (mask & (DV_I_46_0_bit | DV_II_46_0_bit)) != 0 {",
		"	mask &= ((0 - ((W[61] ^ (W[62] >> 5)) & (1 << 0))) | ^(DV_I_46_0_bit | DV_II_46_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_I_46_0_bit|ubc.DV_II_46_0_bit), mask) // TODO: confirm this is correct
	JE(LabelRef("f24"))
	Load(Param("W").Index(61), r1)
	Load(Param("W").Index(62), r2)
	SHRL(U8(5), r2)
	XORL(r2, r1)
	ANDL(U32(1<<0), r1)
	NEGL(r1)
	ORL(U32(^(ubc.DV_I_46_0_bit | ubc.DV_II_46_0_bit)), r1)
	ANDL(r1, mask)

	Label("f24")
	Comment("mask &= ((0 - ((W[61] ^ (W[62] >> 5)) & (1 << 2))) | ^(DV_I_46_2_bit | DV_II_46_2_bit))")
	Load(Param("W").Index(61), r1)
	Load(Param("W").Index(62), r2)
	SHRL(U8(5), r2)
	XORL(r2, r1)
	ANDL(U32(1<<2), r1)
	NEGL(r1)
	ORL(U32(^(ubc.DV_I_46_2_bit | ubc.DV_II_46_2_bit)), r1)
	ANDL(r1, mask)

	Comment(
		"if (mask & (DV_I_45_0_bit | DV_II_45_0_bit)) != 0 {",
		"	mask &= ((0 - ((W[60] ^ (W[61] >> 5)) & (1 << 0))) | ^(DV_I_45_0_bit | DV_II_45_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_I_45_0_bit|ubc.DV_II_45_0_bit), mask) // TODO: confirm this is correct
	JE(LabelRef("f25"))
	Load(Param("W").Index(60), r1)
	Load(Param("W").Index(61), r2)
	SHRL(U8(5), r2)
	XORL(r2, r1)
	ANDL(U32(1<<0), r1)
	NEGL(r1)
	ORL(U32(^(ubc.DV_I_45_0_bit | ubc.DV_II_45_0_bit)), r1)
	ANDL(r1, mask)

	Label("f25")
	Comment(
		"if (mask & (DV_II_51_0_bit | DV_II_54_0_bit)) != 0 {",
		"	mask &= (((((W[58] ^ W[59]) >> 29) & 1) - 1) | ^(DV_II_51_0_bit | DV_II_54_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_II_51_0_bit|ubc.DV_II_54_0_bit), mask) // TODO: confirm this is correct
	JE(LabelRef("f26"))
	Load(Param("W").Index(58), r1)
	Load(Param("W").Index(59), r2)
	XORL(r2, r1)
	SHRL(U8(29), r1)
	ANDL(U32(1), r1)
	SUBL(U32(1), r1)
	ORL(U32(^(ubc.DV_II_51_0_bit | ubc.DV_II_54_0_bit)), r1)
	ANDL(r1, mask)

	Label("f26")
	Comment(
		"if (mask & (DV_II_50_0_bit | DV_II_53_0_bit)) != 0 {",
		"	mask &= (((((W[57] ^ W[58]) >> 29) & 1) - 1) | ^(DV_II_50_0_bit | DV_II_53_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_II_50_0_bit|ubc.DV_II_53_0_bit), mask) // TODO: confirm this is correct
	JE(LabelRef("f27"))
	Load(Param("W").Index(57), r1)
	Load(Param("W").Index(58), r2)
	XORL(r2, r1)
	SHRL(U8(29), r1)
	ANDL(U32(1), r1)
	SUBL(U32(1), r1)
	ORL(U32(^(ubc.DV_II_50_0_bit | ubc.DV_II_53_0_bit)), r1)
	ANDL(r1, mask)

	Label("f27")
	Comment(
		"if (mask & (DV_II_52_0_bit | DV_II_54_0_bit)) != 0 {",
		"	mask &= ((((W[56] ^ (W[59] >> 25)) & (1 << 4)) - (1 << 4)) | ^(DV_II_52_0_bit | DV_II_54_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_II_52_0_bit|ubc.DV_II_54_0_bit), mask) // TODO: confirm this is correct
	JE(LabelRef("f28"))
	Load(Param("W").Index(56), r1)
	Load(Param("W").Index(59), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<4), r1)
	SUBL(U32(1<<4), r1)
	ORL(U32(^(ubc.DV_II_52_0_bit | ubc.DV_II_54_0_bit)), r1)
	ANDL(r1, mask)

	Label("f28")
	Comment(
		"if (mask & (DV_II_51_0_bit | DV_II_52_0_bit)) != 0 {",
		"	mask &= ((0 - (((W[56] ^ W[59]) >> 29) & 1)) | ^(DV_II_51_0_bit | DV_II_52_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_II_51_0_bit|ubc.DV_II_52_0_bit), mask) // TODO: confirm this is correct
	JE(LabelRef("f29"))
	Load(Param("W").Index(56), r1)
	Load(Param("W").Index(59), r2)
	XORL(r2, r1)
	SHRL(U8(29), r1)
	ANDL(U32(1), r1)
	NEGL(r1)
	ORL(U32(^(ubc.DV_II_51_0_bit | ubc.DV_II_52_0_bit)), r1)
	ANDL(r1, mask)

	Label("f29")
	Comment(
		"if (mask & (DV_II_49_0_bit | DV_II_52_0_bit)) != 0 {",
		"	mask &= (((((W[56] ^ W[57]) >> 29) & 1) - 1) | ^(DV_II_49_0_bit | DV_II_52_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_II_49_0_bit|ubc.DV_II_52_0_bit), mask) // TODO: confirm this is correct
	JE(LabelRef("f30"))
	Load(Param("W").Index(56), r1)
	Load(Param("W").Index(57), r2)
	XORL(r2, r1)
	SHRL(U8(29), r1)
	ANDL(U32(1), r1)
	SUBL(U32(1), r1)
	ORL(U32(^(ubc.DV_II_49_0_bit | ubc.DV_II_52_0_bit)), r1)
	ANDL(r1, mask)

	Label("f30")
	Comment(
		"if (mask & (DV_II_51_0_bit | DV_II_53_0_bit)) != 0 {",
		"	mask &= ((((W[55] ^ (W[58] >> 25)) & (1 << 4)) - (1 << 4)) | ^(DV_II_51_0_bit | DV_II_53_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_II_51_0_bit|ubc.DV_II_53_0_bit), mask) // TODO: confirm this is correct
	JE(LabelRef("f31"))
	Load(Param("W").Index(55), r1)
	Load(Param("W").Index(58), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<4), r1)
	SUBL(U32(1<<4), r1)
	ORL(U32(^(ubc.DV_II_51_0_bit | ubc.DV_II_53_0_bit)), r1)
	ANDL(r1, mask)

	Label("f31")
	Comment(
		"if (mask & (DV_II_50_0_bit | DV_II_52_0_bit)) != 0 {",
		"	mask &= ((((W[54] ^ (W[57] >> 25)) & (1 << 4)) - (1 << 4)) | ^(DV_II_50_0_bit | DV_II_52_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_II_50_0_bit|ubc.DV_II_52_0_bit), mask) // TODO: confirm this is correct
	JE(LabelRef("f32"))
	Load(Param("W").Index(54), r1)
	Load(Param("W").Index(57), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<4), r1)
	SUBL(U32(1<<4), r1)
	ORL(U32(^(ubc.DV_II_50_0_bit | ubc.DV_II_52_0_bit)), r1)
	ANDL(r1, mask)

	Label("f32")
	Comment(
		"if (mask & (DV_II_49_0_bit | DV_II_51_0_bit)) != 0 {",
		"	mask &= ((((W[53] ^ (W[56] >> 25)) & (1 << 4)) - (1 << 4)) | ^(DV_II_49_0_bit | DV_II_51_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_II_49_0_bit|ubc.DV_II_51_0_bit), mask) // TODO: confirm this is correct
	JE(LabelRef("f33"))
	Load(Param("W").Index(53), r1)
	Load(Param("W").Index(56), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<4), r1)
	SUBL(U32(1<<4), r1)
	ORL(U32(^(ubc.DV_II_49_0_bit | ubc.DV_II_51_0_bit)), r1)
	ANDL(r1, mask)

	Label("f33")
	Comment("mask &= ((((W[51] ^ (W[50] >> 5)) & (1 << 1)) - (1 << 1)) | ^(DV_I_50_2_bit | DV_II_46_2_bit))")
	Load(Param("W").Index(51), r1)
	Load(Param("W").Index(50), r2)
	SHRL(U8(5), r2)
	XORL(r2, r1)
	ANDL(U32(1<<1), r1)
	SUBL(U32(1<<1), r1) // TODO: NOTL?
	ORL(U32(^(ubc.DV_I_50_2_bit | ubc.DV_II_46_2_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= ((((W[48] ^ W[50]) & (1 << 6)) - (1 << 6)) | ^(DV_I_50_2_bit | DV_II_46_2_bit))")
	Load(Param("W").Index(48), r1)
	Load(Param("W").Index(50), r2)
	XORL(r2, r1)
	ANDL(U32(1<<6), r1)
	SUBL(U32(1<<6), r1) // TODO: NOTL?
	ORL(U32(^(ubc.DV_I_50_2_bit | ubc.DV_II_46_2_bit)), r1)
	ANDL(r1, mask)

	Comment(
		"if (mask & (DV_I_51_0_bit | DV_I_52_0_bit)) != 0 {",
		"	mask &= ((0 - (((W[48] ^ W[55]) >> 29) & 1)) | ^(DV_I_51_0_bit | DV_I_52_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_I_51_0_bit|ubc.DV_I_52_0_bit), mask) // TODO: confirm this is correct
	JE(LabelRef("f34"))
	Load(Param("W").Index(48), r1)
	Load(Param("W").Index(55), r2)
	XORL(r2, r1)
	SHRL(U8(29), r1)
	ANDL(U32(1), r1)
	NEGL(r1)
	ORL(U32(^(ubc.DV_I_51_0_bit | ubc.DV_I_52_0_bit)), r1)
	ANDL(r1, mask)

	Label("f34")
	Comment("mask &= ((((W[47] ^ W[49]) & (1 << 6)) - (1 << 6)) | ^(DV_I_49_2_bit | DV_I_51_2_bit))")
	Load(Param("W").Index(47), r1)
	Load(Param("W").Index(49), r2)
	XORL(r2, r1)
	ANDL(U32(1<<6), r1)
	SUBL(U32(1<<6), r1)
	ORL(U32(^(ubc.DV_I_49_2_bit | ubc.DV_I_51_2_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= ((((W[48] ^ (W[47] >> 5)) & (1 << 1)) - (1 << 1)) | ^(DV_I_47_2_bit | DV_II_51_2_bit))")
	Load(Param("W").Index(48), r1)
	Load(Param("W").Index(47), r2)
	SHRL(U8(5), r2)
	XORL(r2, r1)
	ANDL(U32(1<<1), r1)
	SUBL(U32(1<<1), r1)
	ORL(U32(^(ubc.DV_I_47_2_bit | ubc.DV_II_51_2_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= ((((W[46] ^ W[48]) & (1 << 6)) - (1 << 6)) | ^(DV_I_48_2_bit | DV_I_50_2_bit))")
	Load(Param("W").Index(46), r1)
	Load(Param("W").Index(48), r2)
	XORL(r2, r1)
	ANDL(U32(1<<6), r1)
	SUBL(U32(1<<6), r1)
	ORL(U32(^(ubc.DV_I_48_2_bit | ubc.DV_I_50_2_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= ((((W[47] ^ (W[46] >> 5)) & (1 << 1)) - (1 << 1)) | ^(DV_I_46_2_bit | DV_II_50_2_bit))")
	Load(Param("W").Index(47), r1)
	Load(Param("W").Index(46), r2)
	SHRL(U8(5), r2)
	XORL(r2, r1)
	ANDL(U32(1<<1), r1)
	SUBL(U32(1<<1), r1)
	ORL(U32(^(ubc.DV_I_46_2_bit | ubc.DV_II_50_2_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= ((0 - ((W[44] ^ (W[45] >> 5)) & (1 << 1))) | ^(DV_I_51_2_bit | DV_II_49_2_bit))")
	Load(Param("W").Index(44), r1)
	Load(Param("W").Index(45), r2)
	SHRL(U8(5), r2)
	XORL(r2, r1)
	ANDL(U32(1<<1), r1)
	NEGL(r1)
	ORL(U32(^(ubc.DV_I_51_2_bit | ubc.DV_II_49_2_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= ((((W[43] ^ W[45]) & (1 << 6)) - (1 << 6)) | ^(DV_I_47_2_bit | DV_I_49_2_bit))")
	Load(Param("W").Index(43), r1)
	Load(Param("W").Index(45), r2)
	XORL(r2, r1)
	ANDL(U32(1<<6), r1)
	SUBL(U32(1<<6), r1)
	ORL(U32(^(ubc.DV_I_47_2_bit | ubc.DV_I_49_2_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= (((((W[42] ^ W[44]) >> 6) & 1) - 1) | ^(DV_I_46_2_bit | DV_I_48_2_bit))")
	Load(Param("W").Index(42), r1)
	Load(Param("W").Index(44), r2)
	XORL(r2, r1)
	SHRL(U8(6), r1)
	ANDL(U32(1), r1)
	SUBL(U32(1), r1)
	ORL(U32(^(ubc.DV_I_46_2_bit | ubc.DV_I_48_2_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= ((((W[43] ^ (W[42] >> 5)) & (1 << 1)) - (1 << 1)) | ^(DV_II_46_2_bit | DV_II_51_2_bit))")
	Load(Param("W").Index(43), r1)
	Load(Param("W").Index(42), r2)
	SHRL(U8(5), r2)
	XORL(r2, r1)
	ANDL(U32(1<<1), r1)
	SUBL(U32(1<<1), r1)
	ORL(U32(^(ubc.DV_II_46_2_bit | ubc.DV_II_51_2_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= ((((W[42] ^ (W[41] >> 5)) & (1 << 1)) - (1 << 1)) | ^(DV_I_51_2_bit | DV_II_50_2_bit))")
	Load(Param("W").Index(42), r1)
	Load(Param("W").Index(41), r2)
	SHRL(U8(5), r2)
	XORL(r2, r1)
	ANDL(U32(1<<1), r1)
	SUBL(U32(1<<1), r1)
	ORL(U32(^(ubc.DV_I_51_2_bit | ubc.DV_II_50_2_bit)), r1)
	ANDL(r1, mask)

	Comment("mask &= ((((W[41] ^ (W[40] >> 5)) & (1 << 1)) - (1 << 1)) | ^(DV_I_50_2_bit | DV_II_49_2_bit))")
	Load(Param("W").Index(41), r1)
	Load(Param("W").Index(40), r2)
	SHRL(U8(5), r2)
	XORL(r2, r1)
	ANDL(U32(1<<1), r1)
	SUBL(U32(1<<1), r1)
	ORL(U32(^(ubc.DV_I_50_2_bit | ubc.DV_II_49_2_bit)), r1)
	ANDL(r1, mask)

	Comment(
		"if (mask & (DV_I_52_0_bit | DV_II_51_0_bit)) != 0 {",
		"	mask &= ((((W[39] ^ (W[43] >> 25)) & (1 << 4)) - (1 << 4)) | ^(DV_I_52_0_bit | DV_II_51_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_I_52_0_bit|ubc.DV_II_51_0_bit), mask)
	JE(LabelRef("f35"))
	Load(Param("W").Index(39), r1)
	Load(Param("W").Index(43), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<4), r1)
	SUBL(U32(1<<4), r1) // TODO: NOTL?
	ORL(U32(^(ubc.DV_I_52_0_bit | ubc.DV_II_51_0_bit)), r1)
	ANDL(r1, mask)

	Label("f35")
	Comment(
		"if (mask & (DV_I_51_0_bit | DV_II_50_0_bit)) != 0 {",
		"	mask &= ((((W[38] ^ (W[42] >> 25)) & (1 << 4)) - (1 << 4)) | ^(DV_I_51_0_bit | DV_II_50_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_I_51_0_bit|ubc.DV_II_50_0_bit), mask)
	JE(LabelRef("f36"))
	Load(Param("W").Index(38), r1)
	Load(Param("W").Index(42), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<4), r1)
	SUBL(U32(1<<4), r1) // TODO: NOTL?
	ORL(U32(^(ubc.DV_I_51_0_bit | ubc.DV_II_50_0_bit)), r1)
	ANDL(r1, mask)

	Label("f36")
	Comment(
		"if (mask & (DV_I_48_2_bit | DV_I_51_2_bit)) != 0 {",
		"	mask &= ((0 - ((W[37] ^ (W[38] >> 5)) & (1 << 1))) | ^(DV_I_48_2_bit | DV_I_51_2_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_I_48_2_bit|ubc.DV_I_51_2_bit), mask)
	JE(LabelRef("f37"))
	Load(Param("W").Index(37), r1)
	Load(Param("W").Index(38), r2)
	SHRL(U8(5), r2)
	XORL(r2, r1)
	ANDL(U32(1<<1), r1)
	NEGL(r1)
	ORL(U32(^(ubc.DV_I_48_2_bit | ubc.DV_I_51_2_bit)), r1)
	ANDL(r1, mask)

	Label("f37")
	Comment(
		"if (mask & (DV_I_50_0_bit | DV_II_49_0_bit)) != 0 {",
		"	mask &= ((((W[37] ^ (W[41] >> 25)) & (1 << 4)) - (1 << 4)) | ^(DV_I_50_0_bit | DV_II_49_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_I_50_0_bit|ubc.DV_II_49_0_bit), mask)
	JE(LabelRef("f38"))
	Load(Param("W").Index(37), r1)
	Load(Param("W").Index(41), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<4), r1)
	SUBL(U32(1<<4), r1)
	ORL(U32(^(ubc.DV_I_50_0_bit | ubc.DV_II_49_0_bit)), r1)
	ANDL(r1, mask)

	Label("f38")
	Comment(
		"if (mask & (DV_II_52_0_bit | DV_II_54_0_bit)) != 0 {",
		"	mask &= ((0 - ((W[36] ^ W[38]) & (1 << 4))) | ^(DV_II_52_0_bit | DV_II_54_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_II_52_0_bit|ubc.DV_II_54_0_bit), mask)
	JE(LabelRef("f39"))
	Load(Param("W").Index(36), r1)
	Load(Param("W").Index(38), r2)
	XORL(r2, r1)
	ANDL(U32(1<<4), r1)
	NEGL(r1)
	ORL(U32(^(ubc.DV_II_52_0_bit | ubc.DV_II_54_0_bit)), r1)
	ANDL(r1, mask)

	Label("f39")
	Comment("mask &= ((0 - ((W[35] ^ (W[36] >> 5)) & (1 << 1))) | ^(DV_I_46_2_bit | DV_I_49_2_bit))")
	Load(Param("W").Index(35), r1)
	Load(Param("W").Index(36), r2)
	SHRL(U8(5), r2)
	XORL(r2, r1)
	ANDL(U32(1<<1), r1)
	NEGL(r1)
	ORL(U32(^(ubc.DV_I_46_2_bit | ubc.DV_I_49_2_bit)), r1)
	ANDL(r1, mask)

	Comment(
		"if (mask & (DV_I_51_0_bit | DV_II_47_0_bit)) != 0 {",
		"	mask &= ((((W[35] ^ (W[39] >> 25)) & (1 << 3)) - (1 << 3)) | ^(DV_I_51_0_bit | DV_II_47_0_bit))",
		"}",
	)
	TESTL(U32(ubc.DV_I_51_0_bit|ubc.DV_II_47_0_bit), mask)
	JE(LabelRef("f40"))
	Load(Param("W").Index(35), r1)
	Load(Param("W").Index(39), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<3), r1)
	SUBL(U32(1<<3), r1)
	ORL(U32(^(ubc.DV_I_51_0_bit | ubc.DV_II_47_0_bit)), r1)
	ANDL(r1, mask)

	Label("f40")
	Comment("if mask != 0")
	TESTL(U32(0), mask)
	JNE(LabelRef("end"))

	Comment(
		"if (mask & DV_I_43_0_bit) != 0 {",
		"	if not((W[61]^(W[62]>>5))&(1<<1)) != 0 ||",
		"		not(not((W[59]^(W[63]>>25))&(1<<5))) != 0 ||",
		"		not((W[58]^(W[63]>>30))&(1<<0)) != 0 {",
		"		mask &= ^DV_I_43_0_bit",
		"	}",
		"}",
	)
	BTL(U8(0), mask)          // why 0? DV_I_43_0_bit = 1 << 0
	JNC(LabelRef("f41_skip")) // CF = 1 when mask & DV_I_43_0_bit != 0

	Load(Param("W").Index(61), r1)
	Load(Param("W").Index(62), r2)
	SHRL(U8(5), r2)
	XORL(r2, r1)
	ANDL(U32(1<<1), r1)
	NEGL(r1)
	CMPL(r1, U32(0))
	JE(LabelRef("f41_in"))

	Load(Param("W").Index(59), r1)
	Load(Param("W").Index(63), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<5), r1)
	CMPL(r1, U32(0)) // TODO: Review this, original had not(not(...)) instead.
	JNE(LabelRef("f41_in"))

	Load(Param("W").Index(58), r1)
	Load(Param("W").Index(63), r2)
	SHRL(U8(30), r2)
	XORL(r2, r1)
	ANDL(U32(1<<0), r1)
	NEGL(r1)
	CMPL(r1, U32(0))
	JE(LabelRef("f41_in"))

	JMP(LabelRef("f41_skip"))

	Label("f41_in")
	ANDL(U32(^ubc.DV_I_43_0_bit), mask)

	Label("f41_skip")
	Comment(
		"if (mask & DV_I_44_0_bit) != 0 {",
		"	if not((W[62]^(W[63]>>5))&(1<<1)) != 0 ||",
		"		not(not((W[60]^(W[64]>>25))&(1<<5))) != 0 ||",
		"		not((W[59]^(W[64]>>30))&(1<<0)) != 0 {",
		"		mask &= ^DV_I_44_0_bit",
		"	}",
		"}",
	)
	BTL(U8(1), mask)          // why 1? DV_I_44_0_bit = 1 << 1
	JNC(LabelRef("f42_skip")) // CF = 1 when mask & DV_I_44_0_bit != 0

	Load(Param("W").Index(62), r1)
	Load(Param("W").Index(63), r2)
	SHRL(U8(5), r2)
	XORL(r2, r1)
	ANDL(U32(1<<1), r1)
	NEGL(r1)
	CMPL(r1, U32(0))
	JE(LabelRef("f42_in"))

	Load(Param("W").Index(60), r1)
	Load(Param("W").Index(64), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<5), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f42_in"))

	Load(Param("W").Index(59), r1)
	Load(Param("W").Index(64), r2)
	SHRL(U8(30), r2)
	XORL(r2, r1)
	ANDL(U32(1<<0), r1)
	NEGL(r1)
	CMPL(r1, U32(0))
	JE(LabelRef("f42_in"))

	JMP(LabelRef("f42_skip"))

	Label("f42_in")
	ANDL(U32(^ubc.DV_I_44_0_bit), mask)

	Label("f42_skip")

	Comment(
		"if (mask & DV_I_46_2_bit) != 0 {",
		"	mask &= ((^((W[40] ^ W[42]) >> 2)) | ^DV_I_46_2_bit)",
		"}",
	)
	BTL(U8(4), mask)     // why 4? DV_I_46_2_bit = 1 << 4
	JNC(LabelRef("f43")) // CF = 1 when mask & DV_I_46_2_bit != 0
	Load(Param("W").Index(40), r1)
	Load(Param("W").Index(42), r2)
	XORL(r2, r1)
	SHRL(U8(2), r1)
	NOTL(r1)
	ORL(U32(^ubc.DV_I_46_2_bit), r1)
	ANDL(r1, mask)

	Label("f43")
	Comment(
		"if (mask & DV_I_47_2_bit) != 0 {",
		"	if not((W[62]^(W[63]>>5))&(1<<2)) != 0 ||",
		"		not(not((W[41]^W[43])&(1<<6))) != 0 {",
		"		mask &= ^DV_I_47_2_bit",
		"	}",
		"}",
	)
	BTL(U8(6), mask)          // why 6? DV_I_47_2_bit = 1 << 6
	JNC(LabelRef("f44_skip")) // CF = 1 when mask & DV_I_47_2_bit != 0

	Load(Param("W").Index(62), r1)
	Load(Param("W").Index(63), r2)
	SHRL(U8(5), r2)
	XORL(r2, r1)
	ANDL(U32(1<<2), r1)
	NEGL(r1)
	CMPL(r1, U32(0))
	JE(LabelRef("f44_in"))

	Load(Param("W").Index(41), r1)
	Load(Param("W").Index(43), r2)
	XORL(r2, r1)
	ANDL(U32(1<<6), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f44_in")) // TODO: Review this, original had not(not(...)) instead.

	JMP(LabelRef("f44_skip"))

	Label("f44_in")
	ANDL(U32(^ubc.DV_I_47_2_bit), mask)

	Label("f44_skip")

	Comment(
		"if (mask & DV_I_48_2_bit) != 0 {",
		"	if not((W[63]^(W[64]>>5))&(1<<2)) != 0 ||",
		"		not(not((W[48]^(W[49]<<5))&(1<<6))) != 0 {",
		"		mask &= ^DV_I_48_2_bit",
		"	}",
		"}",
	)
	BTL(U8(8), mask)          // why 8? DV_I_48_2_bit = 1 << 8
	JNC(LabelRef("f45_skip")) // CF = 1 when mask & DV_I_48_2_bit != 0

	Load(Param("W").Index(63), r1)
	Load(Param("W").Index(64), r2)
	SHRL(U8(5), r2)
	XORL(r2, r1)
	ANDL(U32(1<<2), r1)
	NEGL(r1)
	CMPL(r1, U32(0))
	JE(LabelRef("f45_in"))

	Load(Param("W").Index(48), r1)
	Load(Param("W").Index(49), r2)
	SHLL(U8(5), r2)
	XORL(r2, r1)
	ANDL(U32(1<<6), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f45_in")) // TODO: Review this, original had not(not(...)) instead.

	JMP(LabelRef("f45_skip"))

	Label("f45_in")
	ANDL(U32(^ubc.DV_I_48_2_bit), mask)

	Label("f45_skip")
	Comment(
		"if (mask & DV_I_49_2_bit) != 0 {",
		"	if not(not((W[49]^(W[50]<<5))&(1<<6))) != 0 ||",
		"		not((W[42]^W[50])&(1<<1)) != 0 ||",
		"		not(not((W[39]^(W[40]<<5))&(1<<6))) != 0 ||",
		"		not((W[38]^W[40])&(1<<1)) != 0 {",
		"		mask &= ^DV_I_49_2_bit",
		"	}",
		"}",
	)
	BTL(U8(10), mask)         // why 10? DV_I_49_2_bit = 1 << 10
	JNC(LabelRef("f46_skip")) // CF = 1 when mask & DV_I_49_2_bit != 0

	Load(Param("W").Index(49), r1)
	Load(Param("W").Index(50), r2)
	SHLL(U8(5), r2)
	XORL(r2, r1)
	ANDL(U32(1<<6), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f46_in")) // TODO: Review this, original had not(not(...)) instead.

	Load(Param("W").Index(42), r1)
	Load(Param("W").Index(50), r2)
	XORL(r2, r1)
	ANDL(U32(1<<1), r1)
	CMPL(r1, U32(0))
	JE(LabelRef("f46_in"))

	Load(Param("W").Index(39), r1)
	Load(Param("W").Index(40), r2)
	SHLL(U8(5), r2)
	XORL(r2, r1)
	ANDL(U32(1<<6), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f46_in")) // TODO: Review this, original had not(not(...)) instead.

	Load(Param("W").Index(38), r1)
	Load(Param("W").Index(40), r2)
	XORL(r2, r1)
	ANDL(U32(1<<1), r1)
	CMPL(r1, U32(0))
	JE(LabelRef("f46_in"))

	JMP(LabelRef("f46_skip"))

	Label("f46_in")
	ANDL(U32(^ubc.DV_I_49_2_bit), mask)

	Label("f46_skip")

	Comment(
		"if (mask & DV_I_50_0_bit) != 0 {",
		"	mask &= (((W[36] ^ W[37]) << 7) | ^DV_I_50_0_bit)",
		"}",
	)
	BTL(U8(11), mask)    // why 11? DV_I_50_0_bit = 1 << 11
	JNC(LabelRef("f47")) // CF = 1 when mask & DV_I_50_0_bit != 0
	Load(Param("W").Index(36), r1)
	Load(Param("W").Index(37), r2)
	XORL(r2, r1)
	SHLL(U8(7), r1)
	ORL(U32(^ubc.DV_I_50_0_bit), r1)
	ANDL(r1, mask)

	Label("f47")
	Comment(
		"if (mask & DV_I_50_2_bit) != 0 {",
		"	mask &= (((W[43] ^ W[51]) << 11) | ^DV_I_50_2_bit)",
		"}",
	)
	BTL(U8(12), mask)    // why 12? DV_I_50_2_bit = 1 << 12
	JNC(LabelRef("f48")) // CF = 1 when mask & DV_I_50_2_bit != 0
	Load(Param("W").Index(43), r1)
	Load(Param("W").Index(51), r2)
	XORL(r2, r1)
	SHLL(U8(11), r1)
	ORL(U32(^ubc.DV_I_50_2_bit), r1)
	ANDL(r1, mask)

	Label("f48")
	Comment(
		"if (mask & DV_I_51_0_bit) != 0 {",
		"	mask &= (((W[37] ^ W[38]) << 9) | ^DV_I_51_0_bit)",
		"}",
	)
	BTL(U8(13), mask)    // why 13? DV_I_51_0_bit = 1 << 13
	JNC(LabelRef("f49")) // CF = 1 when mask & DV_I_51_0_bit != 0
	Load(Param("W").Index(37), r1)
	Load(Param("W").Index(38), r2)
	XORL(r2, r1)
	SHLL(U8(9), r1)
	ORL(U32(^ubc.DV_I_51_0_bit), r1)
	ANDL(r1, mask)

	Label("f49")
	Comment(
		"if (mask & DV_I_51_2_bit) != 0 {",
		"	if not(not((W[51]^(W[52]<<5))&(1<<6))) != 0 ||",
		"		not(not((W[49]^W[51])&(1<<6))) != 0 ||",
		"		not(not((W[37]^(W[37]>>5))&(1<<1))) != 0 ||",
		"		not(not((W[35]^(W[39]>>25))&(1<<5))) != 0 {",
		"		mask &= ^DV_I_51_2_bit",
		"	}",
		"}",
	)
	BTL(U8(14), mask)         // why 14? DV_I_51_2_bit = 1 << 14
	JNC(LabelRef("f50_skip")) // CF = 1 when mask & DV_I_51_2_bit != 0

	Load(Param("W").Index(51), r1)
	Load(Param("W").Index(52), r2)
	SHLL(U8(5), r2)
	XORL(r2, r1)
	ANDL(U32(1<<6), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f50_in"))

	Load(Param("W").Index(49), r1)
	Load(Param("W").Index(51), r2)
	XORL(r2, r1)
	ANDL(U32(1<<6), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f50_in"))

	Load(Param("W").Index(37), r1)
	Load(Param("W").Index(37), r2)
	SHRL(U8(5), r2)
	XORL(r2, r1)
	ANDL(U32(1<<1), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f50_in"))

	Load(Param("W").Index(35), r1)
	Load(Param("W").Index(39), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<5), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f50_in"))

	JMP(LabelRef("f50_skip"))

	Label("f50_in")
	ANDL(U32(^ubc.DV_I_51_2_bit), mask)

	Label("f50_skip")

	Comment(
		"if (mask & DV_I_52_0_bit) != 0 {",
		"	mask &= (((W[38] ^ W[39]) << 11) | ^DV_I_52_0_bit)",
		"}",
	)
	BTL(U8(15), mask)    // why 15? DV_I_52_0_bit = 1 << 15
	JNC(LabelRef("f51")) // CF = 1 when mask & DV_I_52_0_bit != 0
	Load(Param("W").Index(38), r1)
	Load(Param("W").Index(39), r2)
	XORL(r2, r1)
	SHLL(U8(11), r1)
	ORL(U32(^ubc.DV_I_52_0_bit), r1)
	ANDL(r1, mask)

	Label("f51")
	Comment(
		"if (mask & DV_II_46_2_bit) != 0 {",
		"	mask &= (((W[47] ^ W[51]) << 17) | ^DV_II_46_2_bit)",
		"}",
	)
	TESTL(U32(ubc.DV_II_46_2_bit), mask)
	BTL(U8(18), mask)    // why 18? DV_II_46_2_bit = 1 << 18
	JNC(LabelRef("f52")) // CF = 1 when mask & DV_II_46_2_bit != 0
	Load(Param("W").Index(47), r1)
	Load(Param("W").Index(51), r2)
	XORL(r2, r1)
	SHLL(U8(17), r1)
	ORL(U32(^ubc.DV_II_46_2_bit), r1)
	ANDL(r1, mask)

	Label("f52")
	Comment(
		"if (mask & DV_II_48_0_bit) != 0 {",
		"	if not(not((W[36]^(W[40]>>25))&(1<<3))) != 0 ||",
		"		not((W[35]^(W[40]<<2))&(1<<30)) != 0 {",
		"		mask &= ^DV_II_48_0_bit",
		"	}",
		"}",
	)
	BTL(U8(20), mask) // why 20? DV_II_48_0_bit = 1 << 20
	JNC(LabelRef("f53_skip"))

	Load(Param("W").Index(36), r1)
	Load(Param("W").Index(40), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<3), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f53_in"))

	Load(Param("W").Index(35), r1)
	Load(Param("W").Index(40), r2)
	SHLL(U8(2), r2)
	XORL(r2, r1)
	ANDL(U32(1<<30), r1)
	// TODO: missing NOT
	CMPL(r1, U32(0))
	JNE(LabelRef("f53_in"))

	JMP(LabelRef("f53_skip"))

	Label("f53_in")
	ANDL(U32(^ubc.DV_II_48_0_bit), mask)

	Label("f53_skip")

	Comment(
		"if (mask & DV_II_49_0_bit) != 0 {",
		"	if not(not((W[37]^(W[41]>>25))&(1<<3))) != 0 ||",
		"		not((W[36]^(W[41]<<2))&(1<<30)) != 0 {",
		"		mask &= ^DV_II_49_0_bit",
		"	}",
		"}",
	)
	BTL(U8(21), mask) // why 21? DV_II_49_0_bit = 1 << 21
	JNC(LabelRef("f54_skip"))

	Load(Param("W").Index(37), r1)
	Load(Param("W").Index(41), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<3), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f54_in"))

	Load(Param("W").Index(36), r1)
	Load(Param("W").Index(41), r2)
	SHLL(U8(2), r2)
	XORL(r2, r1)
	ANDL(U32(1<<30), r1)
	// TODO: missing NOT
	CMPL(r1, U32(0))
	JNE(LabelRef("f54_in"))

	JMP(LabelRef("f54_skip"))

	Label("f54_in")
	ANDL(U32(^ubc.DV_II_49_0_bit), mask)

	Label("f54_skip")

	Comment(
		"if (mask & DV_II_49_2_bit) != 0 {",
		"	if not(not((W[53]^(W[54]<<5))&(1<<6))) != 0 ||",
		"		not(not((W[51]^W[53])&(1<<6))) != 0 ||",
		"		not((W[50]^W[54])&(1<<1)) != 0 ||",
		"		not(not((W[45]^(W[46]<<5))&(1<<6))) != 0 ||",
		"		not(not((W[37]^(W[41]>>25))&(1<<5))) != 0 ||",
		"		not((W[36]^(W[41]>>30))&(1<<0)) != 0 {",
		"		mask &= ^DV_II_49_2_bit",
		"	}",
		"}",
	)
	BTL(U8(22), mask) // why 22? DV_II_49_2_bit = 1 << 22
	JNC(LabelRef("f55_skip"))

	Load(Param("W").Index(53), r1)
	Load(Param("W").Index(54), r2)
	SHLL(U8(5), r2)
	XORL(r2, r1)
	ANDL(U32(1<<6), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f55_in"))

	Load(Param("W").Index(51), r1)
	Load(Param("W").Index(53), r2)
	XORL(r2, r1)
	ANDL(U32(1<<6), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f55_in"))

	Load(Param("W").Index(50), r1)
	Load(Param("W").Index(54), r2)
	XORL(r2, r1)
	ANDL(U32(1<<1), r1)
	NEGL(r1)
	CMPL(r1, U32(0))
	JE(LabelRef("f55_in"))

	Load(Param("W").Index(45), r1)
	Load(Param("W").Index(46), r2)
	SHLL(U8(5), r2)
	XORL(r2, r1)
	ANDL(U32(1<<6), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f55_in"))

	Load(Param("W").Index(37), r1)
	Load(Param("W").Index(41), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<5), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f55_in"))

	Load(Param("W").Index(36), r1)
	Load(Param("W").Index(41), r2)
	SHRL(U8(30), r2)
	XORL(r2, r1)
	ANDL(U32(1<<0), r1)
	NEGL(r1)
	CMPL(r1, U32(0))
	JE(LabelRef("f55_in"))

	JMP(LabelRef("f55_skip"))

	Label("f55_in")
	ANDL(U32(^ubc.DV_II_49_2_bit), mask)

	Label("f55_skip")

	Comment(
		"if (mask & DV_II_50_0_bit) != 0 {",
		"	if not((W[55]^W[58])&(1<<29)) != 0 ||",
		"		not(not((W[38]^(W[42]>>25))&(1<<3))) != 0 ||",
		"		not((W[37]^(W[42]<<2))&(1<<30)) != 0 {",
		"		mask &= ^DV_II_50_0_bit",
		"	}",
		"}",
	)
	BTL(U8(23), mask) // why 23? DV_II_50_0_bit = 1 << 23
	JNC(LabelRef("f56_skip"))

	Load(Param("W").Index(55), r1)
	Load(Param("W").Index(58), r2)
	XORL(r2, r1)
	ANDL(U32(1<<29), r1)
	NEGL(r1)
	CMPL(r1, U32(0))
	JE(LabelRef("f56_in"))

	Load(Param("W").Index(38), r1)
	Load(Param("W").Index(42), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<3), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f56_in"))

	Load(Param("W").Index(37), r1)
	Load(Param("W").Index(42), r2)
	SHRL(U8(2), r2)
	XORL(r2, r1)
	ANDL(U32(1<<30), r1)
	NEGL(r1)
	CMPL(r1, U32(0))
	JE(LabelRef("f56_in"))

	JMP(LabelRef("f56_skip"))

	Label("f56_in")
	ANDL(U32(^ubc.DV_II_50_0_bit), mask)

	Label("f56_skip")

	Comment(
		"if (mask & DV_II_50_2_bit) != 0 {",
		"	if not(not((W[54]^(W[55]<<5))&(1<<6))) != 0 ||",
		"		not(not((W[52]^W[54])&(1<<6))) != 0 ||",
		"		not((W[51]^W[55])&(1<<1)) != 0 ||",
		"		not((W[45]^W[47])&(1<<1)) != 0 ||",
		"		not(not((W[38]^(W[42]>>25))&(1<<5))) != 0 ||",
		"		not((W[37]^(W[42]>>30))&(1<<0)) != 0 {",
		"		mask &= ^DV_II_50_2_bit",
		"	}",
		"}",
	)
	BTL(U8(24), mask) // why 22? DV_II_50_2_bit = 1 << 24
	JNC(LabelRef("f57_skip"))

	Load(Param("W").Index(54), r1)
	Load(Param("W").Index(55), r2)
	SHLL(U8(5), r2)
	XORL(r2, r1)
	ANDL(U32(1<<6), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f57_in"))

	Load(Param("W").Index(52), r1)
	Load(Param("W").Index(54), r2)
	XORL(r2, r1)
	ANDL(U32(1<<6), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f57_in"))

	Load(Param("W").Index(51), r1)
	Load(Param("W").Index(55), r2)
	XORL(r2, r1)
	ANDL(U32(1<<1), r1)
	NEGL(r1)
	CMPL(r1, U32(0))
	JE(LabelRef("f57_in"))

	Load(Param("W").Index(45), r1)
	Load(Param("W").Index(47), r2)
	XORL(r2, r1)
	ANDL(U32(1<<1), r1)
	NEGL(r1)
	CMPL(r1, U32(0))
	JE(LabelRef("f57_in"))

	Load(Param("W").Index(38), r1)
	Load(Param("W").Index(42), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<5), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f57_in"))

	Load(Param("W").Index(37), r1)
	Load(Param("W").Index(42), r2)
	SHRL(U8(30), r2)
	XORL(r2, r1)
	ANDL(U32(1<<0), r1)
	NEGL(r1)
	CMPL(r1, U32(0))
	JE(LabelRef("f57_in"))

	JMP(LabelRef("f57_skip"))

	Label("f57_in")
	ANDL(U32(^ubc.DV_II_50_2_bit), mask)

	Label("f57_skip")

	Comment(
		"if (mask & DV_II_51_0_bit) != 0 {",
		"	if not(not((W[39]^(W[43]>>25))&(1<<3))) != 0 ||",
		"		not((W[38]^(W[43]<<2))&(1<<30)) != 0 {",
		"		mask &= ^DV_II_51_0_bit",
		"	}",
		"}",
	)
	BTL(U8(25), mask) // why 25? DV_II_51_0_bit = 1 << 25
	JNC(LabelRef("f58_skip"))

	Load(Param("W").Index(39), r1)
	Load(Param("W").Index(43), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<3), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f58_in"))

	Load(Param("W").Index(38), r1)
	Load(Param("W").Index(43), r2)
	SHLL(U8(2), r2)
	XORL(r2, r1)
	ANDL(U32(1<<30), r1)
	NEGL(r1)
	CMPL(r1, U32(0))
	JE(LabelRef("f58_in"))

	JMP(LabelRef("f58_skip"))

	Label("f58_in")
	ANDL(U32(^ubc.DV_II_51_0_bit), mask)

	Label("f58_skip")

	Comment(
		"if (mask & DV_II_51_2_bit) != 0 {",
		"	if not(not((W[55]^(W[56]<<5))&(1<<6))) != 0 ||",
		"		not(not((W[53]^W[55])&(1<<6))) != 0 ||",
		"		not((W[52]^W[56])&(1<<1)) != 0 ||",
		"		not((W[46]^W[48])&(1<<1)) != 0 ||",
		"		not(not((W[39]^(W[43]>>25))&(1<<5))) != 0 ||",
		"		not((W[38]^(W[43]>>30))&(1<<0)) != 0 {",
		"		mask &= ^DV_II_51_2_bit",
		"	}",
		"}",
	)
	BTL(U8(26), mask) // why 26? DV_II_51_2_bit = 1 << 26
	JNC(LabelRef("f59_skip"))

	Load(Param("W").Index(55), r1)
	Load(Param("W").Index(56), r2)
	SHLL(U8(5), r2)
	XORL(r2, r1)
	ANDL(U32(1<<6), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f59_in"))

	Load(Param("W").Index(53), r1)
	Load(Param("W").Index(55), r2)
	XORL(r2, r1)
	ANDL(U32(1<<6), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f59_in"))

	Load(Param("W").Index(52), r1)
	Load(Param("W").Index(56), r2)
	XORL(r2, r1)
	ANDL(U32(1<<1), r1)
	NEGL(r1)
	CMPL(r1, U32(0))
	JE(LabelRef("f59_in"))

	Load(Param("W").Index(46), r1)
	Load(Param("W").Index(48), r2)
	XORL(r2, r1)
	ANDL(U32(1<<1), r1)
	NEGL(r1)
	CMPL(r1, U32(0))
	JE(LabelRef("f59_in"))

	Load(Param("W").Index(39), r1)
	Load(Param("W").Index(43), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<5), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f59_in"))

	Load(Param("W").Index(38), r1)
	Load(Param("W").Index(43), r2)
	SHRL(U8(30), r2)
	XORL(r2, r1)
	ANDL(U32(1<<0), r1)
	NEGL(r1)
	CMPL(r1, U32(0))
	JE(LabelRef("f59_in"))

	JMP(LabelRef("f59_skip"))

	Label("f59_in")
	ANDL(U32(^ubc.DV_II_51_2_bit), mask)

	Label("f59_skip")

	Comment(
		"if (mask & DV_II_52_0_bit) != 0 {",
		"	if not(not((W[59]^W[60])&(1<<29))) != 0 ||",
		"		not(not((W[40]^(W[44]>>25))&(1<<3))) != 0 ||",
		"		not(not((W[40]^(W[44]>>25))&(1<<4))) != 0 ||",
		"		not((W[39]^(W[44]<<2))&(1<<30)) != 0 {",
		"		mask &= ^DV_II_52_0_bit",
		"	}",
		"}",
	)
	BTL(U8(27), mask) // why 27? DV_II_52_0_bit = 1 << 27
	JNC(LabelRef("f60_skip"))

	Load(Param("W").Index(59), r1)
	Load(Param("W").Index(60), r2)
	XORL(r2, r1)
	ANDL(U32(1<<29), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f60_in"))

	Load(Param("W").Index(40), r1)
	Load(Param("W").Index(44), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<3), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f60_in"))

	Load(Param("W").Index(40), r1)
	Load(Param("W").Index(44), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<4), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f60_in"))

	Load(Param("W").Index(39), r1)
	Load(Param("W").Index(44), r2)
	SHLL(U8(2), r2)
	XORL(r2, r1)
	ANDL(U32(1<<30), r1)
	NEGL(r1)
	CMPL(r1, U32(0))
	JE(LabelRef("f60_in"))

	JMP(LabelRef("f60_skip"))

	Label("f60_in")
	ANDL(U32(^ubc.DV_II_52_0_bit), mask)

	Label("f60_skip")

	Comment(
		"if (mask & DV_II_53_0_bit) != 0 {",
		"	if not((W[58]^W[61])&(1<<29)) != 0 ||",
		"		not(not((W[57]^(W[61]>>25))&(1<<4))) != 0 ||",
		"		not(not((W[41]^(W[45]>>25))&(1<<3))) != 0 ||",
		"		not(not((W[41]^(W[45]>>25))&(1<<4))) != 0 {",
		"		mask &= ^DV_II_53_0_bit",
		"	}",
		"}",
	)
	BTL(U8(28), mask) // why 28? DV_II_53_0_bit = 1 << 28
	JNC(LabelRef("f61_skip"))

	Load(Param("W").Index(58), r1)
	Load(Param("W").Index(61), r2)
	XORL(r2, r1)
	ANDL(U32(1<<29), r1)
	NEGL(r1)
	CMPL(r1, U32(0))
	JE(LabelRef("f61_in"))

	Load(Param("W").Index(57), r1)
	Load(Param("W").Index(61), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<4), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f61_in"))

	Load(Param("W").Index(41), r1)
	Load(Param("W").Index(45), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<3), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f61_in"))

	Load(Param("W").Index(41), r1)
	Load(Param("W").Index(45), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<4), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f61_in"))

	JMP(LabelRef("f61_skip"))

	Label("f61_in")
	ANDL(U32(^ubc.DV_II_53_0_bit), mask)

	Label("f61_skip")

	Comment(
		"if (mask & DV_II_54_0_bit) != 0 {",
		"	if not(not((W[58]^(W[62]>>25))&(1<<4))) != 0 ||",
		"		not(not((W[42]^(W[46]>>25))&(1<<3))) != 0 ||",
		"		not(not((W[42]^(W[46]>>25))&(1<<4))) != 0 {",
		"		mask &= ^DV_II_54_0_bit",
		"	}",
		"}",
	)
	BTL(U8(29), mask) // why 29? DV_II_54_0_bit = 1 << 29
	JNC(LabelRef("f62_skip"))

	Load(Param("W").Index(58), r1)
	Load(Param("W").Index(62), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<4), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f62_in"))

	Load(Param("W").Index(42), r1)
	Load(Param("W").Index(46), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<3), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f62_in"))

	Load(Param("W").Index(42), r1)
	Load(Param("W").Index(46), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<4), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f62_in"))

	JMP(LabelRef("f62_skip"))

	Label("f62_in")
	ANDL(U32(^ubc.DV_II_54_0_bit), mask)

	Label("f62_skip")

	Comment(
		"if (mask & DV_II_55_0_bit) != 0 {",
		"	if not(not((W[59]^(W[63]>>25))&(1<<4))) != 0 ||",
		"		not(not((W[57]^(W[59]>>25))&(1<<4))) != 0 ||",
		"		not(not((W[43]^(W[47]>>25))&(1<<3))) != 0 ||",
		"		not(not((W[43]^(W[47]>>25))&(1<<4))) != 0 {",
		"		mask &= ^DV_II_55_0_bit",
		"	}",
		"}",
	)
	BTL(U8(30), mask) // why 30? DV_II_55_0_bit = 1 << 30
	JNC(LabelRef("f63_skip"))

	Load(Param("W").Index(59), r1)
	Load(Param("W").Index(63), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<4), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f63_in"))

	Load(Param("W").Index(57), r1)
	Load(Param("W").Index(59), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<4), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f63_in"))

	Load(Param("W").Index(43), r1)
	Load(Param("W").Index(47), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<3), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f63_in"))

	Load(Param("W").Index(43), r1)
	Load(Param("W").Index(47), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<4), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f63_in"))

	JMP(LabelRef("f63_skip"))

	Label("f63_in")
	ANDL(U32(^ubc.DV_II_55_0_bit), mask)

	Label("f63_skip")

	Comment(
		"if (mask & DV_II_56_0_bit) != 0 {",
		"	if not(not((W[60]^(W[64]>>25))&(1<<4))) != 0 ||",
		"		not(not((W[44]^(W[48]>>25))&(1<<3))) != 0 ||",
		"		not(not((W[44]^(W[48]>>25))&(1<<4))) != 0 {",
		"		mask &= ^DV_II_56_0_bit",
		"	}",
		"}",
	)
	BTL(U8(31), mask) // why 31? DV_II_56_0_bit = 1 << 31
	JNC(LabelRef("f64_skip"))

	Load(Param("W").Index(60), r1)
	Load(Param("W").Index(64), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<4), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f64_in"))

	Load(Param("W").Index(44), r1)
	Load(Param("W").Index(48), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<3), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f64_in"))

	Load(Param("W").Index(44), r1)
	Load(Param("W").Index(48), r2)
	SHRL(U8(25), r2)
	XORL(r2, r1)
	ANDL(U32(1<<4), r1)
	CMPL(r1, U32(0))
	JNE(LabelRef("f64_in"))

	JMP(LabelRef("f64_skip"))

	Label("f64_in")
	ANDL(U32(^ubc.DV_II_56_0_bit), mask)

	Label("f64_skip")

	Label("end")
	Store(mask, ReturnIndex(0))

	RET()
	Generate()
}
