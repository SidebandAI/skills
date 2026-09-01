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

You can get a starting skeleton from `generate_pulse` (pass a plain-language `goal`), then
refine it against these guidelines. Use `create_pulse_draft` to validate and preview the
result without saving it. The tool returns an `authoring_pulse` payload, generated defaults,
and graph warnings. Apply revisions by calling `create_pulse_draft` again. Targeting may be
omitted while previewing, but it must be present before passing the returned fields to
`create_pulse`.

## Pulse arguments

Required for create: `project_id`, `name`, `sentiment_sheet_eyebrow`, `questions`,
`targeting_rulesets`.

- `name` — identifies the pulse in Sideband.
- `sentiment_sheet_eyebrow` — copy shown above the sentiment question in the sheet.
- `learning_objective` — what decision or uncertainty this pulse should answer, in the
  author's own words (up to 2,000 characters). Optional to save, but **ask for it every
  time.** It is what review reads to judge whether the questions actually answer the thing
  you set out to learn; without it, a review can only check the questions against each
  other. It is also the only record of *why* a pulse was written — that intent cannot be
  reconstructed later from the questions, so a pulse saved without one loses it
  permanently. Write the user's actual goal, not a restatement of the first question.

- `questions` — array. Each question:
  - `type`: `"yes_no"`, `"multiple_choice"`, or `"free_text"`
  - `prompt`: the question text (required)
  - `choices`: array of `{ "label": "...", "value": "..." }` (for choice questions)
  - `required`: boolean
  - `free_text_placeholder`: hint text for free-text questions
  - `branching` (optional): `{ "default_next_node_id": "...", "rules": [{ "choice_id"|"value", "next_node_id" }] }`
- `completions` (optional) — end screens: `{ "title", "body", "actions": [...] }`.
- `base_locale`, `expires_at`, `max_responses`, `redisplay_cooldown_days` (optional).
- `appearance` — `sheet` (default) or `fab`. See below before choosing `fab`.

### Choosing `fab` appearance

`appearance` is `sheet` unless you set it. **Choosing `fab` makes `fab_config_id` and
`fab_title` required** — both, together. Omitting either is a validation error on
`create_pulse`, not a field that falls back to a default, so decide the appearance before
you assemble the create call rather than after.

- `fab_config_id` must be an existing config: call `list_fab_configs` **first** and use one
  of the returned ids. A project may have none, in which case either create one with
  `create_fab_config` or stay with `sheet` — do not invent an id. Creating one is not a
  quick fallback: `create_fab_config` requires a `logoKey`, so a project without a
  configured logo cannot get a FAB in passing. Prefer `sheet` unless the user specifically
  wants a FAB.
- `fab_title` is the label shown in the FAB, up to 120 characters.

If the user has not asked for a FAB, leave `appearance` alone and none of this applies.

Status defaults to `draft`. Publish by calling `update_pulse` with `status: "active"`.

## Updating a saved pulse

`update_pulse` uses patch semantics for scalar fields, but `questions`, `completions`, and
`targeting_rulesets` are **complete replacements whenever present**. Before changing one of
these collections, call `get_pulse`, preserve every item that should remain, apply the edit,
and submit the entire resulting collection. Omit a collection when it is not changing.

Question replacements require every question's stable `id`. For `yes_no` and
`multiple_choice` questions, every choice must include its existing `id`, `label`, and
`value`; preserve those identities and assign explicit identities to new items. Sending
only the edited question removes the others, while omitting required identities makes the
update invalid.

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
  - `event` — `event_name`, `operator`, required `window`, optional `count` and
    `metadata_filters`
  - `event_set` — `event_names`, `operator`, required `window`, optional `count` and
    `metadata_filters`. Any-of (`occurred`, count summed across the set) or none-of
    (`not_occurred`). Prefer this over one `event` condition per name.
  - `event_sequence` — `event_names`, `ordered`, required time `window`. No metadata
    filters yet.
- **Operators, and where each one applies.** `event` and `event_set` conditions take only
  `occurred` and `not_occurred`; a comparison operator on one of those is rejected.
  `not_occurred` is how you express absence ("hasn't done X"). Attribute conditions take
  `eq` and `neq`, and `first_seen_days_ago` additionally takes `gt`, `gte`, `lt`, `lte`.
  Metadata filters take `eq` / `neq` on the string keys and all six on the numeric keys.
- **Two different things are called `count`.** The `count` on an `event` / `event_set`
  condition is *how many times the event occurred*; the `count` **metadata key** is *a
  number the event itself carries*. They behave differently:
  - The metadata key is a normal numeric comparison — `eq` included — so "the rating count
    was exactly 3" is expressible as a metadata filter.
  - The occurrence count takes no comparison operator, only a threshold: `occurred` with
    `count: 3` means the event happened **at least** three times. "Exactly three times" is
    not expressible, and that is deliberate — an exact occurrence count stops matching the
    moment the person does it once more.
