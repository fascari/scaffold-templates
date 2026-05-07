// Package clock abstracts time.Now so it can be faked in tests.
package clock

import "time"

type Clock interface {
	Now() time.Time
}

type real struct{}

func (real) Now() time.Time { return time.Now() }

func Real() Clock { return real{} }

type Fake struct {
	current time.Time
}

func NewFake(t time.Time) *Fake { return &Fake{current: t} }

func (f *Fake) Now() time.Time { return f.current }

func (f *Fake) Advance(d time.Duration) { f.current = f.current.Add(d) }

func (f *Fake) Set(t time.Time) { f.current = t }
