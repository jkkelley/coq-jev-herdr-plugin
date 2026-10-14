package testkit

import (
	"bytes"
	"context"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"testing"
	"time"

	"coq/scheduler/internal/core"
)

// The cases of SPEC-16.K k-t1: the fakes are trustworthy.

func job(verb string, args ...string) core.Job {
	return core.Job{JobSpec: core.JobSpec{Key: "r:" + verb + ":t", Verb: verb, Args: args, RecordID: "r", Ticket: "WO-20300102-abcd"}}
}

func TestFakeExecutorAnswersByPattern(t *testing.T) {
	clock := NewClock(Epoch)
	f := NewFakeExecutor(clock).
		On("seat_up", `^WO-20300102-0001 tester$`, Answer{ExitCode: 4, StderrTail: "slot busy"}).
		On("seat_up", ``, Answer{ExitCode: 0, StdoutTail: "up"}).
		On("enqueue", `--priority`, Answer{ExitCode: 9}).
		Default(Answer{ExitCode: 7})

	cases := []struct {
		job  core.Job
		exit int
		out  string
		err  string
	}{
		{job("seat_up", "WO-20300102-0001", "tester"), 4, "", "slot busy"},
		{job("seat_up", "WO-20300102-0002", "tester"), 0, "up", ""},
		{job("enqueue", "WO-20300102-0002", "r"), 7, "", ""},
		{job("prompt", "tester-wo-20300102-0002", "record r"), 7, "", ""},
	}
	for _, c := range cases {
		v := f.Run(context.Background(), c.job)
		if v.ExitCode != c.exit || v.StdoutTail != c.out || v.StderrTail != c.err || v.TimedOut || v.Refused {
			t.Errorf("%s: got %+v, want exit %d out %q err %q", c.job.Verb, v, c.exit, c.out, c.err)
		}
		if !v.StartedAt.Equal(Epoch) || !v.FinishedAt.Equal(Epoch) {
			t.Errorf("%s: verdict times %v..%v, want the clock's %v", c.job.Verb, v.StartedAt, v.FinishedAt, Epoch)
		}
	}
}

func TestFakeExecutorRefuses(t *testing.T) {
	f := NewFakeExecutor(NewClock(Epoch)).On("shell", ``, Answer{Refused: true, Refusal: "verb not in table"})
	v := f.Run(context.Background(), job("shell", "true"))
	if !v.Refused || v.Refusal != "verb not in table" {
		t.Fatalf("got %+v, want refused with the reason", v)
	}
}

func TestFakeExecutorLogsCallsInOrder(t *testing.T) {
	f := NewFakeExecutor(NewClock(Epoch))
	want := []string{"seat_up WO-20300102-0001 tester", "prompt tester-wo-20300102-0001 record r", "record --code 300 --kind record.routed"}
	for _, line := range want {
		parts := strings.Fields(line)
		f.Run(context.Background(), job(parts[0], parts[1:]...))
	}
	if got := f.Lines(); strings.Join(got, "\n") != strings.Join(want, "\n") {
		t.Fatalf("calls %q, want %q", got, want)
	}
	calls := f.Calls()
	if calls[1].Key != "r:prompt:t" || calls[1].RecordID != "r" || calls[1].Ticket != "WO-20300102-abcd" {
		t.Fatalf("call 2 lost its ids: %+v", calls[1])
	}
	calls[0].Args[0] = "changed"
	if f.Calls()[0].Args[0] != "WO-20300102-0001" {
		t.Fatal("Calls returned the fake's own slice; a caller could rewrite the log")
	}
	f.Reset()
	if len(f.Calls()) != 0 {
		t.Fatal("Reset kept calls")
	}
}

func TestFakeExecutorInjectsTimeout(t *testing.T) {
	f := NewFakeExecutor(NewClock(Epoch)).
		On("prompt", ``, Answer{Timeout: true}).
		On("seat_up", ``, Answer{Delay: time.Minute, ExitCode: 0}).
		On("seat_down", ``, Answer{Delay: time.Millisecond, ExitCode: 0, StdoutTail: "down"})

	if v := f.Run(context.Background(), job("prompt", "s", "line")); !v.TimedOut || v.ExitCode != -1 {
		t.Errorf("scripted timeout: got %+v", v)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Millisecond)
	defer cancel()
	start := time.Now()
	if v := f.Run(ctx, job("seat_up", "WO-20300102-0001", "tester")); !v.TimedOut {
		t.Errorf("delay past the context: got %+v, want timed out", v)
	}
	if time.Since(start) > 10*time.Second {
		t.Error("the delayed Run did not end with its context")
	}
	if v := f.Run(context.Background(), job("seat_down", "tester-wo-20300102-0001")); v.TimedOut || v.StdoutTail != "down" {
		t.Errorf("short delay: got %+v, want the answer", v)
	}
}

