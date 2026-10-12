package core

import (
	"errors"
	"time"
)

// AtLayout is the form of a record's at and of every time on the control plane:
// UTC to the second with a Z suffix (events/schema/event.schema.json#at).
const AtLayout = "2006-01-02T15:04:05Z"

// Record is one entry of the event log as the writer wrote it, plus where intake
// first saw it (SPEC-16 c-record). An optional field the file does not carry is
// the zero value, except Attempt, which is 1 when absent, as the bash runner reads
// it. The scheduler branches on Kind, Code, Attempt and the escalation count only;
// Note is for humans and no domain branches on it.
type Record struct {
	// ID is the UTC stamp, the code and a five-character suffix: the sort key of
	// the log and the trace id of every log line about the record.
	ID string
	// At is when the record was written, in UTC; deadlines and stalls are measured
	// from here, never from the file's mtime.
	At time.Time
	// Code is 100 to 599.
	Code int
	// Seat is the seat that wrote it; a record from one of the scheduler's own
	// seats is never routed.
	Seat string
	// Kind is matched as a string and never enumerated in Go.
	Kind string
	// Ticket is the work order id, or empty.
	Ticket string
	// To is the addressee role of a routed or escalated record, or empty.
	To string
	// Attempt is a seat's try count on one ticket, 1 to 3; 1 when absent.
	Attempt int
	// SHA and PR are the pull request head and number, copied onto the wake line
	// by a row that says with pr.
	SHA string
	PR  int
	// Action, Answer and Policy are the break glass and policy fields, carried
	// through and never interpreted outside their domains.
	Action string
	Answer string
	Policy string
	// Note is prose for humans.
	Note string
	// Root and Path are the root the record was first seen in and its path there;
	// scheduler-side only, never written back.
	Root string
	Path string
}

// Ref is a reference to a record in a root, as Source.List returns it without
// opening the file (SPEC-16.A a-source).
type Ref struct {
	ID   string
	Root string
	Path string
}

// ErrUnreadable is the error Source.Read wraps when a record file does not parse
// or lacks a required field; intake writes the ledger word unreadable for it.
var ErrUnreadable = errors.New("unreadable")
