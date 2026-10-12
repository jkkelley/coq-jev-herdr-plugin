package core

import "testing"

func ip(n int) *int { return &n }

func sp(s string) *string { return &s }

func TestMatchCanonicalIsSchemaOrdered(t *testing.T) {
	cases := []struct {
		m    Match
		want string
	}{
		{Match{}, `{}`},
		{Match{Kind: sp("pr.opened")}, `{"kind":"pr.opened"}`},
		{Match{EscalationsLt: ip(2), Code: ip(423), Kind: sp("blocked"), AttemptLt: ip(3)},
			`{"kind":"blocked","code":423,"attempt_lt":3,"escalations_lt":2}`},
		{Match{CodeGte: ip(500), Attempt: ip(1), Escalations: ip(0)}, `{"code_gte":500,"attempt":1,"escalations":0}`},
		{Match{Kind: sp(`a"b`)}, `{"kind":"a\"b"}`},
	}
	for _, c := range cases {
		if got := c.m.Canonical(); got != c.want {
			t.Errorf("Canonical() = %s, want %s", got, c.want)
		}
	}
}

func TestJobKey(t *testing.T) {
	if got := JobKey("20300102T030405Z-100-k0001", "wake", "tester-wo-20300102-0001"); got != "20300102T030405Z-100-k0001:wake:tester-wo-20300102-0001" {
		t.Fatalf("JobKey = %s", got)
	}
}
