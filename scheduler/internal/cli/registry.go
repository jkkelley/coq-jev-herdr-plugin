// Package cli is the scheduler binary's subcommands (SPEC-16.H h-cli). main calls
// Dispatch; each subcommand is one file in this package that calls Register from
// its init, so a wave adds a file and edits none.
package cli

import (
	"fmt"
	"io"
	"sort"
	"sync"
)

// Exit codes every subcommand uses (SPEC-16.H h-cli-exit).
const (
	ExitOK         = 0
	ExitNotOK      = 1
	ExitUsage      = 2
	ExitValidation = 3
	ExitIO         = 4
)

// Env is what a subcommand gets from the process: its arguments after the
// subcommand's name and the two output streams. Nothing reads os.Args or writes
// os.Stdout directly, so Dispatch is testable.
type Env struct {
	Args   []string
	Stdout io.Writer
	Stderr io.Writer
}

// Command is one subcommand: its name, a one-line usage, and the function that runs
// it and returns the exit code.
type Command struct {
	Name  string
	Usage string
	Run   func(env Env) int
}

var (
	mu       sync.Mutex
	commands = map[string]Command{}
)

// Register adds a subcommand. It panics on an empty name, a nil Run or a second
// registration of one name, because each is a build mistake caught at start.
func Register(c Command) {
	mu.Lock()
	defer mu.Unlock()
	if c.Name == "" || c.Run == nil {
		panic("cli: Register needs a name and a Run")
	}
	if _, dup := commands[c.Name]; dup {
		panic("cli: subcommand registered twice: " + c.Name)
	}
	commands[c.Name] = c
}

// Commands lists the registered subcommands by name.
func Commands() []Command {
	mu.Lock()
	defer mu.Unlock()
	out := make([]Command, 0, len(commands))
	for _, c := range commands {
		out = append(out, c)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].Name < out[j].Name })
	return out
}

// Dispatch runs the subcommand args[0] names with the rest of args and returns its
// exit code. No subcommand, an unknown one, or help prints the usage: help to
// stdout with exit 0, the others to stderr with exit 2.
func Dispatch(args []string, stdout, stderr io.Writer) int {
	if len(args) == 0 {
		usage(stderr)
		return ExitUsage
	}
	switch args[0] {
	case "help", "-h", "--help":
		usage(stdout)
		return ExitOK
	}
	mu.Lock()
	c, ok := commands[args[0]]
	mu.Unlock()
	if !ok {
		fmt.Fprintf(stderr, "scheduler: unknown subcommand %q\n", args[0])
		usage(stderr)
		return ExitUsage
	}
	return c.Run(Env{Args: args[1:], Stdout: stdout, Stderr: stderr})
}

func usage(w io.Writer) {
	fmt.Fprintln(w, "usage: scheduler <subcommand> [flags]")
	for _, c := range Commands() {
		fmt.Fprintf(w, "  %-10s %s\n", c.Name, c.Usage)
	}
}
