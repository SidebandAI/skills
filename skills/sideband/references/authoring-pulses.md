# Authoring pulses

Draft first. Review with the user. Publish only on explicit approval.

## Create

Required to publish: `channel_id`, `name` (console identifier, not user-facing copy),
`sentiment_sheet_eyebrow` (user-visible copy above the sentiment question),
`questions`, `targeting_rulesets`.

Ask for `learning_objective` every time (max 2,000 characters). Review uses it
to judge whether the questions answer the goal. Optional to save; if they
decline, omit it. If saving, use the user's goal, not a restatement of the
first question.

### Test pulse and first real pulse

A new integration needs two different pulses. Say which one you are drafting.

- **Test pulse:** a moment a tester can trigger by hand, with a simple question.
  It proves that the integration delivers a pulse and records an answer. It
  is not a model for later pulses. Copying it to Production is the user's
  choice, not the default next step.
- **First real pulse:** starts from what the team wants to learn (a decision,
  a gap in what they know about their users, something they are about to
  build). Ask them first. If they have no question yet, propose one or two:
  for each, the moment, who to target and why those users can answer, and what
  the team would do with each likely answer. Draft only what they choose.

`create_pulse_draft` saves a draft and needs write access. Only `channel_id` is
required; it returns `id`, `version`, generated defaults, graph warnings and
delivery warnings, or
`validation_errors` for content that cannot be built yet. Show those. The draft
delivers nothing until `publish_pulse`. Targeting may be omitted in a draft; it
is required to publish.

Its `readiness`, which `update_pulse` also returns for the draft it saves,
checks only the events the draft names (trigger events,
condition `event_name` / `event_names`, the anchor of an `event_relative`
window) and the metadata keys it filters them on, against the stored context:
a row exists, its firing moment is not `unknown`, it declares every platform a
ruleset that restricts platforms can target it on (a ruleset where all three
platforms are possible adds no platform check), and it lists the filtered
keys. The draft is saved whatever it says. Status `unavailable` means the
check could not run (the database was unavailable): it reports no gaps, and the next
`update_pulse` on the draft checks it again. For each gap, the app's
coding agent inspects the app's code for that event. If the row is wrong, it
updates that row (keeping unrelated content and recorded uncertainty) and
stores the whole document with `update_channel_context` and the given
`context_version`. If the row is right, the draft is wrong (for example it
targets a platform where the event does not fire, or filters on a key it does
not carry): no context write; fix the draft. Either way, the draft continues
with `update_pulse`. `format_migration_required` gives a `migration`
instruction instead. Catalog evidence is not proof of the code, and `ready`
does not judge the facts in `not_judged` (feature meaning, audience intent,
delivery surface, identity). Change the context only for the gaps it names.
Do not estimate reach from catalog counts: they show that events arrive, not
how many people a pulse will reach.

`publish_pulse` takes the exact saved `expected_version` and an `intent`:
`activate` (now; no start time), `schedule` (future `starts_at`), `inactive`
(published, not delivering; no start or end time), `preserve` (keep the current
delivery state) or `pause`. Call it only after the user explicitly says publish.

Optional: `base_locale`, `expires_at`, `max_responses`, `redisplay_cooldown_days`.
`completions`: `[{ "title", "body", "actions": [...] }]` (array; omit the field
for the default thank-you; `[]` for no thank-you screen, only when the user asks
for none). Each action needs `label` and `action.type`:
`dismiss` or `app_rating`. `app_rating` opens the store rating prompt. At
least one action on a custom completion.

## Review

`validate_pulse` reviews the saved working draft without changing or publishing it.
It requires the existing `mcp_il_tools` and `intelligence_layer` access gates.
Each `validate_pulse` and `monitor_pulse` call is a model-backed run that counts toward
hourly budgets for the channel, for the user and for all of Sideband. Over a budget the
call returns `rate_limited` with `retry_after_seconds` and `limit_scope` (`channel`,
`user` or `deployment`), and nothing runs.
The channel's `pulse_editor_v2` flag selects the new review workflow when enabled
and the legacy review when disabled or absent. Both return the same checklist result
format. This flag does not block draft creation, updates, or publication through MCP.

## Questions

### Entry

The first thing the respondent sees is **one of**:

1. **Sentiment sheet** — `appearance` sheet (default). Root question `type:
   yes_no`. Omit `choices`; the server fills thumbs. `sentiment_sheet_eyebrow`
   sits above it.
2. **FAB** — `appearance: fab` plus `fab_config_id` and `fab_title`. After tap,
   the survey still starts on that `yes_no` root.
3. **Snackbar** — `appearance: snackbar` plus `fab_config_id` (the same images
   as a FAB). The server sets `entry_settings.kind: snackbar`; `entry_settings`
   can also set `position`, `anchor` and `offset`. The survey starts on that
   `yes_no` root. An app on an SDK older than 1.4.0 never shows a snackbar
   pulse; Sideband does not send it there.

