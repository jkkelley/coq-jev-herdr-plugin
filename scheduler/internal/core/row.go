package core

import (
	"encoding/json"
	"strconv"
	"strings"
)

// Match is the match object of one routes row (factory/config/routes.schema.json#match).
// A nil key is absent and holds for every record.
type Match struct {
	Kind          *string
	Code          *int
	CodeGte       *int
	Attempt       *int
	AttemptLt     *int
	Escalations   *int
	EscalationsLt *int
}

// Canonical is the match as compact JSON with its keys in the schema's order, the
// row's identity across reloads (SPEC-16 c-row): two rows with the same match have
// the same canonical string whatever the order of keys in the file.
func (m Match) Canonical() string {
	var b strings.Builder
	b.WriteByte('{')
	n := 0
	add := func(key, val string) {
		if n > 0 {
			b.WriteByte(',')
		}
		b.WriteString(`"` + key + `":` + val)
		n++
	}
	if m.Kind != nil {
		k, _ := json.Marshal(*m.Kind)
		add("kind", string(k))
	}
	for _, f := range []struct {
		key string
		v   *int
	}{
		{"code", m.Code}, {"code_gte", m.CodeGte}, {"attempt", m.Attempt}, {"attempt_lt", m.AttemptLt},
		{"escalations", m.Escalations}, {"escalations_lt", m.EscalationsLt},
	} {
		if f.v != nil {
			add(f.key, strconv.Itoa(*f.v))
		}
	}
	b.WriteByte('}')
	return b.String()
}

// Row is one entry of the routes table, kept as the schema allows it, with its
// index in the table (SPEC-16 c-row). The first matching index wins. Empty strings
// and a zero Code are absent keys.
type Row struct {
	// Index is the row's position in the table, from 0.
	Index int
	Match Match
	// Do is the action: enqueue, wake, seat, escalate, notify_owner, break-glass,
	// ignore or none.
	Do string
	// To is the addressee role; absent on an ignore row.
	To string
	// With is what the action carries: ticket, pr, record, verify or merge-main.
	With string
	// Down is the role whose seat for the ticket is taken down after the action.
	Down string
	// Code is the code of the record the action writes, when it writes one.
	Code int
	// Line is the owner's line the row raises: done or decision.
	Line string
	// PriorityFrom names where an enqueue's priority comes from.
	PriorityFrom string
}
