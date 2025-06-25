package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	_ "github.com/lib/pq" // PostgreSQL driver
	"log"
	"net/http"
	"os"
	"strings"
)

// Database connection (secrets and network parameters)
func getDBConnString() string {
	return fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		os.Getenv("DB_HOST"),
		os.Getenv("DB_PORT"),
		os.Getenv("DB_USER"),
		os.Getenv("DB_PASSWORD"),
		os.Getenv("DB_NAME"),
	)
}

// Global DB connection
var db *sql.DB

// Initialize DB and create example Table
func initDB() error {
	var err error

	// Connect to DB
	db, err = sql.Open("postgres", getDBConnString())
	if err != nil {
		return err
	}

	// Test connectivity
	err = db.Ping()
	if err != nil {
		return err
	}

	// Create Table called `ip_logs`
	_, err = db.Exec(`
        CREATE TABLE IF NOT EXISTS ip_logs (
            id SERIAL PRIMARY KEY,
            original_ip VARCHAR(15) NOT NULL,
            reversed_ip VARCHAR(15) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    `)
	return err
}

// Key functionality - Reverse an IP address as required (e.g., 1.2.3.4 -> 4.3.2.1)
func reverseIP(ip string) string {
	parts := strings.Split(ip, ".")
	for i := 0; i < len(parts)/2; i++ {
		j := len(parts) - 1 - i
		parts[i], parts[j] = parts[j], parts[i]
	}
	return strings.Join(parts, ".")
}

// Main handler function
func handleRequest(w http.ResponseWriter, r *http.Request) {
	// Get incoming IP
	ip := strings.Split(r.RemoteAddr, ":")[0]

	// If it will be behind LB - use X-Forwarded-For
	if forwarded := r.Header.Get("X-Forwarded-For"); forwarded != "" {
		ip = strings.Split(forwarded, ",")[0]
	}

	// Reverse IP
	reversedIP := reverseIP(ip)

	// Log to DB
	_, err := db.Exec(
		"INSERT INTO ip_logs (original_ip, reversed_ip) VALUES ($1, $2)",
		ip, reversedIP,
	)
	if err != nil {
		log.Printf("Database error: %v", err)
		http.Error(w, "Internal Server Error", 500)
		return
	}

	// Create response
	response := map[string]string{
		"original_ip": ip,
		"reversed_ip": reversedIP,
	}

	// Send response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// Health check endpoint
func healthCheck(w http.ResponseWriter, r *http.Request) {
	if err := db.Ping(); err != nil {
		http.Error(w, "Database connection failed", 500)
		return
	}
	fmt.Fprintf(w, "OK")
}

func main() {
	// Initialize DB
	if err := initDB(); err != nil {
		log.Fatalf("Database initialization failed: %v", err)
	}

	// Setut Routing for calls
	http.HandleFunc("/", handleRequest)
	http.HandleFunc("/health", healthCheck)

	// Start Server
	port := os.Getenv("PORT")
	if port == "" {
		port = "80"
	}

	log.Printf("Server starting on port %s", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatal(err)
	}
}
