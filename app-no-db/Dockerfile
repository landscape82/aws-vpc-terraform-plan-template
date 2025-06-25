# Stage 1: Build application
FROM golang:1.23-alpine AS builder

# Install git for management of dependency
RUN apk add --no-cache git

# Set work directory
WORKDIR /app

# Copy go.mod & go.sum to enable caching
COPY go.mod go.sum ./

# Download dependencies and tidy up module
RUN go mod tidy

# Copy source code
COPY . .

# Build application to static binary
RUN CGO_ENABLED=0 GOOS=linux go build -o main .

# Stage 2: Create minimal runtime environment (more secure for production)
FROM alpine:latest

# Add non-root user (minimal permissions)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Set work directory
WORKDIR /app

# Copy built binary from  stage 1.
COPY --from=builder /app/main .

# Change ownership of binary (limit `appuser` to it only)
RUN chown appuser:appgroup /app/main

# Switch non-root user
USER appuser

# Expose application port
EXPOSE 80

# Run the application
CMD ["./main"]