//go:build !noasm && gc && amd64
// +build !noasm,gc,amd64

package sha1cd

// blockAMD64 hashes the message p into the current state in dig.
//
//go:noescape
func blockAMD64(dig *digest, p []byte)

func block(dig *digest, p []byte) {
	blockAMD64(dig, p)
}
