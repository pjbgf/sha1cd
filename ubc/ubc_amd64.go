//go:build !noasm && gc && amd64 && !arm64
// +build !noasm,gc,amd64,!arm64

package ubc

//go:noescape
func CalculateDvMaskAMD64(W [80]uint32) uint32

//go:nosplit
func CalculateDvMask(W [80]uint32) uint32 {
	return CalculateDvMaskAMD64(W)
}
