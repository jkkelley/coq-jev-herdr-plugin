package core

import "time"

// Counters are the counts of the status answer, reset at start (SPEC-16.I i-status,
// i-metrics). There is no metrics server: these live in the answer only.
type Counters struct {
	Records RecordCounters
	Jobs    JobCounters
	Wakes   WakeCounters
	Shadow  ShadowCounters
}

// RecordCounters count records since start by what became of them.
type RecordCounters struct {
	Listed      uint64
	Routed      uint64
	Ignored     uint64
	Unrouted    uint64
	Own         uint64
	Unreadable  uint64
	Interrupted uint64
}

// JobCounters count jobs by state.
type JobCounters struct {
	Pending    uint64
	Held       uint64
	Running    uint64
	Confirming uint64
	Done       uint64
	Dead       uint64
}

// WakeCounters count wakes and how each was confirmed.
type WakeCounters struct {
	Sent              uint64
	ConfirmedByRecord uint64
	ConfirmedByBusy   uint64
	Resent            uint64
	Unconfirmed       uint64
	HeldForQuiet      uint64
}

// ShadowCounters compare shadow decisions with the bash runner's, in shadow mode.
type ShadowCounters struct {
	Compared    uint64
	Agreeing    uint64
	Mismatching uint64
	Since       time.Time
}

// HeldJob is one held job and why.
type HeldJob struct {
	Key    string
	Reason string
}

// DeadJob is one dead-lettered job.
type DeadJob struct {
	Key      string
	Attempts int
	Reason   string
	At       time.Time
}

// Stall is one open latched stall (SPEC-16.F f-stall).
type Stall struct {
	GateID string
	Ticket string
	Kind   string
	Seat   string
	Status SeatStatus
}

// OpenEscalation is one escalation a policies row covers that still waits
// (SPEC-16.E e-open); SecondsToDeadline is negative once the deadline passed.
type OpenEscalation struct {
	RecordID          string
	Ticket            string
	Policy            string
	SecondsToDeadline int64
}

// TableVersions name the hash of each loaded table (SPEC-16.G g-reload).
type TableVersions struct {
	Routes   string
	Policies string
	Flow     string
	Roles    string
}

// StatusSnapshot is the status answer as one value: what the Status call returns
// and what the status subcommand prints (SPEC-16.I i-status).
type StatusSnapshot struct {
	Mode       string
	GatePassed bool
	GateReason string
	BeltAge    time.Duration
	LastTick   time.Time
	// Boundary is the id below which no record is listed (SPEC-16.A a-order).
	Boundary string
	Tables   TableVersions
	// ExecutorOK is whether the executor's Health answered; ExecutorReason says
	// why not.
	ExecutorOK      bool
	ExecutorReason  string
	Counters        Counters
	Held            []HeldJob
	Dead            []DeadJob
	Stalls          []Stall
	Escalations     []OpenEscalation
	DefaultsApplied uint64
	Seats           []Seat
}