Never a `multiple_choice` or `free_text` root. If a FAB config exists, ask
sheet vs FAB vs snackbar; all are valid.

**Toolbar** (`appearance: "toolbar"`): a full-width bar pinned to the page edge.
It needs no `fab_config_id`; the server sets `entry_settings.kind: toolbar`.
- Only the web SDK 1.4.3 and later shows a toolbar pulse. Sideband never sends
  it to the iOS or Android SDK or to an older web SDK, so those users never see
  the pulse.
- The root must be a `yes_no` question. With any other root, the web SDK shows a
  sheet.
- With a `yes_no` root, the toolbar shows only that question. The answer
  completes the pulse, and the web SDK never shows the questions after it. Use
  one `yes_no` question.

The pulse tools return a `delivery_warnings` entry for each of these points
(`toolbar_web_only`, `toolbar_first_question_not_yes_no`,
`toolbar_follow_ups_not_shown`), beside the routing `warnings`. Other codes can
occur; each entry's `message` says what it means. They never block publish;
tell the user what each one means before publishing.

`debug_evaluate` and preview payloads include
`pending_pulse.sentimentPresentation: "toolbar"` for a toolbar pulse.
`debug_evaluate` does not check the SDK platform or version.

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

If the pulse has a thank-you screen, every path ends on it. Route the last
question on each path, for every answer, to the completion's `node_id` (the
default one is `draft_completion` unless a question already uses that id; the
`create_pulse_draft` result shows it). An answer with no route closes the sheet
without a thank-you screen. A rule for one answer does not route the others:
set `default_next_node_id` too. An optional question can be submitted with no
answer, which follows `default_next_node_id`. `create_pulse_draft` connects a
question that has no route at all to the completion. The
`paths_without_completion` warning from `create_pulse_draft`, `update_pulse` and
`preview_pulse` names each answer that has no route. Fix them before publish.

Leave the thank-you screen out only when the user asks: `completions: []`. The
sheet then closes after the last answer. To remove it from a draft, send
`completions: []` and the questions without routes to it in the same
`update_pulse` call; a route to a removed screen makes preview and publish fail.

Follow-ups go on the unhappy path (`thumbs_down` / `no`) — short
`multiple_choice` plus optional `system_other`. Each path the respondent sees
is 1–3 questions. Extra nodes are fine on other branches.

A single unbranched multiple-choice is an opinion poll. Do not publish that
shape.

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

`list_fab_configs` first. If one exists, FAB and snackbar are valid entries
(ask sheet vs FAB vs snackbar).

`fab` requires both `fab_config_id` and `fab_title` (user-visible FAB label,
short, max 120). Omitting either fails publication. Do not invent an id.
`create_fab_config` needs a `logoKey` — no logo, no FAB. After tap, still start
on the `yes_no` root.

## Update

Draft status reports `get_pulse.shows: draft` and `published: false` (`draft.published` in `get_pulse`).

`update_pulse` changes the saved draft, never the delivered pulse. Pass
`expected_version` from `get_pulse.data.draft.version`, or `data.version` from
the latest draft write result. `schema_version` identifies the pulse payload
format, not an edit revision. A stale draft version returns `conflict`.
Omitted fields stay as they are. `questions`, `completions`
and `translations` each replace the whole array: send every item, not only the
edited one.

Retain existing IDs. Every question needs its `id`. Every `yes_no` /
`multiple_choice` choice needs its existing `id`, `label`, and `value`. New
questions and choices need explicit ids too. Omitting required identities
makes the update invalid. Sending only the edited question deletes the others.

Publishing changed content of a published pulse creates a replacement pulse id
and archives the old one. Follow the returned id. A superseded id returns
`conflict` with `replacement_pulse_id`.

A status change is `publish_pulse` with that `intent` (`pause`, `activate`). It
also publishes any saved edits: check `draft.has_unpublished_changes` in
`get_pulse` (top level in `list_pulses`) first, and `reset_pulse_draft` to discard edits the user does not want live.

## Targeting

Required to publish. Argument on `create_pulse_draft` / `update_pulse`, not a
separate resource. Array of rulesets; at least one. Eligible if **any** ruleset matches.

A pulse can target only platform, language, app version, days since first
seen, and the events a user sent.

A ruleset:

- `trigger_events` — at least one **user-initiated** event. A direct user
  action (opened create, saved, tapped), or an at-rest arrival that the reviewed
  map defines with its de-duplication rule (a calm moment, not mid-task). Not
  `system_*`, and not app lifecycle or other events with no direct user action,
  and not an event whose context
  row's `notes` start with `history only: not a pulse trigger`. Check names with
  `list_observed_events` first (`system_*` are in `meta.system_names` unless
  `include_system: true` — do not use them as triggers). A trigger the app
  never sends never fires (no error). Counts are exact through `meta.coverage_to`.
  A name with `in_context: false` has no row in the stored context: describe it
  from the code and store the row before you draft on it, or the draft's
  `readiness` reports a gap.
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
platform and overall) — the key must arrive. Then the **values**: the same tool
with `event_names` (at most 10) and `include_values: true` gives each string
key's values with counts from a bounded recent sample (`meta.values` states it;
counts are events, not people; a rare or old value can be missing from it;
`meta.values.status` `deferred` means not read, not no values;
`metadata_values_not_sampled` names observed keys with no values read), or
`list_events` (`event_name`) for single events and those keys. `list_events`
`since` / `until` compare the device timestamp, not the arrival time. A missing key or a value the app never sends
matches nothing, with no warning.

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

