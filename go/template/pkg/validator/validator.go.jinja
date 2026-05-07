package validator

import (
	"sync"

	"github.com/go-playground/validator/v10"
)

var (
	instance *validator.Validate
	once     sync.Once
)

// Validator returns the singleton validator instance.
func Validator() *validator.Validate {
	once.Do(func() {
		instance = validator.New()
	})
	return instance
}

// Validate validates the given struct using struct tags.
func Validate(s any) error {
	return Validator().Struct(s)
}
