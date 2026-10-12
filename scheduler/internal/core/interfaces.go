package core

import (
	"context"
	"time"
)

// Source lists and reads records (SPEC-16.A a-source). The file source implements
// it now and a bus source later; the ledger still decides exactly-once.
type Source interface {
	// List returns references to records newer than sinceID across every root, in
	// id order, without opening a file.
	List(sinceID string) ([]Ref, error)
	// Read returns the Record a reference names, or an error wrapping ErrUnreadable.
	Read(ref Ref) (Record, error)
}

// Ledger is the routed ledger: one word per record id, claimed before any act
// (SPEC-16.A a-ledger).
type Ledger interface {
	// Claim reports whether this call won the claim on id.
	Claim(id string) (bool, error)
	// Set writes the ledger word for id.
	Set(id, word string) error
	// Get reads the ledger word for id; found is false when id has no entry.
	Get(id string) (word string, found bool, err error)
	// Interrupted lists ids still claimed at start with no job behind them.
	Interrupted() ([]string, error)
}

// Executor runs one job's verb on the host (SPEC-16.H h-proto). The gRPC client
// implements it; the testkit's fake records every call and answers from a script.
type Executor interface {
	Run(ctx context.Context, job Job) Verdict
	Health(ctx context.Context) error
}

// Clock is the only source of the time. Now is in UTC; nothing calls the system
// clock directly, so tests set it.
type Clock interface {
	Now() time.Time
}

// Table is the loaded routes table (SPEC-16.B b-match).
type Table interface {
	// Match returns the first row that holds for the record and its ticket's
	// escalation count; ok is false when none does.
	Match(rec Record, escalations int) (row Row, ok bool)
	// Rows lists the rows in table order.
	Rows() []Row
	// Version names the loaded file's hash.
	Version() string
}

// JobStore keeps one file per job under the state directory (SPEC-16.D d-store).
type JobStore interface {
	// Put writes the job, creating or replacing it by key.
	Put(job Job) error
	// Get reads one job; found is false when the key has none.
	Get(key string) (job Job, found bool, err error)
	// Due lists the pending jobs whose next-due time is at or before now.
	Due(now time.Time) ([]Job, error)
	// ByRecord lists the jobs about one record.
	ByRecord(recordID string) ([]Job, error)
	// ByState lists the jobs in one state.
	ByState(state JobState) ([]Job, error)
}

// SeatObserver returns every seat the executor can see, with its status, in one
// call per tick (SPEC-16.C c-status).
type SeatObserver interface {
	Observe(ctx context.Context) ([]Seat, error)
}

// Latches say a verdict once across restarts; a latch is a file (SPEC-16.F f-latch).
type Latches interface {
	// Take reports whether the latch was free and is now taken.
	Take(name string) (bool, error)
	// Drop frees the latch; dropping a free latch is not an error.
	Drop(name string) error
}
