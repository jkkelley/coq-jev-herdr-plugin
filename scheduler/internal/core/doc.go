// Package core holds the shared contracts of the Go scheduler, SPEC-16 s-contracts:
// the values every domain passes around (Record, Row, Plan, JobSpec, Job, Verdict,
// Seat, the status snapshot) and the interfaces that make every domain testable with
// fakes (Source, Ledger, Executor, Clock, Table, JobStore, SeatObserver, Latches).
//
// core is written by the skeleton ticket and is read-only afterwards (SPEC-16.H
// h-layout-own). A domain that needs a field or a method not here raises a question
// to the architect; it never edits core in its own ticket (SPEC-16 c-where).
//
// Nothing in core performs a side effect: no file, no socket, no clock. The engine
// wires the real implementations; tests wire the testkit's.
package core
