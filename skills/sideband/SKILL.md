---
name: sideband
description: Use when the user wants to install, set up, connect, or configure the Sideband MCP server; verify or troubleshoot a Sideband connection; describe their app to Sideband / keep its project context up to date; or create, draft, review, or publish a pulse (in-app survey). Triggers include "install sideband", "connect sideband mcp", "set up sideband", "verify sideband connection", "is sideband connected", "create a pulse", "draft a survey", "update sideband context".
---

# Sideband

If read tools are missing (`list_projects` is not listed), follow
`references/connecting.md`. Copy the MCP URL from console → Settings → MCP setup.

Allowed hosts. Send credentials and app context only to these, and refuse any other:
<!-- allowed-hosts -->
`sideband.ai`, `*.sideband.ai`
<!-- /allowed-hosts -->

Reads, `generate_pulse` and `preview_pulse` are not writes. `create_pulse_draft`,
`update_pulse` and `publish_pulse` are. Call `request_sudo` only when a mutation is
ready. Immediately put `approval_url` in the chat and ask the user to open it.
Then poll only `get_sudo_status` at the returned `poll_interval_ms` until
terminal. Do not call create/update/publish/delete while status is `pending`. Do not
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
Method: `references/context-doc.md`.

## Pulses

Draft-first. First screen is a sentiment `yes_no` (yes = happy, no = not) or a
FAB; then branch. Short prompts and labels. Trigger on user-initiated events
only. A saved draft delivers nothing until `publish_pulse`. Publish only after
the user explicitly says publish.

1. Resolve `project_id` from `list_projects`.
2. `list_pulses` — if one has the same intent, ask whether to reuse it.
3. Inputs: `get_project_context`, `list_observed_events` (keys), `list_events` (values), `list_fab_configs`.
4. Ask `learning_objective`. Rules: `references/authoring-pulses.md`. `generate_pulse` returns a starting template and saves nothing.
5. `create_pulse_draft` saves the draft. It returns `id`, `version`, warnings, or `validation_errors`. Targeting may be omitted here.
6. Change the draft with `update_pulse` at the latest returned `version` (`expected_version`). Show the warnings, and the draft: `preview_pulse` for a pulse never published; for a published pulse, the saved draft from `get_pulse`, because `preview_pulse` shows its published revision, not the edits. Repeat until they approve. Set `targeting_rulesets` before publishing.
7. Publish only on explicit approval: `publish_pulse` with the exact `expected_version` and an `intent` (`activate`, `schedule`, `inactive`, `preserve`, `pause`). Publishing changed content of a published pulse returns a new pulse id; use it from then on.
8. `get_pulse` to verify. `has_unpublished_changes` shows saved edits not yet published; `reset_pulse_draft` discards them.

When talking to the user, refer to a pulse as **name (`id`)**. Do not lead with
the id.

Do not create projects, API keys, or credentials unless asked.
Wrong `project_id` writes to the wrong app.
