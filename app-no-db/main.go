package main

import (
	"fmt"
	"net/http"
	"strings"
)

// App only catches incoming IP's and presents them in reverse order
func reverseIP(ip string) string {
	parts := strings.Split(ip, ".")
	for i := 0; i < len(parts)/2; i++ {
		j := len(parts) - 1 - i
		parts[i], parts[j] = parts[j], parts[i]
	}
	return strings.Join(parts, ".")
}

// Request handler
func handler(w http.ResponseWriter, r *http.Request) {
	ip := strings.Split(r.RemoteAddr, ":")[0]
	reversedIP := reverseIP(ip)
	fmt.Fprintf(w, "Original IP: %s\nReversed IP: %s", ip, reversedIP)
}

// Main handler function with logging
func main() {
	http.HandleFunc("/", handler)
	fmt.Println("Server starting on :80")
	http.ListenAndServe(":80", nil)
}
