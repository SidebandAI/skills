# Project context

Write from the repo in product language, not types, paths, or SDK calls.
`get_project_context` first; update that body, don't start over.
`update_project_context` (`project_id`, `body`) replaces the stored document.

Prefer events from `list_observed_events` over events you inferred.
An event the app never sends is worse than one you left out.

In Event taxonomy / User flows, lead with event→moment (when a pulse should
fire), then extra detail.

## Outline

1. **App identity** — product, users, core loop, stack, languages
2. **Event taxonomy** — name, user meaning, when it fires, key data
3. **User flows** — ordered steps, branches, events along the way
4. **Date written**
5. **Anything else** that didn't fit
