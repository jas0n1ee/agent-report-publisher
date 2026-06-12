#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT_ROOT="${AGENT_REPORT_PUBLISHER_ROOT:-/srv/agent-report-publisher}"
NGINX_AVAILABLE="/etc/nginx/sites-available/agent-report-publisher"
NGINX_ENABLED="/etc/nginx/sites-enabled/agent-report-publisher"
OWNER="${SUDO_USER:-${USER:-$(id -un)}}"
ESCAPED_REPORT_ROOT="${REPORT_ROOT//\\/\\\\}"
ESCAPED_REPORT_ROOT="${ESCAPED_REPORT_ROOT//&/\\&}"

sudo mkdir -p "$REPORT_ROOT"
sudo chown -R "$OWNER":"$OWNER" "$REPORT_ROOT"
sed "s#/srv/agent-report-publisher#$ESCAPED_REPORT_ROOT#g" "$SCRIPT_DIR/agent-report-publisher-nginx.conf" | sudo tee "$NGINX_AVAILABLE" >/dev/null
sudo ln -sf "$NGINX_AVAILABLE" "$NGINX_ENABLED"
sudo nginx -t
sudo systemctl reload nginx

echo "OK: Nginx report server configured. Root: $REPORT_ROOT. Origin: http://127.0.0.1:8080"
