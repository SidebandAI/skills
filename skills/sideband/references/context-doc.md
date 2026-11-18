# Channel context

Sideband's onboarding documents carry the method. Fetch each with
`get_onboarding_document` and follow it as returned. It takes no
`channel_id`, so read it before a product exists.

A new integration runs `instrumentation_map_prompt` before any change to
how the SDK starts, consent gating, the network allowlist, or the language
that the SDK sends. Its Part E names who decides each of these; a decision
with no known owner goes into the map review, not into the code.

- No context stored yet (`get_channel_context` returns a null body):
  if the app's Production channel already has a context, copy it to
  the Development channel as `change_events_prompt` "Which channel
  holds the context" says. Otherwise run
  `instrumentation_map_prompt` against the repo. It writes
  `sideband_instrumentation_map.md` and a draft context, which the user
  reviews with the map before the one store.
- Events go in the code after the context is stored: `implement_events_prompt`.
  It commits the reviewed map with `docs/SIDEBAND_EVENTS.md`; keep both
  current when an event changes. Every SDK call comes from the SDK's
  README; `implement_events_prompt` links it for each platform.
- Events added, changed or removed later, and a context gap a pulse draft
  reports: `change_events_prompt`.
- `drift` on `get_channel_context` and `get_channel_status`: observed event
  names with no row since the context was stored (`names_without_row`) and
  rows whose firing moment is `unknown` (`rows_unknown`), compared through
  `catalog_through`. Describe each from the code and store the row with
  `change_events_prompt` before you draft a pulse on it.
- A script, a CI pipeline or an agent without the MCP tools that must read,
  check or store the context: `rest_api_guide`. It uses an API client that a
  channel Owner or Admin creates in the console; never a personal MCP token or
  an SDK key. An agent with the MCP tools needs neither the guide nor a client.

## Production and Development channels

Recommend a Development channel for every build that is not a release
(debug, QA, test devices, CI) and a Production channel for release
builds. Each build configuration uses the key of its channel. Build
and test in the Development channel first: store the context there,
implement and check the events, and prove delivery with a test pulse.
Before the release, copy the verified context to the Production channel
(`change_events_prompt`, "Which channel holds the context"). The
context and the pulses for real users belong in the Production channel.
Sideband has no test flag for users, devices or events, and will not add one: the Development channel is the only way to keep test traffic out of the Production channel.
Creating a product with `create_product` creates both channels together. Both start
empty with no API keys. Create a channel's key with `create_channel_api_key` when asked.
Existing standalone workspaces are not converted or linked by these tools.
