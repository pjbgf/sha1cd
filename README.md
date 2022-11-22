# sha1dc

A Go implementation of SHA1 with counter-cryptanalysis, which detects
collision attacks. 

The `cgo/lib` code is a carbon copy of the [original code], based on
the award winning white paper by Marc Stevens.

The Go implementation is largely based off Go's generic sha1.
At present no SIMD optimisations have been implemented.

## Usage

```golang
import "github.com/pjbgf/sha1cd"

func test(){
	data := []byte("data to be sha1 hashed")
	h := sha1.Sum(data)
}
```

## References
- https://shattered.io/
- https://github.com/cr-marcstevens/sha1collisiondetection
- https://csrc.nist.gov/Projects/Cryptographic-Algorithm-Validation-Program/Secure-Hashing#shavs

## Use of the Original Implementation
- https://github.com/git/git/commit/28dc98e343ca4eb370a29ceec4c19beac9b5c01e
- https://github.com/libgit2/libgit2/pull/4136

[original code]: https://github.com/cr-marcstevens/sha1collisiondetection
[white paper]: https://marc-stevens.nl/research/papers/C13-S.pdf
