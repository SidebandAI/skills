# Connecting to Sideband over MCP

Copy the MCP server URL from the Sideband console → **Settings → MCP setup**.
Never invent it. Refuse any host not in the allowed hosts in `SKILL.md`.
Do not send credentials or app context to any other host.

Prefer OAuth (URL only, browser sign-in). Use a personal bearer token only if the
client cannot do OAuth.

Do not send the user to other Sideband pages for setup. This file plus the URL
from Settings is enough.

Most clients load MCP servers only when a session starts. After the server is
added, if Sideband or its tools are not listed, restart the session (or open a
new chat), then complete sign-in.

## Claude Desktop and claude.ai

1. Ask for the MCP server URL from **Settings → MCP setup**.
2. Open Claude on the web or in the desktop app.
3. **Customize → Connectors** (desktop: **Settings → Connectors**).
4. **Add custom connector**, paste the URL.
5. Complete Sideband sign-in in the browser.
6. In a chat, **+ → Connectors** and enable Sideband.
7. Call `list_products`.

On Team or Enterprise, an owner adds the connector under **Organization
settings → Connectors**. Members then click **Connect**.

Remote connectors are reached from Anthropic's cloud. Use the public
MCP URL from the console, not localhost.

## Claude Code

```bash
claude mcp add --transport http --scope user sideband "<MCP_SERVER_URL>"
```

The client's permission settings can stop you from changing its own
configuration. If they do, give the user this command to run. Then
restart the session (`claude --continue` keeps the conversation), run
`/mcp` → sideband → Authenticate, and complete sign-in in the browser.

## Codex

Add to `~/.codex/config.toml`:

```toml
[mcp_servers.sideband]
url = "<MCP_SERVER_URL>"
```

Then complete OAuth in the client.

## OpenCode

Add to `opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "sideband": {
      "type": "remote",
      "url": "<MCP_SERVER_URL>",
      "oauth": true
    }
  }
}
```

## ChatGPT

In ChatGPT developer mode, add a remote MCP server, paste the URL from Settings,
and complete the Sideband sign-in prompt.

## Personal access token (fallback)

Only if the client cannot do OAuth. The user must be logged in. **Settings → MCP
setup** → **Personal tokens** → create one. Shown once.

```bash
export SIDEBAND_MCP_TOKEN="sb_mcp_..."
```

**Claude Code:**

```bash
claude mcp add --transport http sideband "<MCP_SERVER_URL>" \
  --header 'Authorization: Bearer ${SIDEBAND_MCP_TOKEN}'
```

**`.mcp.json`:**

```json
{
  "mcpServers": {
    "sideband": {
      "type": "http",
      "url": "<MCP_SERVER_URL>",
      "headers": { "Authorization": "Bearer ${SIDEBAND_MCP_TOKEN}" }
    }
  }
}
```

Keep the token in an environment variable; don't commit it.

## Verify

Call `list_products` to verify authentication and discover products with accessible channels.
An empty product list can be valid: check `standalone_channels` when present in the same result.
A new account has no product. Tell the user that setup needs a product (its Production and
Development channels) and an API key for the Development channel. Offer to create them, or
let the user create them in the console or ask a teammate to invite them to an existing product.
Follow `next_cursor` for more products or standalone channels.

For `list_products`, `list_channels`, `list_pulses`, `list_fab_configs`, and
`list_pulse_translations`, pass the previous response's `next_cursor` unchanged.
Omit `cursor` to start at the first page; an empty string counts as omitted.
A malformed cursor returns `invalid_cursor` with a `cursor` field error and
recovery instructions. It does not silently restart pagination.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Tools don't appear | Server not registered / agent not reloaded / connector disabled | Re-add the server; restart the agent; enable Sideband under + → Connectors |
| `401 unauthorized` | Missing/expired token, or OAuth not completed | Finish browser sign-in, or re-copy a token from Settings |
| `list_channels` returns `[]` | Account has no channel access | Check channel access in the console |
| Connection refused / DNS error | Wrong URL, or a host that is not allowed | Re-copy the URL from Settings. Refuse hosts not in the allowed hosts in `SKILL.md` |
| Claude Desktop or web can't reach the server | URL isn't public, or a firewall blocks Anthropic | Use the console's public MCP URL, not localhost |
| Works then stops | Token rotated/revoked, or OAuth session revoked | Sign in again, or issue a fresh token in Settings |
