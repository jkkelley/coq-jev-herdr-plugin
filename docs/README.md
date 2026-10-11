# Documentation

Diataxis mode: **reference**.
Last reviewed: 2026-10-11.

This is the router. Every document below declares its mode in its own first lines.

| Directory | Mode | Answers |
| --- | --- | --- |
| `tutorials/` | tutorial | "I am new, walk me to a first success" |
| `how-to/` | how-to | "I have a goal, get me to it" |
| `reference/` | reference | "What exactly does this do" |
| `explanation/` | explanation | "Why is it like this" |
| `decisions/` | reference | Architecture decision records, append-only |
| `sops/` | how-to | Standard operating procedures |

A directory appears once it has something in it.
An empty directory is a promise nobody kept, so none are created ahead of need.

## The two rules

**Every document declares its mode and its review date.**
`docs.sh verify` fails the build when one does not.

**A decision is superseded, never edited.**
A new record supersedes an old one and says so.
Reading top-down, the current answer arrives before the one it replaced.
