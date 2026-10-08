# Project context

Sideband's onboarding documents carry the method. Fetch each with
`get_onboarding_document` and follow it as returned.

- No context stored yet (`get_project_context` returns a null body):
  run `instrumentation_map_prompt` against the repo. It writes
  `sideband_instrumentation_map.md`, then stores the first context.
- Format: `context_contract`. Five sections, the events table, and the
  checks every store runs. Store results return findings as `warnings`;
  fix every `fail`.
- Events go in the code after the context is stored: `implement_events_prompt`.
  It commits the reviewed map with `docs/SIDEBAND_EVENTS.md`; keep both
  current when an event changes.

Keep it current:

1. `list_project_context_questions`. Answer each question from the code.
2. `submit_project_context_answers` records the answers. It stores a new
   version only when they change the document.
3. A correction no question covers: `get_project_context`, edit that body,
   and store it with `update_project_context`. It replaces the whole body.

Prefer events from `list_observed_events` over events you inferred.
An event the app never sends is worse than one you left out.