- **`not_occurred` includes the events arriving right now.** The count spans both stored
  history and the batch that triggered this evaluation, and `not_occurred` requires zero.
  So a condition saying "has not done X" is false when X is in the same batch as the
  trigger — which makes "hasn't done X lately" fail if X could plausibly accompany the
  trigger. Anchor such a condition on a window that ends before the trigger, or target a
  different moment.
- `metadata_filters` on `event` / `event_set` conditions — only occurrences whose metadata
  matches every filter count toward the condition. Filters may reference only the six
  targetable keys: `source`, `item_type`, `mode`, `variant` (compared as lowercase
  strings, `eq`/`neq`) and `count`, `duration` (compared as numbers, all six operators).
  A filter requires the key to be present, `neq` included. Check the key actually
  arrives on the event with `list_observed_events` (its `metadata_keys`, per platform and
  overall) before targeting on it. `list_observed_events` reports which **keys** arrive, not
  which values; to see the values a key actually carries, call `list_events` with that
  `event_name` and read `metadata` on the returned events. Do that before writing any
  `eq`/`neq` filter — a filter on a value the app never sends matches nothing, and nothing
  warns you. Note the
  difference from trigger filters: an `event` condition on the trigger's own name with
  `source eq search` is also satisfied by a matching occurrence earlier in its window.
- `window` — required on `event`, `event_set`, and `event_sequence` conditions. A time
  window is `{ "type": "time", "count": 7, "unit": "day" }`. An event-relative window
  is `{ "type": "event_relative", "event_name": "anchor_event", "count": 7,
  "unit": "day" }`; `event_name` is the required anchor. Units are `second`, `minute`,
  `day`, `week`, or `month`. Always provide the intended window explicitly.

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

## Answer order and the escape hatch

`shuffle_choices` **defaults to true**: multiple-choice answers are served in a per-user
random order, so the order you author is not the order respondents see. `yes_no` questions
never shuffle.

That matters for the escape-hatch choice this guide recommends ("None of these" / "Prefer
not to say"). A catch-all only reads as one if it stays last — shuffled into the middle of
the list it looks like a real option. Give that choice the reserved id **`system_other`**,
which marks it as an Other-style catch-all and implicitly pins it to its authored position;
any other choice you want to hold in place takes `pinned: true`. Set `shuffle_choices:
false` only when the authored order carries meaning everywhere in the pulse (a scale, for
instance).

## Delivery limits and the project cooldown

Two different mechanisms decide whether someone sees a pulse, and confusing them is the
most common reason a pulse "doesn't show up":

- **The project cooldown** (`pulse_cooldown_days` on the project) is **project-wide**: once
  a person has been shown *any* pulse in that project, **no** pulse in that project is
  shown to them again until the cooldown expires. It is keyed to the person, not the
  device — for a user identified with `tagUser`, reinstalling the app or switching devices
  does **not** reset it.
- **Per-pulse redisplay** (`redisplay_cooldown_days`) governs how often that one pulse
  reappears for someone who has already seen it. **Omitting it means the pulse is shown at
  most once, ever** — any past presentation blocks it permanently. Note the two limits
  default in opposite directions: omitting `redisplay_cooldown_days` is the most
  restrictive setting, while omitting `max_responses` means no cap at all.

Read the current value with `get_project`; `pulse_cooldown_days: null` means the project
cooldown is disabled.

**Testing a pulse more than once.** Because the cooldown is project-wide and follows the
identified user, a tester who has already seen one pulse will not see the next one. In
order of preference:

1. **Use a different test account per run.** No settings change and no risk — this is the
   right default.
2. **Test on a separate development project that real users never reach**, and disable the
   cooldown there.

`pulse_cooldown_days` is changed with `update_project`, which is a mutation — see the
write-access step. Before changing it: read and report the current value, confirm with the
user that the project is not one real users receive pulses on, and tell them how to put it
back. **Never leave the cooldown disabled on a project serving real users** — every pulse
becomes eligible for the same person every time.

## Looking at results

- `get_pulse_metrics` — aggregate completion/response counts for a pulse.
- `list_responses` — individual responses (filter by sentiment, completion, time).
- `list_events` / `list_observed_events` — what the app is actually sending: names with
  exact counts, per-platform breakdown, observed metadata keys and first/last seen. Useful
  for sanity-checking trigger events and their keys before you target them, and for
  checking what landed after an instrumentation change. `system_*` events are summarized
  in `meta.system_names` unless you pass `include_system: true`.
