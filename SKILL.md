---
name: agent-report-publisher
description: Publish Agent-produced HTML reports and static report bundles from the local machine through Nginx and Cloudflare Tunnel. Use when an Agent has produced an HTML report, image/table-rich experiment summary, or static report bundle that should be hosted from the current machine and exposed through an existing Cloudflare Tunnel public hostname.
---

# Agent Report Publisher

## Quick Start

Publish a self-contained HTML report or a bundle directory containing `index.html`:

```bash
scripts/ensure_agent_report_publisher.sh
scripts/publish_agent_report.sh /path/to/report.html
scripts/publish_agent_report.sh /path/to/report_bundle_dir
```

The helper prints `LOCAL_PATH`, `RELATIVE_PATH`, and `URL` when `AGENT_REPORT_PUBLISHER_PUBLIC_BASE_URL` is set.

## Runtime Contract

- Report root: `/srv/agent-report-publisher`
- Local origin: `http://127.0.0.1:8080`
- Compose file: `scripts/compose.yaml` in this skill directory
- Scripts: `scripts/`

Machine-specific values must come from the host environment, such as `~/.bashrc`, `~/.profile`, or a systemd environment file:

```bash
export TUNNEL_TOKEN="<Cloudflare Tunnel token>"
export AGENT_REPORT_PUBLISHER_PUBLIC_BASE_URL="https://reports.example.com"
```

Do not store the real tunnel token in this skill directory. Host environment exports are the runtime configuration source.

## Publishing Workflow

1. Treat the report as static content.
2. Prefer one self-contained HTML file; inline CSS and base64 images are acceptable.
3. Avoid external CDNs, third-party fonts, analytics, and remote JavaScript unless explicitly requested.
4. Run `scripts/ensure_agent_report_publisher.sh`.
5. Run `scripts/publish_agent_report.sh /path/to/report.html` or pass a bundle directory containing `index.html`.
6. Return the printed `URL` and `LOCAL_PATH`.

Storage layout:

```text
/srv/agent-report-publisher/YYYY-MM-DD/<128-bit-random-id>.html
/srv/agent-report-publisher/YYYY-MM-DD/<128-bit-random-id>/index.html
```

Do not create public index pages, `latest.html`, predictable filenames, or directory listings unless explicitly requested.

## Setup Workflow

```bash
scripts/install_agent_report_publisher_nginx.sh
```

```text
/etc/nginx/sites-available/agent-report-publisher
/etc/nginx/sites-enabled/agent-report-publisher
/srv/agent-report-publisher/
```

Cloudflare Tunnel route:

```text
Type: HTTP
URL: 127.0.0.1:8080
```

## Security Defaults

- Nginx uses `autoindex off` and returns `404` at `/`.
- Filenames are generated with at least 128 bits of entropy.
- Headers include `X-Robots-Tag`, `Referrer-Policy`, `X-Content-Type-Options`, and a CSP that disables JavaScript.
- Static bundles must not contain symlinks.
- A random URL is discovery resistance, not authentication.

For sensitive reports, recommend Cloudflare Access, email OTP, SSO, or another real authentication layer. For interactive reports, prefer local same-origin JavaScript and update the CSP deliberately.

## Troubleshooting

```bash
curl -I http://127.0.0.1:8080/<known-report>.html
docker compose -p agent-report-publisher -f scripts/compose.yaml ps
docker compose -p agent-report-publisher -f scripts/compose.yaml logs --tail=80
```

If Nginx returns `404`, check the file path under `/srv/agent-report-publisher`. `403` on a directory is expected when no `index.html` exists.
