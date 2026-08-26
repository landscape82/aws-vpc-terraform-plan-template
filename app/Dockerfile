# Stage 1: Build application
FROM golang:1.23-alpine AS builder

# Install git for management of dependency
RUN apk add --no-cache git

# Set work directory
WORKDIR /app

# Copy go.mod & go.sum to enable caching
COPY go.mod go.sum ./

# Download pinned dependencies
RUN go mod download

# Copy source code
COPY . .

# Build application to static binary
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /main .

# Stage 2: Create minimal runtime environment (more secure for production)
FROM alpine:latest

# Add curl for container health checks
RUN apk add --no-cache curl

# Add non-root user (minimal permissions)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Set work directory
WORKDIR /app

# Copy built binary from  stage 1.
COPY --from=builder /main /app/main

# Change ownership of binary (limit `appuser` to it only)
RUN chown appuser:appgroup /app/main

# Default to a non-privileged container port
ENV PORT=8080

# Switch non-root user
USER appuser

# Expose application port
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl --fail http://127.0.0.1:${PORT}/health || exit 1

# Run the application
CMD ["./main"]
