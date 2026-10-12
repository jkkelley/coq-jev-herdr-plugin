package core

import "time"

// SeatStatus is what the observer saw of a seat this tick (SPEC-16.C c-status).
type SeatStatus string

// The seat statuses. Nothing is judged on unknown.
const (
	SeatAbsent  SeatStatus = "absent"
	SeatIdle    SeatStatus = "idle"
	SeatBusy    SeatStatus = "busy"
	SeatUnknown SeatStatus = "unknown"
)

// Seat is what the scheduler knows about one seat from the executor's observation
// verbs (SPEC-16 c-seat).
type Seat struct {
	// Name is the role label with the ticket lowercased, as the seat script names it.
	Name   string
	Role   string
	Ticket string
	Status SeatStatus
	// Since is the first tick that saw the current status; it resets on change.
	Since time.Time
}
