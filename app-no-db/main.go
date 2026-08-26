package main

import (
	"fmt"
	"net/http"
	"os"
	"strings"
)

const defaultPort = "8080"

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

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprint(w, "OK")
}

// Main handler function with logging
func main() {
	http.HandleFunc("/", handler)
	http.HandleFunc("/health", healthHandler)

	port := os.Getenv("PORT")
	if port == "" {
		port = defaultPort
	}

	fmt.Printf("Server starting on :%s\n", port)
	http.ListenAndServe(":"+port, nil)
}
