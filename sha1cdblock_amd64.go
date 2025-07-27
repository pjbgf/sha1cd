//go:build !noasm && gc && amd64 && !arm64
// +build !noasm,gc,amd64,!arm64

package sha1cd

// blockAMD64 processes all complete chunks in p, updating the hash state h.
// It handles the for loop and collision detection internally.
//
//go:noescape
func blockAMD64(h []uint32, p []byte) bool

func block(dig *digest, p []byte) {
	if forceGeneric {
		blockGeneric(dig, p)
		return
	}

	c := blockAMD64(dig.h[:], p)
	dig.col = dig.col || c
}
