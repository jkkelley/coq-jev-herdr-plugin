package main

import (
	"bytes"
	"strings"
	"testing"

	"coq/scheduler/internal/cli"
)

func TestDispatch(t *testing.T) {
	cases := []struct {
		args     []string
		exit     int
		stdout   string
		stderr   string
		noStdout bool
	}{
		{args: []string{"version"}, exit: cli.ExitOK, stdout: "scheduler dev go"},
		{args: []string{"version", "extra"}, exit: cli.ExitUsage, stderr: "usage: scheduler version", noStdout: true},
		{args: nil, exit: cli.ExitUsage, stderr: "usage: scheduler <subcommand>", noStdout: true},
		{args: []string{"sh"}, exit: cli.ExitUsage, stderr: `unknown subcommand "sh"`, noStdout: true},
		{args: []string{"help"}, exit: cli.ExitOK, stdout: "version"},
	}
	for _, c := range cases {
		var out, errb bytes.Buffer
		if got := cli.Dispatch(c.args, &out, &errb); got != c.exit {
			t.Errorf("%v: exit %d, want %d (stderr %q)", c.args, got, c.exit, errb.String())
		}
		if !strings.Contains(out.String(), c.stdout) || !strings.Contains(errb.String(), c.stderr) {
			t.Errorf("%v: stdout %q stderr %q, want %q and %q", c.args, out.String(), errb.String(), c.stdout, c.stderr)
		}
		if c.noStdout && out.Len() > 0 {
			t.Errorf("%v: wrote %q to stdout on a usage error", c.args, out.String())
		}
	}
}

func TestRegisterRefusesDuplicates(t *testing.T) {
	defer func() {
		if recover() == nil {
			t.Fatal("a second version subcommand registered")
		}
	}()
	cli.Register(cli.Command{Name: "version", Run: func(cli.Env) int { return 0 }})
}
