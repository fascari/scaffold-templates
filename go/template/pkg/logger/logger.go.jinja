package logger

import (
	"os"

	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
)

// Init configures the global zerolog logger with the given level.
func Init(level ...string) {
	logLevel := zerolog.InfoLevel
	if len(level) > 0 {
		if parsedLevel, err := zerolog.ParseLevel(level[0]); err == nil {
			logLevel = parsedLevel
		}
	}

	zerolog.SetGlobalLevel(logLevel)
	log.Logger = zerolog.New(zerolog.ConsoleWriter{
		Out:        os.Stdout,
		TimeFormat: "15:04:05",
	}).With().Timestamp().Logger()
}
