# Project context

Sideband's onboarding documents carry the method. Fetch each with
`get_onboarding_document` and follow it as returned.

- No context stored yet (`get_project_context` returns a null body):
  run `instrumentation_map_prompt` against the repo. It writes
  `sideband_instrumentation_map.md` and a draft context, which the user
  reviews with the map before the one store.
- Format: `context_contract`. Five sections, the events table, and the
  checks Sideband runs.
- Before any store: `validate_project_context` runs the same checks on a
  draft and stores nothing (no sudo). Fix every `fail` in `warnings`. If the
  team reviews the draft, show it after that, and validate any change the
  review makes. Then store once.
- Events go in the code after the context is stored: `implement_events_prompt`.
  It commits the reviewed map with `docs/SIDEBAND_EVENTS.md`; keep both
  current when an event changes.
- Events added, changed or removed later: `change_events_prompt`. It
  also covers the pulses that depend on a changed event.
- Row status: write `proposed` or `implemented` only, and keep the
  stored `verified` rows. After events arrive, `verify_project_events`
  with their names writes `verified`.

Keep it current:

1. `list_project_context_questions`. Answer each question from the code,
   citing file and line. For an open item about runtime, exercise the
   flow and read what arrived; `submit_project_context_answers` says
   what to put in `evidence`.
2. `submit_project_context_answers` records the answers. It stores a new
   version only when they change the document.
3. A correction no question covers: `get_project_context`, edit that body,
   validate it with `validate_project_context`, fix every `fail`, and store
   it with `update_project_context`. It replaces the whole body.

Prefer events from `list_observed_events` over events you inferred.
An event the app never sends is worse than one you left out.
