# Authoring pulses

Draft first. Review with the user. Publish only on explicit approval.

## Create

Required: `project_id`, `name` (console identifier, not user-facing copy),
`sentiment_sheet_eyebrow` (user-visible copy above the sentiment question),
`questions`, `targeting_rulesets`.

Ask for `learning_objective` every time (max 2,000 characters). Review uses it
to judge whether the questions answer the goal. Optional to save; if they
decline, omit it. If saving, use the user's goal, not a restatement of the
first question.

`generate_pulse` (`goal`) returns a template. It creates nothing.
`create_pulse_draft` validates and previews. It saves nothing. It returns
`authoring_pulse`, generated defaults, and graph warnings — show those, then
pass the returned fields to `create_pulse`. Targeting may be omitted while
previewing; it is required on `create_pulse`.

Status defaults to `draft`. Publish with `update_pulse` (`status: "active"`).

Optional: `base_locale`, `expires_at`, `max_responses`, `redisplay_cooldown_days`.
`completions`: `[{ "title", "body", "actions": [...] }]` (array; omit the field
for the default screen).

## Questions

### Entry

The first thing the respondent sees is **one of**:

1. **Sentiment sheet** — `appearance` sheet (default). Root question `type:
   yes_no`. Omit `choices`; the server fills thumbs. `sentiment_sheet_eyebrow`
   sits above it.
2. **FAB** — `appearance: fab` plus `fab_config_id` and `fab_title`. After tap,
   the survey still starts on that `yes_no` root.

Never a `multiple_choice` or `free_text` root. If a FAB config exists, ask
sheet vs FAB; both are valid.

### Copy

A few words. Not a sentence that restates the event.

Reject: `What was the main reason you did not save this countdown?`
Prefer: `What got in the way?`

Same cap on `sentiment_sheet_eyebrow`, every `prompt`, `fab_title`, completion
`title`, and choice labels (`Too many fields`, `Not ready`). Non-leading.
Balanced choices.

### Tree

The root `yes_no` is a **sentiment** split: yes = happy, no = not happy.
Branch from that. Question order is not the route. Set `branching.rules` and
`default_next_node_id`.

Follow-ups go on the unhappy path (`thumbs_down` / `no`) — short
`multiple_choice` plus optional `system_other`. Each path the respondent sees
is 1–3 questions. Extra nodes are fine on other branches.

A single unbranched multiple-choice is an opinion poll. Do not `create_pulse`
that shape.

Each question: `type` (`yes_no` | `multiple_choice` | `free_text`), `prompt`,
optional `choices` (`{ "id", "label", "value" }`), `required`,
`free_text_placeholder`, `branching`
(`{ "default_next_node_id", "rules": [{ "choice_id"|"value", "next_node_id" }] }`).

`shuffle_choices` defaults to true: multiple-choice answers are shown in a
per-user random order, not the order you authored. `yes_no` never shuffles.

If you want a catch-all, on `multiple_choice` only, set at most one choice
`id` to exactly `system_other`. The `label` is whatever the user wants
("Something else…", "Other", or other copy) — the reserved behavior is the
id, not the label. It is still a chip, with a different style. Selecting it
replaces the other choices with a follow-up text field (`answer_key:
system_other` plus the typed `value`). Any other id does not open that field.
It pins to the authored slot — put it last in the array if you want it last.
Do not set `pinned` on it.

Pin any other choice with `pinned: true`.
Set `shuffle_choices: false` only when authored order matters (a scale).

## FAB

`list_fab_configs` first. If one exists, FAB is a valid entry (ask sheet vs FAB).

`fab` requires both `fab_config_id` and `fab_title` (user-visible FAB label,
short, max 120). Omitting either fails `create_pulse`. Do not invent an id.
`create_fab_config` needs a `logoKey` — no logo, no FAB. After tap, still start
on the `yes_no` root.

## Update

Scalars patch. `questions`, `completions`, and `targeting_rulesets` are full
replacements whenever present. Omit a collection that is not changing.

Before editing a collection: `get_pulse`, keep every item that should remain,
submit the whole collection. Every question needs its `id`. Every `yes_no` /
`multiple_choice` choice needs its existing `id`, `label`, and `value`. New
questions and choices need explicit ids too. Omitting required identities
makes the update invalid. Sending only the edited question deletes the others.

