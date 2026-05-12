#!/bin/sh
set -eu

sleep 5

until mc alias set local http://minio:9000 "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}"; do
  echo "Waiting for MinIO..."
  sleep 3
done

mc mb --ignore-existing local/source-codes
mc mb --ignore-existing local/analysis-artifacts

echo "=== MinIO buckets created: source-codes, analysis-artifacts ==="
