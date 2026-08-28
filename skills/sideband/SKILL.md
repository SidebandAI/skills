---
name: sideband
description: Connect to and operate Sideband from your coding agent. Use when the user wants to install, set up, connect, or configure the Sideband MCP server; verify or troubleshoot a Sideband connection; describe their app to Sideband / keep its project context up to date; or create, draft, review, or publish a pulse (in-app survey). Triggers include "install sideband", "connect sideband mcp", "set up sideband", "verify sideband connection", "is sideband connected", "create a pulse", "draft a survey", "update sideband context".
---

# Sideband Agent

Sideband collects in-app feedback through **pulses** (short, targeted surveys) and the **events** your app already sends. This skill helps you connect a coding agent to Sideband over MCP, keep Sideband's understanding of the app current, and author good pulses.

Work the steps in order. Each step has a "done when" check — don't move on until it passes.

## 1. Connect (do this first, once)

The Sideband tools are exposed through a standard MCP server, so **any MCP-capable agent** (Claude Code, Cursor, opencode, and others) can use them — these instructions are not specific to one tool. You can't call the tools until the agent's MCP client is configured. The connection URL and an access token both come from the **Sideband console → Settings** page — never invent or hardcode either.

1. Ask the user to open the Sideband console → **Settings → MCP setup** and copy the
   **MCP server URL** (an `mcp.`-prefixed address). Never invent the URL. Do not send them
   to other Sideband pages for setup steps — this skill already has them.
2. Register the server with the agent's MCP client. Most clients discover OAuth from the
   URL alone and prompt for browser sign-in — no token to manage.
   - **Claude Desktop / claude.ai:** Customize → Connectors → Add custom connector → paste
     the URL → sign in → enable Sideband under + → Connectors. Full steps:
     `references/connecting.md`.
   - **Claude Code:**
     ```bash
     claude mcp add --transport http --scope user sideband "<MCP_SERVER_URL>"
     ```
     Then connect and complete sign-in in the browser.
   For a client that does not support OAuth yet, Settings can issue a personal bearer
   token (`SIDEBAND_MCP_TOKEN`) to send as an `Authorization: Bearer <token>` header.
   Per-client snippets and troubleshooting: `references/connecting.md`.
3. Restart / reload the agent so it picks up the new server.

**Done when:** the agent lists Sideband tools (names like `list_projects`, `create_pulse`). If not, see `references/connecting.md` → Troubleshooting.

## 2. Verify the connection

Confirm the credentials actually resolve to a project before doing anything else.

1. Call `list_projects`.
2. Report the project name(s) and id(s) back to the user.
3. If exactly one project is returned, use it as the default for later steps. If several, ask which one.

**Done when:** at least one project is listed. An empty list or a 401 means the token is wrong or unscoped — see Troubleshooting.

## 3. Keep project context current

Sideband produces better pulse drafts and review feedback when it has an accurate description of the app. Maintain that description with `update_project_context`.

- **When to do it:** the first time you connect, and again whenever the app's purpose, audience, the events it sends, or its key user flows change. This is manual — run it deliberately, not on every commit. (A team can later wire it into a hook or CI step; that's optional and out of scope here.)
- **How:**
  1. Read the codebase and write a concise context document covering: what the app does and who uses it; the events the app sends to Sideband (name, what it means, when it fires); and the main user flows. See `references/context-doc.md` for the recommended outline.
  2. Optionally read the existing context first with `get_project_context` and update rather than restate.
  3. Call `update_project_context` with `project_id` and the `body` (the document).

Each call **replaces** the project's stored context with the body you provide, so re-run it whenever the description drifts.

**Done when:** `get_project_context` returns the body you just wrote.

## 4. Create a pulse

Always treat this as draft-first. Never publish without the user's review.

1. **Confirm the target project** (`project_id`). If unknown, run `list_projects`.
2. **Avoid duplicates:** call `list_pulses` and check for an existing pulse with the same intent/name before creating a new one.
3. **Draft well.** Follow `references/authoring-pulses.md`: one clear objective, concise non-leading prompts, balanced answer choices, an escape hatch ("None of these" / "Prefer not to say"), and a short completion message.
   - `generate_pulse` (pass a plain-language `goal`) returns a starter skeleton to edit. It is a deterministic template, not a written-for-you draft, and it creates nothing.
4. **Decide the targeting.** `create_pulse` **requires** `targeting_rulesets` — who sees the pulse and after which event. There is no way to create a pulse without it, so settle it with the user before the call. See `references/authoring-pulses.md` → Targeting.
5. **Create it as a draft** with `create_pulse` (it defaults to `draft` status — leave it there).
6. **Review with the user.** Show the drafted questions and choices. Make edits with `update_pulse`.
7. **Publish only on explicit approval** — set the pulse to active with `update_pulse` (`status: "active"`) as a separate, deliberate step.

**Done when:** `get_pulse` shows the pulse the user approved, in the status they asked for.

## Tool map

The customer-facing tools you'll use, grouped by job. Full list + arguments: `references/authoring-pulses.md`.

| Job | Tools |
|---|---|
| Find your project | `list_projects`, `get_project`, `get_project_status` |
| Keep context current | `get_project_context`, `update_project_context` |
| Author pulses | `generate_pulse`, `create_pulse`, `get_pulse`, `list_pulses`, `update_pulse` |
| Targeting (who/when) | no separate tools — targeting is the `targeting_rulesets` argument on `create_pulse` / `update_pulse` |
| Look at results | `get_pulse_metrics`, `list_responses`, `list_events`, `list_observed_events` (which events, metadata keys and platforms are actually arriving) |
| Appearance | `list_fab_configs`, `create_fab_config`, `get_fab_config` |

Administrative tools (deleting projects, managing API keys, deleting user data) exist but are out of scope for this skill — use the console for those unless the user explicitly asks.

## Guardrails

- Confirm `project_id` before any write. One wrong id writes to the wrong app.
- Pulses are draft-first; publishing is always a separate, explicitly-approved step.
- Don't create credentials or projects on the user's behalf without asking.
- If a tool returns an auth/permission error, stop and re-check the connection (step 2) rather than retrying blindly.
