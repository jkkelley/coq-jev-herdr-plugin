package core

// PlanVerdict is what routing decided for one record (SPEC-16 c-plan).
type PlanVerdict string

// The plan verdicts. Routed carries jobs; ignored and own carry none; unrouted and
// unreadable carry only the note the domain that owns them writes.
const (
	PlanRouted     PlanVerdict = "routed"
	PlanIgnored    PlanVerdict = "ignored"
	PlanUnrouted   PlanVerdict = "unrouted"
	PlanOwn        PlanVerdict = "own"
	PlanUnreadable PlanVerdict = "unreadable"
)

// NoRow is Plan.RowIndex when no row decided the record.
const NoRow = -1

// Plan is what routing decides for one record: pure data with no side effect, so
// shadow mode can write it down and the parity report can compare it.
type Plan struct {
	RecordID string
	// RowIndex is the index of the row that matched, or NoRow.
	RowIndex int
	Verdict  PlanVerdict
	// Jobs are in order: the primary action, then the down, then the receipt.
	// An ignored or own record has none.
	Jobs []JobSpec
}
