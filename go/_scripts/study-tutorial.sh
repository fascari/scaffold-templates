#!/usr/bin/env bash
# Study-tutorial generator. Invoked by go/copier.yml via _tasks.
# Receives values as environment variables (set by copier).
#
# Required env:
#   MODULE_PATH      — e.g. github.com/user/project
#   ENTRYPOINT       — "cli" or "rest"
#   INCLUDE_STORE    — "true" or "false"
#   DOMAIN_NAMES     — comma-separated package names

set -euo pipefail

DOMAINS=$(echo "$DOMAIN_NAMES" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | { grep -v '^$' || true; })

# Per-domain packages: internal/<name>/<name>.go + <name>_test.go
for name in $DOMAINS; do
	pkg_dir="internal/$name"
	mkdir -p "$pkg_dir"
	cat > "$pkg_dir/$name.go" <<EOF
// Package $name explores the "$name" concurrency scenario.
package $name

import "context"

// Params is the input for Run.
type Params struct{}

// Result is the output of Run.
type Result struct{}

// Run executes the $name scenario. Replace this skeleton with the
// concrete pattern you want to study (channels, goroutine pool, etc).
func Run(ctx context.Context, p Params) (Result, error) {
	_ = ctx
	_ = p
	return Result{}, nil
}
EOF
	cat > "$pkg_dir/${name}_test.go" <<EOF
package $name

import (
	"context"
	"testing"

	"go.uber.org/goleak"
)

func TestRun(t *testing.T) {
	defer goleak.VerifyNone(t)

	ctx := context.Background()
	if _, err := Run(ctx, Params{}); err != nil {
		t.Fatalf("Run: %v", err)
	}
}
EOF
done

# Optional shared store: map+sync.RWMutex (deliberately not sync.Map so
# scenarios can reason about explicit critical sections).
if [ "$INCLUDE_STORE" = "True" ] || [ "$INCLUDE_STORE" = "true" ]; then
	mkdir -p internal/store
	cat > internal/store/store.go <<'EOF'
// Package store provides an in-memory key/value store guarded by
// sync.RWMutex. Intentionally NOT sync.Map: pedagogy needs explicit
// critical sections so scenarios can illustrate races and -race output.
package store

import "sync"

// Store is a goroutine-safe map keyed by string.
type Store[T any] struct {
	mu sync.RWMutex
	m  map[string]T
}

// New returns an empty Store.
func New[T any]() *Store[T] {
	return &Store[T]{m: make(map[string]T)}
}

// Get returns the value and a presence flag.
func (s *Store[T]) Get(k string) (T, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	v, ok := s.m[k]
	return v, ok
}

// Set assigns v to key k.
func (s *Store[T]) Set(k string, v T) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.m[k] = v
}

// Len returns the current number of entries.
func (s *Store[T]) Len() int {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return len(s.m)
}
EOF
	cat > internal/store/store_test.go <<'EOF'
package store

import "testing"

func TestStoreSetGetLen(t *testing.T) {
	s := New[int]()
	s.Set("a", 1)
	s.Set("b", 2)

	if got, ok := s.Get("a"); !ok || got != 1 {
		t.Fatalf("Get(a): got=%d ok=%v", got, ok)
	}
	if got := s.Len(); got != 2 {
		t.Fatalf("Len: got=%d want=2", got)
	}
}
EOF
fi

# Documentation stubs (text-only units)
mkdir -p docs
cat > docs/foundations.md <<'EOF'
# Foundations

Mental models, primitives and vocabulary that anchor every scenario in
this study. Keep it text-only — runnable demos live under `internal/`.

<!-- TODO: GMP scheduler, happens-before, CSP vs shared-memory, etc. -->
EOF
cat > docs/decision-guide.md <<'EOF'
# Decision guide

Use this as a flowchart when deciding which primitive to reach for:
channels vs mutexes vs errgroups vs synctest.

<!-- TODO: decision tree, common anti-patterns, when NOT to use X. -->
EOF

# Dispatcher entrypoint
if [ "$ENTRYPOINT" = "cli" ]; then
	mkdir -p cmd/concurrency
	IMPORTS=""
	CASES=""
	for name in $DOMAINS; do
		IMPORTS="${IMPORTS}	\"${MODULE_PATH}/internal/${name}\"
"
		CASES="${CASES}	case \"${name}\":
		if _, err := ${name}.Run(ctx, ${name}.Params{}); err != nil {
			log.Fatalf(\"%s: %v\", *pattern, err)
		}
"
	done
	cat > cmd/concurrency/main.go <<EOF
// Command concurrency dispatches one scenario by --pattern flag.
// Example: go run ./cmd/concurrency --pattern goroutines
package main

import (
	"context"
	"flag"
	"log"

${IMPORTS})

func main() {
	pattern := flag.String("pattern", "", "scenario to run")
	flag.Parse()

	if *pattern == "" {
		log.Fatal("--pattern is required")
	}

	ctx := context.Background()
	_ = ctx
	switch *pattern {
${CASES}	default:
		log.Fatalf("unknown pattern: %q", *pattern)
	}
}
EOF
else
	mkdir -p cmd/api
	IMPORTS=""
	ROUTES=""
	for name in $DOMAINS; do
		IMPORTS="${IMPORTS}	\"${MODULE_PATH}/internal/${name}\"
"
		ROUTES="${ROUTES}	mux.HandleFunc(\"POST /run/${name}\", func(w http.ResponseWriter, r *http.Request) {
		if _, err := ${name}.Run(r.Context(), ${name}.Params{}); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusNoContent)
	})
"
	done
	cat > cmd/api/main.go <<EOF
// Command api exposes one POST endpoint per scenario.
// Example: curl -X POST http://localhost:8080/run/goroutines
package main

import (
	"log"
	"net/http"

${IMPORTS})

func main() {
	mux := http.NewServeMux()
${ROUTES}
	addr := ":8080"
	log.Printf("listening on %s", addr)
	if err := http.ListenAndServe(addr, mux); err != nil {
		log.Fatal(err)
	}
}
EOF
fi
