# Agent Report Publisher

Publish Agent-generated HTML reports from this machine through local Nginx and Cloudflare Tunnel.

## Install

Install globally for all supported agents:

```bash
npx skills add git@github.com:jas0n1ee/agent-report-publisher.git -g --all
```

Install only for the current project and choose prompts interactively:

```bash
npx skills add git@github.com:jas0n1ee/agent-report-publisher.git
```

If SSH access to GitHub is not configured, use HTTPS instead:

```bash
npx skills add https://github.com/jas0n1ee/agent-report-publisher.git -g --all
```

## Configure Environment

Set the Cloudflare Tunnel token and public report base URL in the host shell profile. Do not store the real token in this repository.

For Bash, add this near the top of `~/.bashrc`, before any non-interactive `return` guard:

```bash
export TUNNEL_TOKEN="<cloudflare-tunnel-token>"
export AGENT_REPORT_PUBLISHER_PUBLIC_BASE_URL="https://reports.example.com"
```

For Zsh, add this to `~/.zprofile`:

```zsh
export TUNNEL_TOKEN="<cloudflare-tunnel-token>"
export AGENT_REPORT_PUBLISHER_PUBLIC_BASE_URL="https://reports.example.com"
```

Reload the profile:

```bash
source ~/.bashrc
# or
source ~/.zprofile
```

Verify without printing the token:

```bash
test -n "$TUNNEL_TOKEN" && echo "TUNNEL_TOKEN is set"
test -n "$AGENT_REPORT_PUBLISHER_PUBLIC_BASE_URL" && echo "report URL is set"
```

## Machine Setup

The skill expects local Nginx to serve `/srv/agent-reports` on `127.0.0.1:8080`, and Cloudflare Tunnel to route the public hostname to that local origin.

After installation, run the bundled setup script from the installed skill directory:

```bash
scripts/install_agent_report_publisher_nginx.sh
```

Then verify and start the tunnel:

```bash
scripts/ensure_agent_report_publisher.sh
```

## Publish Check

Create and publish a small HTML file:

```bash
tmp="$(mktemp --suffix=.html)"
printf '<!doctype html><html><body>hello</body></html>\n' > "$tmp"
scripts/publish_agent_report.sh "$tmp"
```

The script prints `LOCAL_PATH`, `RELATIVE_PATH`, and `URL`. Open or `curl` the URL to confirm the report is public.
