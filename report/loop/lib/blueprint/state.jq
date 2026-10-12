# state.jq - where each Component stands: done, in flight or coming up (WO-20261011-ceea). Pure: components and tickets in, JSON out.
#   jq -f state.jq in.json                  in.json is {components, tickets}: the outputs of components.jq and tickets.jq
# Output: the components, each with `tickets` (the non-cancelled tickets that name it, {id, title, status}), `state`, and
#   `missing_runbook` (true when it has no runbook). The rule, written in report/loop/RUNBOOK.md:
#   in-flight   a ticket that names the Component is in progress or in review. Work wins over everything else: a built Component
#               being changed again is in flight.
#   done        not in flight, and the Component node is locked or a ticket that names it is done.
#   coming-up   everything else: proposed or draft, with no finished ticket.
# A cancelled ticket counts for nothing. A draft or ready ticket does not make a locked Component less done.

def open: .status == "in-progress" or .status == "in-review";

.tickets as $T
| .components
| map(. as $c
    | ($T | map(select(.status != "cancelled" and (.cmps | index($c.id) != null)))) as $tk
    | . + { tickets: ($tk | map({id, title, status})),
            state: (if any($tk[]; open) then "in-flight"
                    elif ($c.status == "locked" or any($tk[]; .status == "done")) then "done"
                    else "coming-up" end),
            missing_runbook: ($c.runbook == null) })