func TestFakeExecutorHealthOnDemand(t *testing.T) {
	f := NewFakeExecutor(NewClock(Epoch))
	if err := f.Health(context.Background()); err != nil {
		t.Fatalf("healthy fake: %v", err)
	}
	f.FailHealth(ErrHealth)
	if err := f.Health(context.Background()); err != ErrHealth {
		t.Fatalf("got %v, want ErrHealth", err)
	}
	f.FailHealth(nil)
	if err := f.Health(context.Background()); err != nil {
		t.Fatalf("recovered fake: %v", err)
	}
}

func TestClockAdvances(t *testing.T) {
	c := NewClock(time.Date(2030, 1, 2, 3, 4, 5, 0, time.FixedZone("x", 3600)))
	if c.Now().Location() != time.UTC {
		t.Fatal("clock is not in UTC")
	}
	start := c.Now()
	if got := c.Advance(90 * time.Second); !got.Equal(start.Add(90*time.Second)) || !c.Now().Equal(got) {
		t.Fatalf("Advance: got %v, now %v", got, c.Now())
	}
	c.Set(Epoch)
	if !c.Now().Equal(Epoch) {
		t.Fatalf("Set: got %v", c.Now())
	}
}

// builderSpecs cover every optional field the writer knows, including the kinds
// that alone may carry action, answer and policy.
//
// BREADCRUMB 2026-10-14 - WO-20261014-539a. What broke: the test.failed spec carried no SHA, and the writer refuses a gate kind
// without --sha since WO-20261013-f298 (event.sh line 97), so TestRecordBuilderMatchesWriterShape stopped at spec 1 once the
// world could run the writer at all. Why this fix: the spec gets a SHA like the pr.opened spec, which is what a real gate record
// carries. Rejected: dropping the kind from the specs (the builder must stay proven against every kind the writer knows).
// Cost: none.
var builderSpecs = []RecordSpec{
	{Kind: "pr.opened", Code: 100, Seat: "worker-wo-20300102-0001", Ticket: "WO-20300102-0001", SHA: "abc1234", PR: 7, Note: "pr opened"},
	{Kind: "test.failed", Code: 422, Seat: "tester-wo-20300102-0001", Ticket: "WO-20300102-0001", SHA: "abc1234", Attempt: 2, To: "worker", Evidence: []string{"a/b.txt"}},
	{Kind: "record.routed", Code: 300, Seat: "scheduler", To: "tester", Note: `routed "pr.opened" <100> & more`},
	{Kind: "break.glass", Code: 300, Seat: "worker-wo-20300102-0001", Ticket: "WO-20300102-0001", Action: "git push", Answer: "20300102T030405Z-300-k0001"},
	{Kind: "policy.applied", Code: 204, Seat: "scheduler", Ticket: "WO-20300102-0001", Policy: "POL-default-retry", Answer: "20300102T030406Z-423-k0002"},
	{Kind: "seat.up", Code: 100, Seat: "monitor"},
}

func TestRecordBuilderPassesWriterCheck(t *testing.T) {
	w := NewWorld(t)
	var ids []string
	for _, s := range builderSpecs {
		r, err := w.Records.Write(s)
		if err != nil {
			t.Fatalf("Write %s: %v", s.Kind, err)
		}
		if r.Root != w.Events || filepath.Base(r.Path) != r.ID+".json" {
			t.Fatalf("record %s at %s, root %s", r.ID, r.Path, r.Root)
		}
		if s.Attempt == 0 && r.Attempt != 1 {
			t.Fatalf("absent attempt read as %d, want 1", r.Attempt)
		}
		ids = append(ids, r.ID)
	}
	if !sort.StringsAreSorted(ids) {
		t.Fatalf("ids written in order do not sort in order: %v", ids)
	}
	out, err := w.CheckRecords()
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(out, "events ok: 6 files") {
		t.Fatalf("event.sh check said %q, want 6 files ok", out)
	}
	if _, err := w.Records.Write(RecordSpec{Kind: "note", Code: 99, Seat: "x"}); err == nil {
		t.Fatal("a code below 100 was written")
	}
}

