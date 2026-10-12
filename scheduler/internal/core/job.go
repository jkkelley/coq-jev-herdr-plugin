package core

import (
	"strings"
	"time"
)

// JobState is where a job is in its life (SPEC-16.D d-states).
type JobState string

// The job states.
const (
	JobPending    JobState = "pending"
	JobHeld       JobState = "held"
	JobRunning    JobState = "running"
	JobConfirming JobState = "confirming"
	JobDone       JobState = "done"
	JobDead       JobState = "dead"
)

// JobKey is the idempotency key of a job and its file name: the record id, a colon,
// the action, a colon, the target seat or file (SPEC-16.D d-idem-key).
func JobKey(recordID, action, target string) string {
	return strings.Join([]string{recordID, action, target}, ":")
}

// JobSpec is the part of a job a plan decides: one executor verb with its
// arguments, about one record, and the keys it waits on. The engine stores it as a
// Job; whoever plans it never touches the store or the executor.
type JobSpec struct {
	// Key is the idempotency key, see JobKey.
	Key string
	// Verb and Args are the executor verb and its positional arguments; never a
	// shell line.
	Verb string
	Args []string
	// RecordID, Ticket, Seat and Role say what the job is about, for the log and
	// for confirmation.
	RecordID string
	Ticket   string
	Seat     string
	Role     string
	// After lists keys of jobs that must finish first. A plain key is satisfied by
	// done only; a key with a trailing question mark by done or dead.
	After []string
}

// Job is one side effect to perform through the executor, durable in the state
// directory, identified by its key so a restart never performs it twice
// (SPEC-16 c-job).
type Job struct {
	JobSpec
	// Attempt is how many Runs have started; MaxAttempts is when it is dead;
	// NextDue is when it may run next.
	Attempt     int
	MaxAttempts int
	NextDue     time.Time
	State       JobState
	// HoldReason says why a held job is held: quiet, cap, absent, shared, order.
	HoldReason string
	// LastExit and LastReason are what the last Run said.
	LastExit   int
	LastReason string
}
