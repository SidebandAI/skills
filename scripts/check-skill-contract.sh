#!/usr/bin/env bash
set -euo pipefail

skill="skills/sideband/SKILL.md"
authoring="skills/sideband/references/authoring-pulses.md"
connecting="skills/sideband/references/connecting.md"

require_text() {
	local file="$1"
	local text="$2"

	if ! grep -Fq -- "$text" "$file"; then
		printf 'Missing contract guidance in %s: %s\n' "$file" "$text" >&2
		exit 1
	fi
}

reject_text() {
	local file="$1"
	local text="$2"

	if grep -Fq -- "$text" "$file"; then
		printf 'Stale contract guidance in %s: %s\n' "$file" "$text" >&2
		exit 1
	fi
}

require_text "$skill" 'create_pulse_draft'
require_text "$skill" 'request_sudo'
require_text "$connecting" 'Mutation tools appear after temporary write access is approved.'
require_text "$authoring" 'complete replacements whenever present'
require_text "$authoring" 'required `window`'
require_text "$authoring" '"event_name": "anchor_event"'
require_text "$connecting" 'Authorization: Bearer ${SIDEBAND_MCP_TOKEN}'
reject_text "$connecting" 'Authorization: Bearer $SIDEBAND_MCP_TOKEN"'

printf 'Skill contract guidance is present.\n'
