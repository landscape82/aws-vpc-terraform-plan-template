#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
IMAGE_TAG="${IMAGE_TAG:-local}"

cd "${PROJECT_ROOT}"

docker build --pull -t "ip-reverser:${IMAGE_TAG}" ./app
docker build --pull -t "ip-reverser-no-db:${IMAGE_TAG}" ./app-no-db

printf 'Built images with tag %s\n' "${IMAGE_TAG}"
