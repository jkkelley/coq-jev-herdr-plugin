package cli

import (
	"fmt"
	"runtime"
)

// version is stamped at build time by the Makefile's -ldflags -X; a build that does
// not stamp it says dev.
var version = "dev"

// Version is the binary's version, for the Health answers and the log.
func Version() string { return version }

func init() {
	Register(Command{
		Name:  "version",
		Usage: "print the version and the Go runtime it was built with",
		Run: func(env Env) int {
			if len(env.Args) > 0 {
				fmt.Fprintln(env.Stderr, "usage: scheduler version")
				return ExitUsage
			}
			fmt.Fprintf(env.Stdout, "scheduler %s %s %s/%s\n", version, runtime.Version(), runtime.GOOS, runtime.GOARCH)
			return ExitOK
		},
	})
}