## Targeting

Required on create. Argument on `create_pulse` / `update_pulse`, not a separate
resource. Array of rulesets; at least one. Eligible if **any** ruleset matches.

A ruleset:

- `trigger_events` — at least one **user-initiated** event. A direct user
  action (opened create, saved, tapped). Not `system_*`, and not app lifecycle
  or other events with no direct user action. Check names with
  `list_observed_events` first (`system_*` are in `meta.system_names` unless
  `include_system: true` — do not use them as triggers). A trigger the app
  never sends never fires (no error). Counts are exact as of that call.
- `trigger_metadata_filters` — optional `{key, operator, value}` on the
  **activating event** (all AND-ed). Not history.
- `conditions` — optional, evaluated in order. Each needs `kind`:
  - `attribute` — `field`, `operator`, `value`. Fields: `platform`, `locale`,
    `app_version`, `first_seen_days_ago`. No dormancy field. No session counter.
  - `event` — `event_name`, `operator`, required `window`, optional `count`,
    `metadata_filters`
  - `event_set` — `event_names`, `operator`, required `window`, optional `count`,
    `metadata_filters`. `occurred` = any-of (counts summed). `not_occurred` =
    none-of. Prefer this over one `event` condition per name.
  - `event_sequence` — `event_names`, `ordered`, required time `window`. No
    metadata filters.

Operators:

- `event` / `event_set`: `occurred`, `not_occurred` only.
- `attribute`: `eq`, `neq`. `first_seen_days_ago` also `gt`, `gte`, `lt`, `lte`.
- Metadata: `eq` / `neq` on string keys; all six on numeric keys.

Two different `count`s:

- Condition `count` = how many times the event occurred. `occurred` + `count: 3`
  means **at least** three. Exactly N is not expressible.
- Metadata key `count` = a number on the event. `eq` works.

`not_occurred` includes the current batch. "Has not done X" is false if X
arrives with the trigger. Anchor the window so it ends before the trigger, or
target a different moment.

`metadata_filters` on `event` / `event_set`: every filter must match. Allowed
keys only: `source`, `item_type`, `mode`, `variant` (lowercase strings,
`eq`/`neq`) and `count`, `duration` (numbers, all six). The key must be present,
`neq` included.

Before any metadata filter: `list_observed_events` (`metadata_keys`, per
platform and overall) — the key must arrive. Then `list_events` (`event_name`)
for **values**. A missing key or a value the app never sends matches nothing,
with no warning.

An `event` condition on the trigger's own name with e.g. `source eq search` is
also satisfied by a matching occurrence earlier in its window.

`window` is required on `event`, `event_set`, and `event_sequence`.
Time: `{ "type": "time", "count": 7, "unit": "day" }`.
Event-relative: `{ "type": "event_relative", "event_name": "anchor", "count": 7, "unit": "day" }`.
Units: `second`, `minute`, `day`, `week`, `month`. Always set the window.

Each condition after the first has `connector`: `"and"` (default) or `"or"`.
They fold left to right. No parentheses. `A or B and C` is `(A or B) and C`.
For real grouping, use multiple rulesets.
No "any of these attributes" primitive — separate rulesets.

## Delivery

- **Project cooldown** (`pulse_cooldown_days`): after any pulse is shown to a
  person, no pulse in that project is shown again until that cooldown elapses.
  Keyed to the person, not the device — reinstall and switching devices do not
  reset it (`tagUser`). `get_project`; `null` means disabled.
- **Per-pulse redisplay** (`redisplay_cooldown_days`): how often that pulse can
  show again. On create, omit = shown at most once, ever; omit `max_responses` =
  no cap. On `update_pulse`, omit leaves the existing value; send `null` to clear.

Test on a different account. Or use a separate project real users never see, and
disable cooldown there.

`update_project` is a mutation. Before changing `pulse_cooldown_days`: read and
report the current value, confirm the project is not serving real users, say how
to put it back. Never leave cooldown disabled on a live project.

## Results

- `get_pulse_metrics` — completion/response counts
- `list_responses` — filter by sentiment, completion, time
- `list_events` / `list_observed_events` — names, exact counts, per-platform
  breakdown, metadata keys, first/last seen. `system_*` names are in
  `meta.system_names` unless `include_system: true`
