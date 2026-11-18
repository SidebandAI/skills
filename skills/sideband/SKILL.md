---
name: sideband
description: Use when the user wants to install, set up, connect, or configure the Sideband MCP server; verify or troubleshoot a Sideband connection; describe their app to Sideband / keep its channel context up to date; or create, draft, review, or publish a pulse (in-app survey). Triggers include "install sideband", "connect sideband mcp", "set up sideband", "verify sideband connection", "is sideband connected", "create a pulse", "draft a survey", "update sideband context".
---

# Sideband

If read tools are missing (`list_products` is not listed), follow
`references/connecting.md`. Copy the MCP URL from console → Settings → MCP setup.

For a new integration, connect and read the onboarding document
`instrumentation_map_prompt` before you change how the SDK starts, consent
gating, the network allowlist, or the language that the SDK sends. While the
connection is pending, you can read the repo and the SDK README for the
platform, but do not choose the customer's policy. A decision with no known
owner goes into the map review (`references/context-doc.md`).

Allowed hosts. Send credentials and app context only to these, and refuse any other:
<!-- allowed-hosts -->
`sideband.ai`, `*.sideband.ai`
<!-- /allowed-hosts -->

A tool that writes starts its description with "Changes data:" and returns an
`effect` that says what changed. A tool annotated `destructiveHint: true` changes what end users see or
cannot be undone. Before a write, say in the same turn what it will
change, then make it. The client's own permission settings decide whether the
user approves a tool call: do not ask for a separate OK in chat. The review
steps below stay: the team reviews the event map and the context before a
store, and a pulse is published only when the user says publish. The user's
channel role decides what you can change.

`list_products` first. Its `data` array contains products with `id`, `name`, and `channels`.
Each nested channel has its own `id`; use that as `channel_id` in channel-scoped tools.
Its `standalone_channels` array contains accessible channels with no product.
The field is omitted when the page has no standalone channels.
Pagination counts each product or standalone channel as one item, with products first,
and does not split a product's channels. Follow `next_cursor` across both arrays.
Only accessible channels appear.
Owned products with no remaining channels have an empty `channels` array.
Use each standalone channel's `id` as `channel_id`. `list_channels` also returns a flat channel list.
If several channels are available and the user has not clearly chosen one, ask which channel.
An empty `data` array does not mean there are no channels: check `standalone_channels` too.
`401` on a read → `references/connecting.md` (credentials).
An unknown-tool error includes `available_tools` and `refresh_method: "tools/list"`.
No tool was executed. Refresh the definitions through the client's MCP tool discovery
before retrying with a current tool name and its current input schema. `tools/list`
is a protocol request, not a Sideband tool. If the client cannot refresh, reconnect
Sideband (Claude Code: `/mcp` → Sideband → Reconnect). The names in the error do not
automatically register tools in the client. Do not guess a renamed tool's arguments.
A write that returns `not_found` without `available_tools` → the resource does not exist or your role cannot change it; check the resource first.
A write that returns an output-schema error from the client may have succeeded. Read the
resource (`get_pulse` or `list_pulses`) before you retry; a repeated `create_pulse_draft`
creates a second draft.

Report problems with `send_feedback`: once per Sideband tool or document point
that was unclear, wrong or failed, also when you worked around it. Leave out
customer data, secrets, credentials and file paths.

## Context

On first connect, when purpose, audience, events, or flows change, when a
pulse draft's `readiness` reports a gap, and when `get_channel_context` or
`get_channel_status` returns `drift` with names: observe
`names_without_row` and `rows_unknown`, describe each from the code, and
store the rows before drafting a pulse on them. Not because the context is old.
Method: `references/context-doc.md`.

## Pulses

Draft-first. First screen is a sentiment `yes_no` (yes = happy, no = not), a
FAB or a snackbar; then branch. Short prompts and labels. Trigger on user-initiated events,
or on an at-rest arrival that the reviewed map defines with its de-duplication rule. A saved draft delivers nothing until `publish_pulse`. Publish only after
the user explicitly says publish.