// TestRecordBuilderMatchesWriterShape writes the same record with the real writer
// and with the builder and compares the files byte for byte, id and at aside.
func TestRecordBuilderMatchesWriterShape(t *testing.T) {
	w := NewWorld(t)
	writer := filepath.Join(w.Events, "bin", "event.sh")
	for i, s := range builderSpecs {
		args := []string{writer, "add", "--code", strconv.Itoa(s.Code), "--seat", s.Seat, "--kind", s.Kind}
		for _, kv := range [][2]string{{"--ticket", s.Ticket}, {"--to", s.To}, {"--note", s.Note}, {"--sha", s.SHA},
			{"--action", s.Action}, {"--answer", s.Answer}, {"--policy", s.Policy}} {
			if kv[1] != "" {
				args = append(args, kv[0], kv[1])
			}
		}
		if s.Attempt != 0 {
			args = append(args, "--attempt", strconv.Itoa(s.Attempt))
		}
		if s.PR != 0 {
			args = append(args, "--pr", strconv.Itoa(s.PR))
		}
		for _, e := range s.Evidence {
			args = append(args, "--evidence", e)
		}
		cmd := exec.Command("bash", args...)
		// BREADCRUMB 2026-10-14 - WO-20261014-539a. What broke: the writer (WO-20261012-7e13, Roadmap A1) puts a record under the
		// state root and prints that file's path, not its id, so this test looked for <id>.json in w.Events and never found the
		// file the writer wrote under HOME. Why this fix: COQ_STATE points the writer at the world's own state directory, so the
		// test never writes into, or reads, the developer's real state root, and the printed path is the file to compare.
		// Rejected: leaving HOME to decide (a host run would write into the real state root). Cost: none.
		cmd.Env = append(os.Environ(), "TZ=UTC", "COQ_STATE="+w.StateDir)
		out, err := cmd.CombinedOutput()
		if err != nil {
			t.Fatalf("spec %d: the writer refused it: %v: %s", i, err, out)
		}
		written := strings.TrimSpace(string(out))
		if !strings.HasPrefix(written, w.StateDir+string(filepath.Separator)) {
			t.Fatalf("spec %d: writer file %q is not under the world's state directory %s", i, written, w.StateDir)
		}
		fromWriter, err := os.ReadFile(written)
		if err != nil {
			t.Fatalf("spec %d: writer file not readable: %v", i, err)
		}
		r, err := w.Records.Write(s)
		if err != nil {
			t.Fatal(err)
		}
		fromBuilder, _ := os.ReadFile(r.Path)
		if a, b := normalise(fromWriter), normalise(fromBuilder); !bytes.Equal(a, b) {
			t.Errorf("spec %d (%s): shapes differ\nwriter:\n%s\nbuilder:\n%s", i, s.Kind, a, b)
		}
	}
}

var idOrAt = regexp.MustCompile(`"(id|at)": "[^"]*"`)

func normalise(b []byte) []byte { return idOrAt.ReplaceAll(b, []byte(`"$1": "-"`)) }

func TestWorldRendersVariablesIntoIt(t *testing.T) {
	w := NewWorld(t)
	for _, rel := range []string{"factory/config/routes.json", "factory/config/flow.json", "roles/tester.json", "events/schema/event.schema.json"} {
		if !isFile(filepath.Join(w.Repo, rel)) {
			t.Errorf("world lacks %s", rel)
		}
	}
	p, err := w.Render("factory/config/runner.json")
	if err != nil {
		t.Fatal(err)
	}
	b, _ := os.ReadFile(p)
	if strings.Contains(string(b), "${repo}") || !strings.Contains(string(b), w.Repo+"/factory/config/routes.json") {
		t.Fatalf("rendered runner.json still names the template or not the world:\n%s", b)
	}
	if !strings.HasPrefix(p, w.Dir) {
		t.Fatalf("rendered into %s, outside the world %s", p, w.Dir)
	}
}
