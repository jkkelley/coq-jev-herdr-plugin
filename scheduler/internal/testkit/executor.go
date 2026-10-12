package testkit

import (
	"context"
	"errors"
	"regexp"
	"strings"
	"sync"
	"time"

	"coq/scheduler/internal/core"
)

// Answer is what the fake executor returns for a Run its script matches.
type Answer struct {
	ExitCode   int
	StdoutTail string
	StderrTail string
	// Refused and Refusal answer as the executor does for a verb it will not run.
	Refused bool
	Refusal string
	// Delay is real time the Run takes before it answers; a context that ends
	// first makes the Run time out, as the executor's own timeout does.
	Delay time.Duration
	// Timeout answers timed out at once, with no delay.
	Timeout bool
}

// Call is one Run the fake executor received, in arrival order.
type Call struct {
	Verb     string
	Args     []string
	Key      string
	RecordID string
	Ticket   string
	Seat     string
}

// Line is the call as one line, the verb then its arguments joined by spaces, the
// form the bash cases assert on the stub's log.
func (c Call) Line() string { return strings.TrimSpace(c.Verb + " " + strings.Join(c.Args, " ")) }

type rule struct {
	verb string
	args *regexp.Regexp
	ans  Answer
}

// FakeExecutor is a core.Executor that answers each Run from a script keyed by verb
// and an argument pattern, records every call in order, and fails Health on demand
// (SPEC-16.K k-kit-exec). It is safe for concurrent use, as the job runner calls it
// from one goroutine per job.
type FakeExecutor struct {
	mu        sync.Mutex
	clock     core.Clock
	rules     []rule
	fallback  Answer
	calls     []Call
	healthErr error
}

var _ core.Executor = (*FakeExecutor)(nil)

// NewFakeExecutor returns a fake whose verdict times come from clock. An unscripted
// Run answers exit 0 with empty tails until Default says otherwise.
func NewFakeExecutor(clock core.Clock) *FakeExecutor { return &FakeExecutor{clock: clock} }

// On scripts the answer for verb when the call's arguments, joined by single spaces,
// match the regular expression argPattern; an empty pattern matches any arguments.
// Rules are tried in the order they were added and the first match answers. A bad
// pattern panics, because it is a mistake in the test.
func (f *FakeExecutor) On(verb, argPattern string, a Answer) *FakeExecutor {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.rules = append(f.rules, rule{verb: verb, args: regexp.MustCompile(argPattern), ans: a})
	return f
}

// Default sets the answer for a Run no rule matches.
func (f *FakeExecutor) Default(a Answer) *FakeExecutor {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.fallback = a
	return f
}

// FailHealth makes Health return err; nil makes it healthy again.
func (f *FakeExecutor) FailHealth(err error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.healthErr = err
}

// Calls returns a copy of the calls received, in order.
func (f *FakeExecutor) Calls() []Call {
	f.mu.Lock()
	defer f.mu.Unlock()
	out := make([]Call, len(f.calls))
	for i, c := range f.calls {
		c.Args = append([]string(nil), c.Args...)
		out[i] = c
	}
	return out
}

// Lines returns every call as its Line, in order.
func (f *FakeExecutor) Lines() []string {
	calls := f.Calls()
	out := make([]string, len(calls))
	for i, c := range calls {
		out[i] = c.Line()
	}
	return out
}

// Reset forgets the calls received; the script stays.
func (f *FakeExecutor) Reset() {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.calls = nil
}

// Run records the call, then answers from the first matching rule.
func (f *FakeExecutor) Run(ctx context.Context, job core.Job) core.Verdict {
	f.mu.Lock()
	f.calls = append(f.calls, Call{
		Verb: job.Verb, Args: append([]string(nil), job.Args...), Key: job.Key,
		RecordID: job.RecordID, Ticket: job.Ticket, Seat: job.Seat,
	})
	ans := f.fallback
	line := strings.Join(job.Args, " ")
	for _, r := range f.rules {
		if r.verb == job.Verb && r.args.MatchString(line) {
			ans = r.ans
			break
		}
	}
	f.mu.Unlock()

	v := core.Verdict{StartedAt: f.clock.Now()}
	if ans.Timeout {
		v.TimedOut, v.ExitCode, v.FinishedAt = true, -1, f.clock.Now()
		return v
	}
	if ans.Delay > 0 {
		t := time.NewTimer(ans.Delay)
		defer t.Stop()
		select {
		case <-t.C:
		case <-ctx.Done():
			v.TimedOut, v.ExitCode, v.FinishedAt = true, -1, f.clock.Now()
			return v
		}
	}
	v.ExitCode, v.Refused, v.Refusal = ans.ExitCode, ans.Refused, ans.Refusal
	v.StdoutTail, v.StderrTail, v.FinishedAt = ans.StdoutTail, ans.StderrTail, f.clock.Now()
	return v
}

// ErrHealth is a ready-made error for FailHealth.
var ErrHealth = errors.New("executor unreachable")

// Health returns the error FailHealth set, or nil.
func (f *FakeExecutor) Health(ctx context.Context) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	return f.healthErr
}
