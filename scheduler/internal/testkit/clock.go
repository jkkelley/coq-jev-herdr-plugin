// Package testkit is the scheduler's test fakes (SPEC-16.K k-testkit): the fake
// executor, the world on a temporary directory, the settable clock and the record
// builder. Every domain's tests compile against it from their first day; a fake a
// domain needs that is missing here is a question to the architect, not an edit.
package testkit

import (
	"sync"
	"time"

	"coq/scheduler/internal/core"
)

// Clock is a settable core.Clock. Advance moves it, so deadlines, windows and
// backoff are tested without waiting. It is safe for concurrent use.
type Clock struct {
	mu  sync.Mutex
	now time.Time
}

var _ core.Clock = (*Clock)(nil)

// NewClock returns a clock set to t, in UTC.
func NewClock(t time.Time) *Clock { return &Clock{now: t.UTC()} }

// Now returns the clock's time in UTC.
func (c *Clock) Now() time.Time {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.now
}

// Set moves the clock to t.
func (c *Clock) Set(t time.Time) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.now = t.UTC()
}

// Advance moves the clock forward by d and returns the new time.
func (c *Clock) Advance(d time.Duration) time.Time {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.now = c.now.Add(d)
	return c.now
}
