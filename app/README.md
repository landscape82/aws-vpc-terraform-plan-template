# Go Application: `ip-reverser`

The `ip-reverser` is a Go application that provides the following main functionality:

## Main Functionality

- Reverses incoming IP addresses
- Stores the original and reversed IPs in a PostgreSQL database
- Returns JSON responses

## Security Features

- Secure database connection using password
- Proper error handling and logging

## Additional Endpoints - handy while developing some API

- `/health`: For health checks
- `/stats`: For usage statistics

## Infrastructure Integration

- Compatible with AWS load balancer (handles `X-Forwarded-For`)
- Configurable via environment variables
- Supports structured logging
- By default app create DB table and logs all IP's that are incoming
- Dockerfile with multi-stage build for more secure and reliable setup (all needed comments are included in `README.md`)

---

## Running the Application - with plain GO

To run this application, you need to follow these steps:

### 1. Set the Environment Variables (examples)

```bash
export DB_HOST="127.0.0.1"
export DB_PORT="5432"
export DB_USER="myuser"
export DB_PASSWORD="mypassword"
export DB_NAME="mydb"
export PORT="80"  # optional, defaults to 80
```

### 2. Install the Dependencies

```bash
go mod init ip-reverser # run it in app directory
go mod tidy
```

### 3. Build and Run the Application

```bash
go build -o main .
./main
```

---

## Running the Application - with Docker

To run this application, you'll need to follow these steps:

### 1. Set the Environment Variables

```bash
export POSTGRES_USER=myuser
export POSTGRES_PASSWORD=mypassword
export POSTGRES_DB=mydb
```

### 2. Pull and Run Database

```bash
docker pull postgres
docker run --name my-postgres -e POSTGRES_USER=myuser -e POSTGRES_PASSWORD=mypassword -e POSTGRES_DB=mydb -p 5432:5432 -d postgres # here secrets are passed via cli, if we could forgot to export them earlier
docker run --rm \
  -e DB_HOST=host.docker.internal \
  -e DB_PORT=5432 \
  -e DB_USER=myuser \
  -e DB_PASSWORD=mypassword \
  -e DB_NAME=mydb \
  -p 8080:80 my-go-app
```

### 3. Build and Run the Application

```bash
sudo docker build -t ip-reverser .
docker run --rm \
  -e DB_HOST=host.docker.internal \
  -e DB_PORT=5432 \
  -e DB_USER=myuser \
  -e DB_PASSWORD=mypassword \
  -e DB_NAME=mydb \
  -p 8080:80 ip-reverser
```

### 4. Run with Docker Compose 

In root directory you can find `docker-compose.yml`, so from that location you can run:

```bash
cp .env.example .env
docker compose up --build -d
```

Docker Compose now expects local values in `.env` or exported shell variables instead of tracked credentials. Docker should automatically deploy both - application and database. I order to delete / cleanup local environment type:

```bash
docker compose down
```

### 5. Expected result

Check browser or use cli for example curl to get following result:

<img src="../assets/result_app_running_localhost_docker_desktop.png" alt="localhost">
