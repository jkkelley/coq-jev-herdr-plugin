# tickets.jq - the tickets, each with the Components it names (WO-20261011-ceea). Pure: ticket files in, JSON out.
#   jq -f tickets.jq tickets.json           tickets.json is an array of {fm, text}: the frontmatter object of one WO-*.md and the whole file
# Output: [{id, title, status, pr, closed, parent, cmps}] in input order.
#   cmps   the CMP ids named in the ticket's title, its Problem section or its Scope section, unique and sorted. Those are the places a
#          ticket says what it builds. An id in Notes, an acceptance criterion or the Outcome is a reference, not the work, and is not
#          counted: the 616c board ticket's retro names three Components it did not build.

def body_sections: (.text | split("\n## ")[1:] | map(select(split("\n")[0] as $h | ["Problem", "Scope"] | index($h))));
map(. as $t
    | ([$t.fm.title] + ($t | body_sections) | join("\n")) as $where
    | { id: $t.fm.id, title: $t.fm.title, status: $t.fm.status, pr: ($t.fm.pr // null), closed: ($t.fm.closed // null), parent: ($t.fm.parent // null),
        cmps: ([$where | match("CMP-[a-z0-9]+(?:-[a-z0-9]+)*"; "g").string] | unique) })
