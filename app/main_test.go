package main

import (
	"net/http/httptest"
	"testing"
)

func TestReverseIP(t *testing.T) {
	tests := map[string]string{
		"1.2.3.4":   "4.3.2.1",
		"127.0.0.1": "1.0.0.127",
		"":          "",
	}

	for input, want := range tests {
		if got := reverseIP(input); got != want {
			t.Errorf("reverseIP(%q) = %q, want %q", input, got, want)
		}
	}
}

func TestClientIP(t *testing.T) {
	r := httptest.NewRequest("GET", "/", nil)
	r.RemoteAddr = "10.0.0.5:1234"
	if got := clientIP(r); got != "10.0.0.5" {
		t.Fatalf("clientIP() = %q, want %q", got, "10.0.0.5")
	}

	r.Header.Set("X-Forwarded-For", "203.0.113.10, 10.0.0.5")
	if got := clientIP(r); got != "203.0.113.10" {
		t.Fatalf("clientIP() with forwarding = %q, want %q", got, "203.0.113.10")
	}
}
