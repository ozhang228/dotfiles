#!/usr/bin/env bash
#
# Claude Code PreToolUse adapter.
#
# Reads Claude Code's hook JSON on stdin, dispatches on tool_name, calls the
# vendor-neutral core, and emits additionalContext JSON for Claude Code.
#
# Wired in ~/.claude/settings.json under hooks.PreToolUse for
# Write|Edit|NotebookEdit|Bash.
set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$HOOKS_DIR/inject_rules.py"

input_json="$(cat)"
tool_name="$(printf '%s' "$input_json" | jq -r '.tool_name // empty')"

case "$tool_name" in
    Write|Edit|NotebookEdit)
        file_path="$(
            printf '%s' "$input_json" \
            | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty'
        )"
        if [[ -z "$file_path" ]]; then exit 0; fi
        rules="$("$CORE" --file "$file_path")"
        ;;
    Bash)
        command="$(printf '%s' "$input_json" | jq -r '.tool_input.command // empty')"
        if [[ -z "$command" ]]; then exit 0; fi
        rules="$("$CORE" --bash "$command")"
        ;;
    *)
        exit 0
        ;;
esac

if [[ -z "$rules" ]]; then exit 0; fi

jq -n --arg ctx "$rules" '{
    hookSpecificOutput: {
        hookEventName: "PreToolUse",
        additionalContext: $ctx
    }
}'
