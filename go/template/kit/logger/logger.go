// Package logger wraps the stdlib slog with sensible defaults.
package logger

import (
	"log/slog"
	"os"
)

func New(service string) *slog.Logger {
	h := slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelInfo})
	return slog.New(h).With("service", service)
}
