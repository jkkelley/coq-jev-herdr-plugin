// Command scheduler is the one binary of the Go scheduler (SPEC-16 CMP-scheduler):
// in its container it is the scheduler, on the host in a labelled pane it is the
// executor. Every behaviour is a subcommand registered in internal/cli.
package main

import (
	"os"

	"coq/scheduler/internal/cli"
)

func main() {
	os.Exit(cli.Dispatch(os.Args[1:], os.Stdout, os.Stderr))
}
