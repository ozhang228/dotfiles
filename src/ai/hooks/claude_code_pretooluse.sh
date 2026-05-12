#!/usr/bin/env bash
#
# Claude Code PreToolUse adapter.
#
# Fires on Write and Edit tool calls. Extracts the target file path from
# the tool input, calls inject_rules.py --file to find matching language/skill
# rules, and emits additionalContext JSON for Claude Code.
set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$HOOKS_DIR/inject_rules.py"

input_json="$(cat)"
file="$(printf '%s' "$input_json" | jq -r '.tool_input.file_path // empty')"

if [[ -z "$file" ]]; then exit 0; fi

rules="$("$CORE" --file "$file")"

if [[ -z "$rules" ]]; then exit 0; fi

jq -n --arg ctx "$rules" '{
    hookSpecificOutput: {
        hookEventName: "PreToolUse",
        additionalContext: $ctx
    }
}'
