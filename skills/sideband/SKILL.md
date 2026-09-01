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

**Done when:** the agent lists Sideband tools (names like `list_projects`,
`create_pulse_draft`, and `request_sudo`). If not, see `references/connecting.md` →
Troubleshooting.

## 2. Verify the connection

Confirm the credentials actually resolve to a project before doing anything else.

1. Call `list_projects`.
2. Report the project name(s) and id(s) back to the user.
3. If exactly one project is returned, use it as the default for later steps. If several, ask which one.

**Done when:** at least one project is listed. An empty list or a 401 means the token is wrong or unscoped — see Troubleshooting.

## 3. Obtain write access when needed

Sideband MCP credentials are read-only by default. Reads and `create_pulse_draft` need no
approval. Before `update_project_context`, `create_pulse`, `update_pulse`, or any other
mutation:

1. Call `request_sudo` with a short reason describing the intended change.
2. Ask the user to open the returned browser approval URL.
3. Poll the returned Task with `tasks/get` at `pollIntervalMs`, or use `get_sudo_status`
   with `request_id` at `poll_interval_ms` when Tasks are unavailable.
4. If approved, refresh `tools/list` and continue. If denied, expired, or revoked, stop;
   do not retry the mutation.

Request approval only when the write is ready, because the grant is temporary.

**Done when:** mutation access is approved and the client has refreshed its tool list.

## 4. Keep project context current

Sideband produces better pulse drafts and review feedback when it has an accurate description of the app. Maintain that description with `update_project_context`.

- **When to do it:** the first time you connect, and again whenever the app's purpose, audience, the events it sends, or its key user flows change. This is manual — run it deliberately, not on every commit. (A team can later wire it into a hook or CI step; that's optional and out of scope here.)
- **How:**
  1. Read the codebase and write a concise context document covering: what the app does and who uses it; the events the app sends to Sideband (name, what it means, when it fires); and the main user flows. See `references/context-doc.md` for the recommended outline.
  2. Optionally read the existing context first with `get_project_context` and update rather than restate.
  3. Obtain write access as described above.
  4. Call `update_project_context` with `project_id` and the `body` (the document).

Each call **replaces** the project's stored context with the body you provide, so re-run it whenever the description drifts.

**Done when:** `get_project_context` returns the body you just wrote.

## 5. Create a pulse

Always treat this as draft-first. Never publish without the user's review.

1. **Confirm the target project** (`project_id`). If unknown, run `list_projects`.
2. **Avoid duplicates:** call `list_pulses` and check for an existing pulse with the same intent/name before creating a new one.
3. **Discover real inputs.** Read `get_project_context`, call `list_observed_events` for valid trigger events and metadata keys, and call `list_fab_configs` if the user wants a FAB — choosing `fab` appearance requires both a `fab_config_id` from that list and a `fab_title`, so check what exists before offering it. `list_observed_events` gives you the metadata *keys* an event carries; when you need the *values* a key actually takes, call `list_events` for that event name and read `metadata` on the results.
4. **Draft well.** Follow `references/authoring-pulses.md`: one clear objective, concise non-leading prompts, balanced answer choices, an escape hatch ("None of these" / "Prefer not to say"), and a short completion message.
   - **Ask what they are trying to learn, and save it as `learning_objective`.** It is optional to save but always worth asking: it is what review compares the questions against, and it is the only record of the pulse's intent — nobody can recover it from the questions later.
   - `generate_pulse` (pass a plain-language `goal`) returns a starter skeleton to edit. It is a deterministic template, not a written-for-you draft, and it creates nothing.
5. **Preview without saving.** Call `create_pulse_draft`. Targeting may be omitted during early drafting. Show the returned preview, questions, choices, defaults, and warnings to the user. Apply revisions by calling `create_pulse_draft` again; do not persist an unapproved draft.
6. **Decide the targeting.** `create_pulse` **requires** `targeting_rulesets` — who sees the pulse and after which event. Settle it with the user and preview the complete draft again. See `references/authoring-pulses.md` → Targeting.
7. **Create the approved draft.** Obtain write access, then pass the returned `authoring_pulse` fields to `create_pulse`. It defaults to `draft` status; leave it there.
8. **Verify the saved draft** with `get_pulse`. For later content edits, follow the full-replacement rules in `references/authoring-pulses.md` before calling `update_pulse`.
9. **Publish only on explicit approval** — obtain or renew write access if needed, then set the pulse to active with `update_pulse` (`status: "active"`) as a separate, deliberate step.

**Done when:** `get_pulse` shows the pulse the user approved, in the status they asked for.

## Tool map

The customer-facing tools you'll use, grouped by job. Full list + arguments: `references/authoring-pulses.md`.

| Job | Tools |
|---|---|
| Find your project | `list_projects`, `get_project`, `get_project_status` |
| Project settings | `update_project` (includes `pulse_cooldown_days` — see `references/authoring-pulses.md` → Delivery limits) |
| Obtain write access | `request_sudo`, `get_sudo_status` (or `tasks/get` when supported) |
| Keep context current | `get_project_context`, `update_project_context` |
| Author pulses | `generate_pulse`, `create_pulse_draft`, `create_pulse`, `get_pulse`, `list_pulses`, `update_pulse` |
| Targeting (who/when) | no separate tools — targeting is the `targeting_rulesets` argument on `create_pulse` / `update_pulse` |
| Look at results | `get_pulse_metrics`, `list_responses`, `list_observed_events` (which events, metadata keys and platforms are actually arriving), `list_events` (individual events with their metadata values) |
| Appearance | `list_fab_configs`, `create_fab_config`, `get_fab_config` |

Administrative tools (deleting projects, managing API keys, deleting user data) exist but are out of scope for this skill — use the console for those unless the user explicitly asks.

## Guardrails

- Confirm `project_id` before any write. One wrong id writes to the wrong app.
- Pulses are draft-first; publishing is always a separate, explicitly-approved step.
- Obtain temporary write access only when a mutation is ready, and stop if approval fails.
- Don't create credentials or projects on the user's behalf without asking.
- If a read returns `401`, re-check the connection. If a mutation is unavailable or denied,
  follow the write-access flow in step 3 rather than retrying blindly.
