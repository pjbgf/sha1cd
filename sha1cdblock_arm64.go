//go:build !noasm && gc && arm64 && !amd64
// +build !noasm,gc,arm64,!amd64

package sha1cd

// blockARM64 processes all complete chunks in p, updating the hash state h.
// It handles the for loop and collision detection internally.
//
//go:noescape
func blockARM64(h []uint32, p []byte) bool

func block(dig *digest, p []byte) {
	if forceGeneric {
		blockGeneric(dig, p)
		return
	}

	c := blockARM64(dig.h[:], p)
	dig.col = dig.col || c
}
