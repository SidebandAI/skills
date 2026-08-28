# Writing a project context document

A good context document lets Sideband tailor pulse drafts and review feedback to *this*
app instead of a generic one. Write it from what's actually in the codebase, keep it
concise, and re-run `update_project_context` whenever it drifts.

Store it with `update_project_context` (`project_id`, `body`). Each call replaces the
project's stored context, so re-run it whenever the document drifts.

## Recommended outline

1. **App identity** — what the product does, who its users are, the core value loop, the
   relevant stack, and supported languages.
2. **Event taxonomy** — for each event the app sends to Sideband: the event name, what it
   means in user terms, when it fires, and any key data it carries.
3. **User flows** — the main journeys as ordered steps, noting branch points and which
   events fire along the way.
4. **Update marker** — the date you wrote this, so it's clear how current the context is.
5. **Anything notable** — important context that didn't fit the sections above.

## Keep it a digest, not a report

Write this document on purpose rather than pasting in a generated product map — a long
dump buries the part that does the work. Prioritise the event-to-moment mapping over
prose, and cut anything that doesn't help decide when a pulse should fire.

There is an upper bound on the stored length, and an over-long document is rejected
rather than truncated. If a save is refused for length, trim and save again.

## Tips

- Describe behavior in plain product language, not implementation detail.
- Prefer the events the app *actually* sends (cross-check with `list_observed_events`,
  which also shows the metadata keys and platforms each one arrives with) over
  aspirational ones.
- Read the current document first (`get_project_context`) and update it, rather than
  rewriting from scratch.
- Keep it focused — a few hundred words of accurate context beats an exhaustive dump.
