# Authoring pulses

A pulse is a short in-app survey. Good pulses are short, have one clear objective, and
ask non-leading questions. Draft first, review with the user, publish only on approval.

## What makes a good pulse

- **One objective.** Decide the single thing you want to learn before writing questions.
- **Short.** One to three questions. Every extra question costs responses.
- **Non-leading prompts.** Ask "How was checkout?" not "How great was our easy checkout?".
- **Balanced choices.** If you offer positive options, offer equivalent negative ones.
- **An escape hatch.** Include "None of these" / "Prefer not to say" where a forced choice
  would distort answers.
- **A clear finish.** A brief completion message; thank the user.

You can get a starting draft from `generate_pulse` (pass a plain-language `goal`), then
refine it against these guidelines.

## `create_pulse` / `update_pulse` arguments

Required for create: `project_id`, `name`, `sentiment_sheet_eyebrow`, `questions`,
`targeting_rulesets`.

- `name` — identifies the pulse in Sideband.
- `sentiment_sheet_eyebrow` — copy shown above the sentiment question in the sheet.

- `questions` — array. Each question:
  - `type`: `"yes_no"`, `"multiple_choice"`, or `"free_text"`
  - `prompt`: the question text (required)
  - `choices`: array of `{ "label": "...", "value": "..." }` (for choice questions)
  - `required`: boolean
  - `free_text_placeholder`: hint text for free-text questions
  - `branching` (optional): `{ "default_next_node_id": "...", "rules": [{ "choice_id"|"value", "next_node_id" }] }`
- `completions` (optional) — end screens: `{ "title", "body", "actions": [...] }`.
- `base_locale`, `fab_config_id`, `fab_title`, `expires_at`, `max_responses` (optional).

Status defaults to `draft`. Publish by calling `update_pulse` with `status: "active"`.

## Targeting — who sees the pulse, and when

Targeting is **part of the pulse**, not a separate resource: the `targeting_rulesets`
argument on `create_pulse` / `update_pulse`. It is required on create.

`targeting_rulesets` is an array (at least one ruleset). A ruleset is:

- `trigger_events` — array of event names, at least one. Any of them makes the pulse
  eligible. Cross-check the names against `list_observed_events` first; a trigger on an
  event the app never sends silently never fires. Its counts are exact as of the call — an
  event that arrived minutes ago already shows.
- `trigger_metadata_filters` — optional array of `{key, operator, value}` the **activating
  event itself** must carry (all AND-ed). This is "fire on this `detail_view_abandoned`
  only when it arrives with `source=search`" — checked on the arriving event, never on
  history. It is the right tool whenever the pulse is *about* the event that just happened.
- `conditions` — optional array, evaluated in order. Each condition needs a `kind`:
  - `attribute` — `field`, `operator`, `value`. Allowed fields: `platform`, `locale`,
    `app_version`, `first_seen_days_ago`. (There is no "days since last seen" /
    dormancy field, and no session counter.)
  - `event` — `event_name`, `operator`, optional `count`, `window`, `metadata_filters`
  - `event_set` — `event_names`, `operator`, optional `count`, `window`,
    `metadata_filters`. Any-of (`occurred`, count summed across the set) or none-of
    (`not_occurred`). Prefer this over one `event` condition per name.
  - `event_sequence` — `event_names`, `ordered`, required time `window`. No metadata
    filters yet.
- Operators: `eq`, `neq`, `gt`, `gte`, `lt`, `lte`, `occurred`, `not_occurred`.
  `not_occurred` is how you express absence ("hasn't done X").
- `metadata_filters` on `event` / `event_set` conditions — only occurrences whose metadata
  matches every filter count toward the condition. Filters may reference only the six
  targetable keys: `source`, `item_type`, `mode`, `variant` (compared as lowercase
  strings, `eq`/`neq`) and `count`, `duration` (compared as numbers, all six operators).
  A filter requires the key to be present, `neq` included. Check the key actually
  arrives on the event with `list_observed_events` (its `metadata_keys`, per platform and
  overall) before targeting on it. Note the
  difference from trigger filters: an `event` condition on the trigger's own name with
  `source eq search` is also satisfied by a matching occurrence earlier in its window.
- `window` — `{type: "time"|"event_relative", count, unit}` where unit is `second`,
  `minute`, `day`, `week`, or `month`. **An `event` condition with no `window` defaults to
  the last 7 days**, silently. If you mean "ever", say so with an explicit long window.

Two things about how conditions combine, both easy to get wrong:

- Each condition after the first carries a `connector` of `"and"` (default) or `"or"`, and
  they **fold strictly left to right with no grouping or precedence**. `A or B and C`
  evaluates as `(A or B) and C`, not `A or (B and C)`. There are no parentheses. If an
  objective needs real grouping, use multiple rulesets instead — a pulse is eligible if
  **any** of its rulesets matches, which is how you get an "or" across groups.
- There is no "any of these attributes" primitive; express that as separate rulesets.
  "Any of these events" / "none of these events" is the `event_set` kind above.

Keep targeting as narrow as the objective requires; overly broad targeting dilutes results,
overly narrow starves the pulse of responses.

## Looking at results

- `get_pulse_metrics` — aggregate completion/response counts for a pulse.
- `list_responses` — individual responses (filter by sentiment, completion, time).
- `list_events` / `list_observed_events` — what the app is actually sending: names with
  exact counts, per-platform breakdown, observed metadata keys and first/last seen. Useful
  for sanity-checking trigger events and their keys before you target them, and for
  checking what landed after an instrumentation change. `system_*` events are summarized
  in `meta.system_names` unless you pass `include_system: true`.