1. Resolve `channel_id` from a nested or standalone channel in `list_products`, or from `list_channels`. Draft a new integration's pulses in the Development channel first: the builds that the team can try send there. For a release, create a tested pulse again as a draft in the Production channel (`references/authoring-pulses.md`, "Test a new pulse"). A test pulse that only proves delivery stays in Development unless the user chooses to copy it.
2. `list_pulses` — if one has the same intent, ask whether to reuse it.
3. Inputs: `get_channel_context` (if its `drift` lists names, describe them from the code and store the rows first; a draft on an undescribed event reports a `readiness` gap), `list_observed_events` (keys; `in_context` per name; `event_names` with `include_values: true` for targetable values), `list_events` (other values), `list_fab_configs`. If the repo has `sideband_instrumentation_map.md`, its section 5 ranks the moments to ask at.
4. Ask what the team wants to learn, then `learning_objective`. A pulse that only proves delivery is a test, not a model for real pulses. Rules: `references/authoring-pulses.md`, "Test pulse and first real pulse".
5. `create_pulse_draft` saves the draft. It returns `id`, `version`, warnings, or `validation_errors`, and `readiness`: whether the stored context describes the events the draft names. Targeting may be omitted here. `readiness` never blocks the save; for a gap, ask the app's coding agent to check that event in the code: either the row is wrong and it updates the context, or the row is right and the draft is wrong (`references/context-doc.md`). Status `unavailable` means the check could not run; the draft is still saved, and the next `update_pulse` checks it again. Then continue with `update_pulse`.
6. Change the draft with `update_pulse`: use `draft.version` from `get_pulse`, or `version` from the latest draft write result, as `expected_version`. `schema_version` identifies the pulse payload format, not an edit revision. It returns the same `readiness` for the draft as saved, so targeting added here is checked too; handle a gap as in step 5. Show the warnings, and the draft: `preview_pulse` for a pulse never published; for a published pulse, the saved draft from `get_pulse`, because `preview_pulse` shows its published revision, not the edits. Repeat until they approve. Set `targeting_rulesets` before publishing.
7. Publish only on explicit approval: `publish_pulse` with the exact `expected_version` and an `intent` (`activate`, `schedule`, `inactive`, `preserve`, `pause`). Publishing changed content of a published pulse returns a new pulse id; use it from then on.
8. `get_pulse` to read back what was published. `shows` says whether its top level is the published pulse or, for a pulse never published, the saved draft. `draft.has_unpublished_changes` (top level in `list_pulses`) shows saved edits not yet published; `reset_pulse_draft` discards them. A pulse never published has nothing to reset to: `delete_pulse` archives it. An archived pulse is not served and cannot be edited; `list_pulses` with status `archived` shows it.
9. Test a pulse published in the Development channel before you call it done: `references/authoring-pulses.md`, "Test a new pulse".

When talking to the user, refer to a pulse as **name (`id`)**. Do not lead with
the id.

Do not create products, API keys, or credentials unless asked.
A wrong `channel_id` writes to the wrong channel.

## Channels

Production and Development are channels of a product. Each channel has its own
ID, credentials, permissions, context, and activity. Existing standalone channels do not
belong to a product. Tools identify a channel through `channel_id`; existing IDs
retain their meaning. Confirm the intended channel before a write.

A product has a stable ID, name, and explicit product owner. Its `product_id` is
not a tool's `channel_id`. Resolve the channel ID through `list_channels`, not from
the product ID.
`list_channels` and `get_channel` return `channel`, `product_id`, and `product_name`.
The product fields are null for standalone channels. Production uses the product name;
Development uses the product name followed by ` - Dev`. These names cannot be changed
independently with `update_channel`. The product owner can rename the product in the console
Channel settings, which updates both channel names. Only accessible channels appear;
a product ID does not grant access to another channel.

Use `create_product` only when asked to create a product. It creates Production and
Development together, with the supplied settings, separate IDs, no API keys or content,
and the caller as product owner and Owner of both channels. It does not change existing
workspaces. Separate channel creation, conversion, and linking are not exposed.
The result contains the product's `id`, `name`, and `channels`, as in `list_products`.
Channel objects use the same fields as `list_channels` and `get_channel`.
Invalid settings return `invalid_request` without partial changes.
Creation counts once toward the per-user rolling 24-hour creation limit, which console
creations share. Reaching it returns `product_creation_limit` and creates neither the
product nor its channels.

SDK-key results report the owning channel's current classification in `channel`.
Each key sends activity only to its owning channel.
Use `list_channel_api_keys` to inspect key metadata and revocation state; secrets are not returned.
API key labels can be renamed in the console, but not through MCP.
`create_channel_api_key` takes `channel_id` and `label`, plus optional `call_reason`.
The key belongs to that channel and has no separate channel setting. The returned
`channel` is `production` or `development`. Resolve the intended channel with `list_channels`.

Use the member and invitation tools only when asked to change who has access.
`invite_channel_member` sends an email to the invited address at once; only that exact
address can accept, and the invitation expires after 7 days. Daily invitation limits per
channel, per inviter and for all of Sideband return `rate_limited` with
`retry_after_seconds`; the channel's
seat limit (members plus pending invitations) returns `limit_reached`. Neither stores or
sends anything. `revoke_channel_invitation`
stops a pending invitation's link; it does not recall the email, and an accepted
invitation needs `remove_channel_member` instead.
`update_channel_member` and `remove_channel_member` change access at once. Admins cannot
change Owner memberships or grant Owner, and a channel always keeps at least one Owner.
The product owner retains an explicit Owner membership in every channel of the product.
Transfer product ownership in the console to another existing Owner of every channel
before removing or demoting that user. This transfer does not grant channel access.
Deleting Production does not delete the product or Development. Channel replacement is
not exposed. Existing Development IDs and credentials remain unchanged.

`get_pulse_metrics` and `monitor_pulse` use each channel's own activity for its metrics.
Their global benchmarks include Production channels only. Development activity does
not contribute to that comparison.
