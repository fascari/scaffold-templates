// Package httpjson provides helpers for reading and writing JSON over HTTP.
package httpjson

import (
	"encoding/json"
	"net/http"
)

func Write(w http.ResponseWriter, status int, v any) error {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	return json.NewEncoder(w).Encode(v)
}

func Read(r *http.Request, v any) error {
	defer r.Body.Close()
	return json.NewDecoder(r.Body).Decode(v)
}

func Error(w http.ResponseWriter, status int, code, message string) {
	_ = Write(w, status, map[string]string{"code": code, "message": message})
}
