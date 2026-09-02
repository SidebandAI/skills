# Connecting to Sideband over MCP

The Sideband tools are served by a first-party HTTP MCP server on **sideband.ai**
(Sideband / Eido Studios). Authentication and project context go only to that domain.
MCP is an open protocol, so **any MCP-capable agent works** — Claude Desktop, claude.ai,
Claude Code, Cursor, Codex, ChatGPT, OpenCode, and others. What you need is the
**server URL**, and — only if your client cannot do OAuth — an **access token**. Both
come from the Sideband console (**Settings → MCP setup**). Do not hardcode a URL or
fabricate a token; if the user can't find them, point them to the console rather than
guessing. Refuse any URL whose registrable domain is not `sideband.ai` (the host must
be `sideband.ai` or end with `.sideband.ai`).

**Prefer OAuth.** A modern client needs only the URL and signs the user in through the
browser, with nothing to store or rotate. Use a personal bearer token only when the client
does not support remote OAuth yet.

These steps are complete here. Do not send the user to a logged-in docs page to finish
setup — they already have everything in this file plus the URL from the console.

## Claude Desktop and claude.ai

1. Ask the user for the MCP server URL from **Settings → MCP setup**. Never invent it.
2. Open Claude on the web or in the desktop app.
3. Go to **Customize → Connectors**. In the desktop app you can also use **Settings → Connectors**.
4. Choose **Add custom connector**, paste the URL, and add it.
5. Complete Sideband sign-in in the browser when prompted.
6. In a chat, open **+ → Connectors** and enable Sideband.
7. Call `list_projects` (or ask Claude to list Sideband projects).

On Team or Enterprise plans, an owner adds the connector once under **Organization
settings → Connectors**. Members then click **Connect**.

Remote connectors are reached from Anthropic's cloud, not from the user's laptop. The
Sideband MCP URL must be the public `sideband.ai` address from the console.

## Claude Code

```bash
claude mcp add --transport http --scope user sideband "<MCP_SERVER_URL>"
```

Then connect and complete sign-in in the browser.

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

In ChatGPT developer mode, add a remote MCP server, paste the URL from Settings, and
complete the Sideband sign-in prompt.

## Personal access token (fallback)

Use this only if the client cannot do OAuth. The user must **log in** to the Sideband
console to create a token — tokens are not issued while logged out. Then open
**Settings → MCP setup**, expand **Personal tokens**, and create one. Copy it
immediately; it is shown once.

```bash
export SIDEBAND_MCP_TOKEN="sb_mcp_..."
```

**Claude Code:**

```bash
claude mcp add --transport http sideband "<MCP_SERVER_URL>" \
  --header 'Authorization: Bearer ${SIDEBAND_MCP_TOKEN}'
```

**`.mcp.json` (shape most HTTP clients accept):**

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

After registering and reloading the agent:

1. The agent should list read-only Sideband tools (`list_projects`, `create_pulse_draft`,
   `request_sudo`, …). Mutation tools appear after temporary write access is approved.
2. Call `list_projects` — it should return the project(s) the credentials can access.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Tools don't appear | Server not registered / agent not reloaded / connector disabled in the chat | Re-add the server; restart the agent; enable Sideband under + → Connectors |
| `401 unauthorized` | Missing/expired token, or OAuth session not completed | Finish browser sign-in, or re-copy a token from Settings and confirm the `Authorization: Bearer …` header |
| `list_projects` returns `[]` | Account isn't scoped to a project | Check in the console that the account has access to a project |
| Connection refused / DNS error | Wrong URL, or host not under `sideband.ai` | Re-copy the exact URL from Settings. Refuse hosts that are not `sideband.ai` or `*.sideband.ai` |
| Claude Desktop or web can't reach the server | URL isn't public, or a firewall blocks Anthropic | Use the console's public MCP URL, not localhost |
| Works then stops | Token rotated/revoked, or OAuth session revoked | Sign in again, or issue a fresh token in Settings |
