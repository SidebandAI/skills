# Writing a project context document

A good context document lets Sideband tailor pulse drafts and review feedback to *this*
app instead of a generic one. Write it from what's actually in the codebase, and re-run
`update_project_context` whenever it drifts.

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

## Lead with the digest

Nothing is trimmed at the door — a full instrumentation map is stored whole, so save what
you produced rather than cutting it down to fit. What matters is the order: the front of
the document is what pulse drafting and review actually read, so open with the
event-to-moment mapping and the parts that help decide when a pulse should fire, and let
the long-form detail follow.

There is a very large upper bound on the stored length, well above any real document. A
save is only refused if you exceed it — that is a sanity limit, not a budget to write to.

## Tips

- Describe behavior in plain product language, not implementation detail.
- Prefer the events the app *actually* sends (cross-check with `list_observed_events`,
  which also shows the metadata keys and platforms each one arrives with) over
  aspirational ones.
- Read the current document first (`get_project_context`) and update it, rather than
  rewriting from scratch.
- Accuracy beats volume: an event you inferred but the app never sends is worse than an
  event you left out.
