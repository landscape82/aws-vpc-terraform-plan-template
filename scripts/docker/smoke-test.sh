#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"

cd "${PROJECT_ROOT}"

cleanup() {
	docker compose --env-file .env.example down >/dev/null 2>&1 || true
}

trap cleanup EXIT

docker compose --env-file .env.example up --build -d

for attempt in {1..15}; do
	if curl --fail --silent http://127.0.0.1:8080/health >/dev/null; then
		break
	fi
	if [[ "${attempt}" == "15" ]]; then
		echo "Application health check did not become ready" >&2
		exit 1
	fi
	sleep 2
done

curl --fail --silent http://127.0.0.1:8080/health
printf '\n'
curl --fail --silent http://127.0.0.1:8080/
printf '\n'
