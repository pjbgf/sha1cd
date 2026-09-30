//go:build !noasm && gc && amd64

package test

import (
	"os"
	"testing"
	_ "unsafe"
)

//go:linkname hasSHANI github.com/pjbgf/sha1cd.hasSHANI
var hasSHANI bool

//go:linkname hasAVX2 github.com/pjbgf/sha1cd.hasAVX2
var hasAVX2 bool

// Setting SHA1CD_TEST_NOSHANI runs the whole package against the AVX2
// fallback, which the native implementation otherwise hides on CPUs with
// SHA-NI.
func init() {
	if os.Getenv("SHA1CD_TEST_NOSHANI") != "" {
		hasSHANI = false
	}
}

func TestNativeImplementation(t *testing.T) {
	switch {
	case hasSHANI:
		t.Log("native is SHA-NI")
	case hasAVX2:
		t.Log("native is AVX2")
	default:
		t.Log("native is generic")
	}
}
