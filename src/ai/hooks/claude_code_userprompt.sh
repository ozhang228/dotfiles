#!/usr/bin/env bash
#
# Claude Code UserPromptSubmit adapter.
#
# Reads Claude Code's hook JSON on stdin, extracts the user's prompt text,
# calls inject_rules.py --prompt to find relevant language/skill rules based
# on file references and CLI tool mentions in the message, and emits
# additionalContext JSON for Claude Code.
#
# Wired in ~/.claude/settings.json under hooks.UserPromptSubmit.
set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$HOOKS_DIR/inject_rules.py"

input_json="$(cat)"
prompt="$(printf '%s' "$input_json" | jq -r '.prompt // empty')"

if [[ -z "$prompt" ]]; then exit 0; fi

rules="$("$CORE" --prompt "$prompt")"

if [[ -z "$rules" ]]; then exit 0; fi

jq -n --arg ctx "$rules" '{
    hookSpecificOutput: {
        hookEventName: "UserPromptSubmit",
        additionalContext: $ctx
    }
}'
