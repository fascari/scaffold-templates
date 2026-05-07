package apperror

import (
	"errors"
	"fmt"
)

type AppError struct {
	Code    string `json:"code"`
	Message string `json:"message"`
	err     error
}

func New(code string, message string, args ...any) AppError {
	return AppError{
		Code:    code,
		Message: fmt.Sprintf(message, args...),
	}
}

func As(err error, code string) bool {
	var appError AppError
	if errors.As(err, &appError) {
		return appError.Code == code
	}
	return false
}

func (e AppError) Error() string {
	return e.Message
}

func (e AppError) Unwrap() error {
	return e.err
}
