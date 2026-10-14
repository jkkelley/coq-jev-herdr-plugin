package testkit

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

// Epoch is the time a World's clock starts at: a fixed UTC second, so ids and
// deadlines in a test are the same on every run.
var Epoch = time.Date(2030, 1, 2, 3, 4, 5, 0, time.UTC)

// worldFiles are the repository files a World copies, repository-relative: the
// tables the scheduler loads and the event writer with its schema, so records the
// builder writes into the world can be checked by the real writer.
//
// BREADCRUMB 2026-10-14 - WO-20261014-539a (system epic WO-20261013-16f1, cause ay). What broke: events/bin/event.sh line 40
// sources ../bin/state-root.sh and that resolver reads config/state.json (WO-20261012-7e13, Roadmap A1), but this list
// copied event.sh alone, so the world's writer exited 4 ("bin/state-root.sh is missing beside this events/ tree") and
// TestRecordBuilderPassesWriterCheck and TestRecordBuilderMatchesWriterShape failed; main was red on make -C scheduler
// test. Why this fix: copy the two files the writer needs, at their repository paths, so the copy runs the real writer
// exactly as the repository does. Rejected: stubbing a resolver inside the world (a second answer to "where does runtime
// data go", the thing A1 made single) and skipping the two cases (a test that passes by not running). Cost: a new file
// event.sh sources must be added here too; the glob-or-fail loop in NewWorld names the missing one at once.
var worldFiles = []string{
	"factory/config/*.json",
	"roles/*.json",
	"events/bin/event.sh",
	"events/schema/*.json",
	"bin/state-root.sh",
	"config/state.json",
}

// World is a scheduler's surroundings on a temporary directory (SPEC-16.K
// k-kit-world): a repository holding copies of the tables and the event writer, the
// record log root inside it, a state directory and a home directory, a clock at
// Epoch, a fake executor and a record builder writing into the log.
type World struct {
	// Dir is the temporary directory everything lives under.
	Dir string
	// Repo is the world's repository: the copied files at their repository paths.
	Repo string
	// Events is the record log root, Repo/events, the first intake root.
	Events   string
	StateDir string
	Home     string
	Clock    *Clock
	Exec     *FakeExecutor
	Records  *Records
}

// NewWorld builds a World under t.TempDir from the repository this test runs in,
// failing the test when the repository or a file cannot be found.
func NewWorld(t testing.TB) *World {
	t.Helper()
	src, err := RepoRoot()
	if err != nil {
		t.Fatalf("testkit: %v", err)
	}
	dir := t.TempDir()
	w := &World{
		Dir: dir, Repo: filepath.Join(dir, "repo"), StateDir: filepath.Join(dir, "state"), Home: filepath.Join(dir, "home"),
		Clock: NewClock(Epoch),
	}
	w.Events = filepath.Join(w.Repo, "events")
	for _, d := range []string{w.Events, w.StateDir, w.Home} {
		if err := os.MkdirAll(d, 0o755); err != nil {
			t.Fatalf("testkit: %v", err)
		}
	}
	for _, pattern := range worldFiles {
		matches, err := filepath.Glob(filepath.Join(src, pattern))
		if err != nil || len(matches) == 0 {
			t.Fatalf("testkit: no repository file matches %s under %s", pattern, src)
		}
		for _, m := range matches {
			rel, _ := filepath.Rel(src, m)
			if err := copyFile(m, filepath.Join(w.Repo, rel)); err != nil {
				t.Fatalf("testkit: %v", err)
			}
		}
	}
	w.Exec = NewFakeExecutor(w.Clock)
	w.Records = NewRecords(w.Events, w.Clock)
	return w
}

// Vars are the configuration variables pointing into the world, as SPEC-16.G g-vars
// names them; host_repo is the world's repository too, since nothing leaves it.
func (w *World) Vars() map[string]string {
	return map[string]string{"repo": w.Repo, "host_repo": w.Repo, "state_dir": w.StateDir, "HOME": w.Home}
}

// Render reads a repository file, replaces every ${name} of Vars with its value,
// and writes the result at the same repository-relative path inside the world,
// returning that path. Other variables, ENV:NAME among them, are left for the
// loader under test to resolve.
func (w *World) Render(repoRel string) (string, error) {
	src, err := RepoRoot()
	if err != nil {
		return "", err
	}
	b, err := os.ReadFile(filepath.Join(src, repoRel))
	if err != nil {
		return "", err
	}
	s := string(b)
	for k, v := range w.Vars() {
		s = strings.ReplaceAll(s, "${"+k+"}", v)
	}
	dst := filepath.Join(w.Repo, repoRel)
	if err := os.MkdirAll(filepath.Dir(dst), 0o755); err != nil {
		return "", err
	}
	return dst, os.WriteFile(dst, []byte(s), 0o644)
}

// CheckRecords runs the event writer's own check over the world's log, the copy
// of events/bin/event.sh against the copy of its schema. It returns the check's
// output and an error when the check fails or cannot run.
func (w *World) CheckRecords() (string, error) {
	cmd := exec.Command("bash", filepath.Join(w.Events, "bin", "event.sh"), "check")
	// COQ_STATE keeps the check on the world's own state directory, never the developer's real state root (WO-20261014-539a).
	cmd.Env = append(os.Environ(), "COQ_STATE="+w.StateDir)
	out, err := cmd.CombinedOutput()
	if err != nil {
		return string(out), fmt.Errorf("event.sh check: %v: %s", err, out)
	}
	return string(out), nil
}

// RepoRoot finds the repository this code runs in: the nearest directory, from the
// working directory up, that holds both scheduler/go.mod and events/bin/event.sh.
func RepoRoot() (string, error) {
	dir, err := os.Getwd()
	if err != nil {
		return "", err
	}
	for {
		if isFile(filepath.Join(dir, "scheduler", "go.mod")) && isFile(filepath.Join(dir, "events", "bin", "event.sh")) {
			return dir, nil
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			return "", errors.New("no repository holding scheduler/go.mod and events/bin/event.sh above the working directory")
		}
		dir = parent
	}
}

func isFile(p string) bool {
	st, err := os.Stat(p)
	return err == nil && st.Mode().IsRegular()
}

func copyFile(src, dst string) error {
	b, err := os.ReadFile(src)
	if err != nil {
		return err
	}
	st, err := os.Stat(src)
	if err != nil {
		return err
	}
	if err := os.MkdirAll(filepath.Dir(dst), 0o755); err != nil {
		return err
	}
	return os.WriteFile(dst, b, st.Mode().Perm())
}
