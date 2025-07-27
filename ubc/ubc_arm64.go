//go:build !noasm && gc && arm64 && !amd64
// +build !noasm,gc,arm64,!amd64

package ubc

//go:noescape
func CalculateDvMaskARM64(W [80]uint32) uint32

//go:nosplit
func CalculateDvMask(W [80]uint32) uint32 {
	return CalculateDvMaskARM64(W)
}
