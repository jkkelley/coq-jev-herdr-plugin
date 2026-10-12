package testkit

import (
	"bytes"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"sync"
	"time"

	"coq/scheduler/internal/core"
)

// RecordSpec is what a test says about a record; the builder fills in the rest as
// the event writer would. Zero values are absent fields.
type RecordSpec struct {
	Kind     string
	Code     int
	Seat     string
	Ticket   string
	To       string
	Note     string
	Attempt  int
	SHA      string
	PR       int
	Action   string
	Answer   string
	Policy   string
	Evidence []string
}

// Records writes record files in the event writer's exact layout and shape
// (events/bin/event.sh add): <root>/YYYY/MM/<id>.json, the keys in the writer's
// order, pretty-printed with two spaces, written to a temporary name and renamed.
// The record's at is the clock's time, and the clock advances one second after
// every write, so records a test writes in order sort in that order (SPEC-16.K
// k-kit-records). Suffixes are a counter, so ids are deterministic.
type Records struct {
	mu    sync.Mutex
	root  string
	clock *Clock
	n     int
}

// NewRecords returns a builder writing under root with times from clock.
func NewRecords(root string, clock *Clock) *Records { return &Records{root: root, clock: clock} }

// Root is the directory the builder writes under.
func (b *Records) Root() string { return b.root }

// wire is the writer's JSON shape. The order of the fields is the writer's key
// order; the pointer fields are written as null when absent, the omitempty fields
// are left out, exactly as the writer's jq program does.
type wire struct {
	SchemaVersion string   `json:"schema_version"`
	ID            string   `json:"id"`
	At            string   `json:"at"`
	Code          int      `json:"code"`
	Seat          string   `json:"seat"`
	Kind          string   `json:"kind"`
	Ticket        *string  `json:"ticket"`
	Pane          *string  `json:"pane"`
	Note          string   `json:"note"`
	Evidence      []string `json:"evidence"`
	Observations  []any    `json:"observations"`
	Attempt       int      `json:"attempt,omitempty"`
	To            string   `json:"to,omitempty"`
	SHA           string   `json:"sha,omitempty"`
	PR            int      `json:"pr,omitempty"`
	Action        string   `json:"action,omitempty"`
	Answer        string   `json:"answer,omitempty"`
	Policy        string   `json:"policy,omitempty"`
}

// Write writes one record and returns it as intake would read it.
func (b *Records) Write(s RecordSpec) (core.Record, error) {
	if s.Kind == "" || s.Seat == "" {
		return core.Record{}, fmt.Errorf("testkit: a record needs a kind and a seat")
	}
	if s.Code < 100 || s.Code > 599 {
		return core.Record{}, fmt.Errorf("testkit: code %d is not 100..599", s.Code)
	}
	b.mu.Lock()
	b.n++
	n := b.n
	at := b.clock.Now().Truncate(time.Second)
	b.clock.Advance(time.Second)
	b.mu.Unlock()

	id := fmt.Sprintf("%s-%03d-%s", at.Format("20060102T150405Z"), s.Code, suffix(n))
	w := wire{
		SchemaVersion: "1.0.0", ID: id, At: at.Format(core.AtLayout), Code: s.Code, Seat: s.Seat, Kind: s.Kind,
		Note: s.Note, Evidence: append([]string{}, s.Evidence...), Observations: []any{},
		Attempt: s.Attempt, To: s.To, SHA: s.SHA, PR: s.PR, Action: s.Action, Answer: s.Answer, Policy: s.Policy,
	}
	if s.Ticket != "" {
		w.Ticket = &s.Ticket
	}
	var buf bytes.Buffer
	enc := json.NewEncoder(&buf)
	enc.SetEscapeHTML(false)
	enc.SetIndent("", "  ")
	if err := enc.Encode(w); err != nil {
		return core.Record{}, err
	}
	dir := filepath.Join(b.root, at.Format("2006"), at.Format("01"))
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return core.Record{}, err
	}
	path := filepath.Join(dir, id+".json")
	if err := os.WriteFile(path+".tmp", buf.Bytes(), 0o644); err != nil {
		return core.Record{}, err
	}
	if err := os.Rename(path+".tmp", path); err != nil {
		return core.Record{}, err
	}

	attempt := s.Attempt
	if attempt == 0 {
		attempt = 1
	}
	return core.Record{
		ID: id, At: at, Code: s.Code, Seat: s.Seat, Kind: s.Kind, Ticket: s.Ticket, To: s.To, Attempt: attempt,
		SHA: s.SHA, PR: s.PR, Action: s.Action, Answer: s.Answer, Policy: s.Policy, Note: s.Note,
		Root: b.root, Path: path,
	}, nil
}

// suffix is the five-character id suffix for the n-th record: k and n in base 36,
// zero-padded, which the writer's pattern [a-z0-9]{5} accepts.
func suffix(n int) string {
	s := strconv.FormatInt(int64(n%(36*36*36*36)), 36)
	for len(s) < 4 {
		s = "0" + s
	}
	return "k" + s
}
