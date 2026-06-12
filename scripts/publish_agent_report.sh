#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  publish_agent_report.sh /path/to/report.html
  publish_agent_report.sh /path/to/report_bundle_dir

Environment:
  AGENT_REPORT_PUBLISHER_ROOT=/srv/agent-report-publisher
  AGENT_REPORT_PUBLISHER_PUBLIC_BASE_URL=https://reports.example.com

Behavior:
  - File input is copied to /srv/agent-report-publisher/YYYY-MM-DD/<random>.html
  - Directory input must contain index.html and is copied to /srv/agent-report-publisher/YYYY-MM-DD/<random>/
  - Prints LOCAL_PATH and URL when AGENT_REPORT_PUBLISHER_PUBLIC_BASE_URL is set.
USAGE
}

if [[ $# -ne 1 ]]; then
  usage
  exit 2
fi

if ! command -v openssl >/dev/null 2>&1; then
  echo "ERROR: openssl is required to generate report IDs." >&2
  exit 5
fi

SRC="$1"
REPORT_ROOT="${AGENT_REPORT_PUBLISHER_ROOT:-/srv/agent-report-publisher}"
PUBLIC_BASE="${AGENT_REPORT_PUBLISHER_PUBLIC_BASE_URL:-}"
DATE="$(date +%F)"
ID="$(openssl rand -hex 16)"
DEST_DIR="${REPORT_ROOT}/${DATE}"

mkdir -p "$DEST_DIR"

if [[ -f "$SRC" ]]; then
  DEST="${DEST_DIR}/${ID}.html"
  install -m 0644 "$SRC" "$DEST"
  REL_PATH="${DATE}/${ID}.html"
  LOCAL_PATH="$DEST"
elif [[ -d "$SRC" ]]; then
  if [[ ! -f "${SRC}/index.html" || -L "${SRC}/index.html" ]]; then
    echo "ERROR: bundle directory must contain index.html: $SRC" >&2
    exit 3
  fi
  if find "$SRC" -type l -print -quit | grep -q .; then
    echo "ERROR: bundle directory must not contain symlinks: $SRC" >&2
    exit 6
  fi
  DEST="${DEST_DIR}/${ID}"
  mkdir -p "$DEST"
  cp -a "${SRC}/." "$DEST/"
  find "$DEST" -type d -exec chmod 0755 {} +
  find "$DEST" -type f -exec chmod 0644 {} +
  REL_PATH="${DATE}/${ID}/index.html"
  LOCAL_PATH="${DEST}/index.html"
else
  echo "ERROR: source is neither file nor directory: $SRC" >&2
  exit 4
fi

printf 'LOCAL_PATH=%s\n' "$LOCAL_PATH"
printf 'RELATIVE_PATH=%s\n' "$REL_PATH"

if [[ -n "$PUBLIC_BASE" ]]; then
  PUBLIC_BASE="${PUBLIC_BASE%/}"
  printf 'URL=%s/%s\n' "$PUBLIC_BASE" "$REL_PATH"
else
  echo "URL not printed because AGENT_REPORT_PUBLISHER_PUBLIC_BASE_URL is not set." >&2
fi
