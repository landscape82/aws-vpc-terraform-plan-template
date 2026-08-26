package main

import (
	"net/http/httptest"
	"strings"
	"testing"
)

func TestReverseIP(t *testing.T) {
	if got := reverseIP("1.2.3.4"); got != "4.3.2.1" {
		t.Fatalf("reverseIP() = %q, want %q", got, "4.3.2.1")
	}
}

func TestHandler(t *testing.T) {
	r := httptest.NewRequest("GET", "/", nil)
	r.RemoteAddr = "1.2.3.4:5678"
	w := httptest.NewRecorder()

	handler(w, r)

	if got := w.Body.String(); !strings.Contains(got, "Original IP: 1.2.3.4") {
		t.Fatalf("handler() response = %q, missing original IP", got)
	}
	if got := w.Body.String(); !strings.Contains(got, "Reversed IP: 4.3.2.1") {
		t.Fatalf("handler() response = %q, missing reversed IP", got)
	}
}
