# Channel context

Sideband's onboarding documents carry the method. Fetch each with
`get_onboarding_document` and follow it as returned. It takes no
`channel_id`, so read it before a product exists.

- No context stored yet (`get_channel_context` returns a null body):
  if this is the Development channel of an app whose Production
  channel already has a context, copy it as `change_events_prompt`
  "Which channel holds the context" says. Otherwise run
  `instrumentation_map_prompt` against the repo. It writes
  `sideband_instrumentation_map.md` and a draft context, which the user
  reviews with the map before the one store.
- Events go in the code after the context is stored: `implement_events_prompt`.
  It commits the reviewed map with `docs/SIDEBAND_EVENTS.md`; keep both
  current when an event changes. Every SDK call comes from the SDK's
  README; `implement_events_prompt` links it for each platform.
- Events added, changed or removed later, and a context gap a pulse draft
  reports: `change_events_prompt`.

## Production and Development channels

Recommend a Development channel for every build that is not a release
(debug, QA, test devices, CI) and a Production channel for release
builds. Each build configuration uses the key of its channel. The
context and the pulses for real users belong in the Production channel.
Sideband has no test flag for users, devices or events, and will not add one: the Development channel is the only way to keep test traffic out of the Production channel.
Creating a product with `create_product` creates both channels together. Both start
empty with no API keys. Create a channel's key with `create_channel_api_key` when asked.
Existing standalone workspaces are not converted or linked by these tools.