- **Channel cooldown** (`pulse_cooldown_days`): after any pulse is shown to a
  person, no pulse in that channel is shown again until that cooldown elapses.
  Keyed to the person the app identifies to Sideband as the signed-in user, not
  the device — reinstall and switching devices do not reset it for that user.
  `get_channel`; `null` means disabled.
- **Per-pulse redisplay** (`redisplay_cooldown_days`): how often that pulse can
  show again. On create, omit = shown at most once, ever; omit `max_responses` =
  no cap. On `update_pulse`, omit it to keep the current value; send `null`
  only when intentionally clearing it.
- **Delivery language**: a pulse shows only when the language that the SDK
  sends matches the pulse's language or one of its published translations. A
  person with no match gets no pulse, also when the pulse has no language rule.
  By default the SDK sends the device's language; the SDK README for the
  platform says whether and how the app can send a different one.

Test in the Development channel, with a build that uses its key. A different
account in the Production channel does not keep the test out of it. Turn off
cooldown only in the Development channel.

`update_channel` is a mutation. Before changing `pulse_cooldown_days`: read and
report the current value, make sure the channel is not serving real users, say
how to put it back. Never leave cooldown disabled on a channel serving real users.

### Test a new pulse

A published pulse is not done until someone sees it in a build. In the
Development channel, after the user says publish:

1. Use a build with the Development channel's key and a user who has not seen
   this pulse (a pulse shows at most once per user unless its redisplay allows more).
   Two limits block a user who saw a pulse: the channel cooldown after any
   pulse, and this pulse's redisplay. A lower channel cooldown alone does not
   show a show-once pulse again to the same user. For each repeat test, prefer
   a fresh eligible user.
2. Do something that should not show it (another action, or a user outside its
   targeting): nothing appears.
3. Do the trigger action: the pulse appears after the app's next sync, usually
   a few seconds later, because the server sets a minimum wait between syncs.
   Note when the trigger happened and when the pulse appeared, and report that
   delay. Answer it with a known answer. When the app's language and the
   device's language can differ, also test the team's language choice with a
   second eligible user who has not seen this pulse, on a device set to a
   language that does not match. Record the language that the build sends in
   each test. If it sends the app's language, the pulse shows. If it sends the
   device's language and the pulse has no matching translation, no pulse shows,
   and that is the expected result. When the trigger can fire with a host dialog
   open, test with the dialog open, with mouse and with keyboard. Report each
   input mode you did not test as not tested.
4. Read the answer back with `list_responses`, and the delivery with
   `get_pulse_delivery`. Do the trigger action again with the same user: nothing
   appears.
5. Restore any test setting you changed (cooldown), or pause the pulse, as
   agreed with the user.

If you cannot run the app, give the user these steps and report the pulse as
not tested until the answer is read back.

For the release, create the tested real pulse again as a draft in the
Production channel (a test pulse only if the user chooses): same questions,
targeting and learning objective, with that channel's FAB configuration. Do not
copy test settings. Show the draft, and publish it only when the user says
publish.

## Results

- `get_pulse_metrics` — completion/response counts
- `get_pulse_delivery` — delivery health (presentations by the pulse's entry kind,
  FAB drawn vs opened for a FAB pulse, selections never presented, `not_now` vs `never` dismissals) and serve timing (gap from app
  foreground, tenure, gap from each condition event, which trigger fired, seconds
  to answer). Counts and ratios only; read them against what the pulse was meant
  to ask about before calling a moment wrong. A report is cached for up to five
  minutes, and `computed_at` gives its age: activity after the report was built
  can be missing from it until the cache expires. Check answers with
  `list_responses`
- `list_responses` — filter by sentiment, completion, time
- `monitor_pulse` — results with benchmarks, delivery and timing, and a read of the
  newest free-text answers against the learning objective (objective progress,
  takeaways, themes by response id, hero responses). `qualitative_error` names why a
  read is missing; the measurements stand on their own
- `list_events` / `list_observed_events` — names, exact counts, per-platform
  breakdown, metadata keys, first/last seen. `system_*` names are in
  `meta.system_names` unless `include_system: true`. `event_names` reads
  exact names outside the count-ranked shortlist; `include_values: true` with
  them adds targetable string-key values from a bounded sample. Counts are events, not
  people or a pulse's audience
