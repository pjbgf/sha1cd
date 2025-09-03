module github.com/pjbgf/sha1cd

go 1.22

toolchain go1.24.6

// Temporary dependency to be removed once CPU feature checks
// are natively supported. https://github.com/golang/go/issues/73787
require github.com/klauspost/cpuid/v2 v2.3.0

require golang.org/x/sys v0.30.0 // indirect
