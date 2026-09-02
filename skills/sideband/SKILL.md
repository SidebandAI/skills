---
name: sideband
description: Use when the user wants to install, set up, connect, or configure the Sideband MCP server; verify or troubleshoot a Sideband connection; describe their app to Sideband / keep its project context up to date; or create, draft, review, or publish a pulse (in-app survey). Triggers include "install sideband", "connect sideband mcp", "set up sideband", "verify sideband connection", "is sideband connected", "create a pulse", "draft a survey", "update sideband context".
---

# Sideband

If read tools are missing (`list_projects` is not listed), follow
`references/connecting.md`. Copy the MCP URL from console → Settings → MCP setup.
Refuse any host that is not `sideband.ai` or `*.sideband.ai`.

`create_pulse_draft` is not a write. Call `request_sudo` only when a mutation is
ready. Immediately put `approval_url` in the chat and ask the user to open it.
Then poll only `get_sudo_status` at the returned `poll_interval_ms` until
terminal. Do not call create/update/delete while status is `pending`. Do not
retry the mutation as a stand-in for polling. Do not stop polling for a chat
reply while pending. Stop polling after 30 minutes — the request has expired
by then; do not retry the mutation. After approval, refresh `tools/list` and
retry the original write. If denied, expired, or revoked, stop.
The grant is short-lived. Later writes, including publish, may need `request_sudo` again.

`list_projects` first. Report name and id. If several, ask which.
`[]` or `401` on a read → `references/connecting.md` (credentials).
Mutation tools missing while reads work → `request_sudo`. Do not retry a denied mutation.

## Context

On first connect, and when purpose, audience, events, or flows change.
Read the repo. Outline: `references/context-doc.md`.
`get_project_context` first. `update_project_context` replaces the whole body.

## Pulses

Draft-first. First screen is a sentiment `yes_no` (yes = happy, no = not) or a
FAB; then branch. Short prompts and labels. Trigger on user-initiated events
only. Do not set `status: "active"` on create. Publish only with `update_pulse`
after the user explicitly says publish.

1. Resolve `project_id` from `list_projects`.
2. `list_pulses` — if one has the same intent, ask whether to reuse it.
3. Inputs: `get_project_context`, `list_observed_events` (keys), `list_events` (values), `list_fab_configs`.
4. Ask `learning_objective`. Rules: `references/authoring-pulses.md`.
5. `create_pulse_draft` until they approve. Show preview, defaults, and warnings. Targeting may be omitted here.
6. Set `targeting_rulesets`, then `create_pulse_draft` once more. Pass the returned `authoring_pulse` to `create_pulse`. Leave status `draft`.
7. `get_pulse` to verify.
8. Later edits: `get_pulse`, then `update_pulse` — full-replace rules in `references/authoring-pulses.md`.
9. Publish: `update_pulse` (`status: "active"`) only on explicit approval.

When talking to the user, refer to a pulse as **name (`id`)**. Do not lead with
the id.

Do not create projects, API keys, or credentials unless asked.
Wrong `project_id` writes to the wrong app.
