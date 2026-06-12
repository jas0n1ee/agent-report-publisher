#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${AGENT_REPORT_PUBLISHER_COMPOSE_FILE:-$SCRIPT_DIR/compose.yaml}"
LOCAL_ORIGIN="${AGENT_REPORT_PUBLISHER_LOCAL_ORIGIN:-http://127.0.0.1:8080}"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker CLI not found." >&2
  exit 10
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "ERROR: docker compose plugin not found." >&2
  exit 11
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "ERROR: curl is required to check the local origin." >&2
  exit 12
fi

if ! docker info >/dev/null 2>&1; then
  echo "Docker daemon is not reachable. Trying to start docker via systemctl..." >&2
  if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl start docker
  else
    echo "ERROR: systemctl not found; cannot auto-start Docker." >&2
    exit 11
  fi
fi

if ! docker info >/dev/null 2>&1; then
  echo "ERROR: Docker daemon still not reachable after start attempt." >&2
  exit 12
fi

if [[ -z "${TUNNEL_TOKEN:-}" ]]; then
  echo "ERROR: TUNNEL_TOKEN is not set in the host environment." >&2
  exit 14
fi

if [[ ! -f "$COMPOSE_FILE" ]]; then
  echo "ERROR: compose file not found: $COMPOSE_FILE" >&2
  exit 16
fi

# Nginx may return 404 for / by design. Any HTTP response means the local origin is alive.
HTTP_CODE="$(curl -s -o /dev/null -w '%{http_code}' "$LOCAL_ORIGIN/" || true)"
if [[ "$HTTP_CODE" == "000" ]]; then
  echo "ERROR: local origin not reachable: $LOCAL_ORIGIN" >&2
  exit 17
fi

docker compose -p agent-report-publisher -f "$COMPOSE_FILE" up -d

echo "OK: Docker is running, tunnel compose stack is up, local origin returned HTTP $HTTP_CODE."
