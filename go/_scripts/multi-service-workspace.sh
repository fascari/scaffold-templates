#!/usr/bin/env bash
# Multi-service workspace generator. Invoked by go/copier.yml via _tasks.
# Receives values as environment variables (set by copier).
#
# Required env:
#   MODULE_PATH        — e.g. github.com/user/project
#   PROJECT_NAME       — workspace name
#   GO_VERSION         — e.g. 1.26.1
#   INCLUDE_DOCKERFILE — "true" or "false"
#   SERVICE_NAMES      — comma-separated service names

set -euo pipefail

mkdir -p services bin

for svc in $(echo "$SERVICE_NAMES" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'); do
	[ -z "$svc" ] && continue
	svcdir="services/$svc"
	mkdir -p "$svcdir/cmd/api" "$svcdir/internal"

	# go.mod with replace directive pointing to local kit
	cat > "$svcdir/go.mod" <<EOF
module ${MODULE_PATH}/services/${svc}

go ${GO_VERSION}

require ${MODULE_PATH}/kit v0.0.0

replace ${MODULE_PATH}/kit => ../../kit
EOF

	# cmd/api/main.go — minimal HTTP server using kit packages
	cat > "$svcdir/cmd/api/main.go" <<EOF
package main

import (
	"net/http"
	"os"

	"${MODULE_PATH}/kit/httpjson"
	"${MODULE_PATH}/kit/logger"
)

func main() {
	log := logger.New("${svc}")
	addr := os.Getenv("ADDR")
	if addr == "" {
		addr = ":8080"
	}
	mux := http.NewServeMux()
	mux.HandleFunc("/health", func(w http.ResponseWriter, _ *http.Request) {
		_ = httpjson.Write(w, http.StatusOK, map[string]string{"status": "ok"})
	})
	log.Info("starting", "addr", addr)
	if err := http.ListenAndServe(addr, mux); err != nil {
		log.Error("server stopped", "err", err)
		os.Exit(1)
	}
}
EOF

	# service README
	cat > "$svcdir/README.md" <<EOF
# ${svc}

Service in the \`${PROJECT_NAME}\` workspace.

## Run

\`\`\`bash
cd services/${svc}
go run ./cmd/api
\`\`\`
EOF

	# optional service Dockerfile
	if [ "$INCLUDE_DOCKERFILE" = "True" ] || [ "$INCLUDE_DOCKERFILE" = "true" ]; then
		cat > "$svcdir/Dockerfile" <<EOF
FROM golang:${GO_VERSION}-alpine AS builder
WORKDIR /workspace
COPY ../../kit ./kit
COPY . ./services/${svc}
WORKDIR /workspace/services/${svc}
RUN go build -o /out/app ./cmd/api

FROM alpine:3.20
COPY --from=builder /out/app /app
ENTRYPOINT ["/app"]
EOF
	fi

	touch "$svcdir/internal/.gitkeep"
done
