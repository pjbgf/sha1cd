# go-hardened-sha1

A Go implementation of SHA1 with counter-cryptanalysis, which detects
collision attacks. 

The `cgo/lib` code is a carbon copy of the [original code], based on
the award winning white paper by Marc Stevens.

## Usage

```golang
import "github.com/pjbgf/go-hardened-sha1"

func test(){
	data := []byte("data to be sha1 hashed")
	h := sha1.Sum(data)
}
```

## References
- https://shattered.io/
- https://github.com/cr-marcstevens/sha1collisiondetection


[original code]: https://github.com/cr-marcstevens/sha1collisiondetection
[white paper]: https://marc-stevens.nl/research/papers/C13-S.pdf
