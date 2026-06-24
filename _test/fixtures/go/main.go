// Minimal module used by the cache-go integration tests. It pulls in a single
// small dependency so that go.sum exists (for the cache key) and the module
// cache has something to save and restore.
package main

import (
	"fmt"

	"github.com/google/uuid"
)

func main() {
	fmt.Println(uuid.New().String())
}
