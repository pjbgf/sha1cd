//go:build ignore
// +build ignore

package main

import (
	. "github.com/mmcloughlin/avo/build"
	"github.com/mmcloughlin/avo/buildtags"
	. "github.com/mmcloughlin/avo/operand"
	"github.com/pjbgf/sha1cd/ubc"
)

//go:generate go run ubc_dvs_amd64_asm.go -out ubc_dvs_amd64.s

const (
	DvTypeOffset = 0
	DvKOffset    = 4
	DvBOffset    = 8
	TestTOffset  = 12
	MaskIOffset  = 16
	MaskBOffset  = 20

	DvsSizeBytes = 6 + 80
)

func main() {
	Constraint(buildtags.Not("noasm").ToConstraint())
	Constraint(buildtags.Term("gc").ToConstraint())
	Constraint(buildtags.Term("amd64").ToConstraint())

	data := GLOBL("sha1_dvs", RODATA|NOPTR)
	_ = data.Offset(0*DvsSizeBytes + DvTypeOffset)

	for i, dvs := range ubc.SHA1_dvs() {
		offset := i * DvsSizeBytes * 4
		DATA(offset+DvTypeOffset, U32(dvs.DvType))
		DATA(offset+DvKOffset, U32(dvs.DvK))
		DATA(offset+DvBOffset, U32(dvs.DvB))
		DATA(offset+TestTOffset, U32(dvs.TestT))
		DATA(offset+MaskIOffset, U32(dvs.MaskI))
		DATA(offset+MaskBOffset, U32(dvs.MaskB))

		for j, em := range dvs.Dm {
			DATA(offset+24+(j*4), U32(em))
		}
	}

	Generate()
}
