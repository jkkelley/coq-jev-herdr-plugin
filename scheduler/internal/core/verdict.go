package core

import "time"

// Verdict is the executor's answer to one Run, carried unchanged from the proto's
// RunResponse (SPEC-16 c-verdict, SPEC-16.H h-proto).
type Verdict struct {
	ExitCode int
	TimedOut bool
	// Refused means the executor did not run the verb (not in its table, a bad
	// argument); Refusal says why.
	Refused bool
	Refusal string
	// StdoutTail and StderrTail are the last lines, bounded by the executor's
	// configuration, for the log and the 500 note.
	StdoutTail string
	StderrTail string
	StartedAt  time.Time
	FinishedAt time.Time
}
