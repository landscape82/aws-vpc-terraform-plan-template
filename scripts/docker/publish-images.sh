#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
DOCKERHUB_USERNAME="${DOCKERHUB_USERNAME:?set DOCKERHUB_USERNAME before publishing}"

if [[ -z "${IMAGE_TAG:-}" ]]; then
	IMAGE_TAG="$(git describe --tags --exact-match 2>/dev/null || git rev-parse --short HEAD)"
fi

cd "${PROJECT_ROOT}"

for image in ip-reverser ip-reverser-no-db; do
	case "${image}" in
		ip-reverser) context="app" ;;
		ip-reverser-no-db) context="app-no-db" ;;
	esac

	remote_image="docker.io/${DOCKERHUB_USERNAME}/${image}:${IMAGE_TAG}"
	docker build --pull -t "${remote_image}" "./${context}"
	docker push "${remote_image}"
done

printf 'Published Docker Hub images with tag %s\n' "${IMAGE_TAG}"
