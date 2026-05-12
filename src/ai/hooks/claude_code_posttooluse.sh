#!/usr/bin/env bash
#
# Claude Code PostToolUse adapter.
#
# Fires after Write and Edit tool calls. Runs the appropriate formatter
# (and linter where applicable) for the file type, then returns any lint
# diagnostics as additionalContext so Claude can fix them immediately.
set -euo pipefail

input_json="$(cat)"
file="$(printf '%s' "$input_json" | jq -r '.tool_input.file_path // empty')"

if [[ -z "$file" || ! -f "$file" ]]; then exit 0; fi

ext="${file##*.}"
lint_out=""

# Format using prettierd, falling back to prettier. Only replaces the file
# if the formatter produces non-empty output — avoids wiping files on error.
_prettier_inplace() {
  local f="$1"
  local tmp
  tmp=$(mktemp)
  if prettierd "$f" > "$tmp" 2>/dev/null && [[ -s "$tmp" ]]; then
    cat "$tmp" > "$f"
  else
    prettier --write "$f" 2>/dev/null || true
  fi
  rm -f "$tmp"
}

case "$ext" in
  py)
    ruff check --fix --quiet "$file" 2>/dev/null || true
    ruff format --quiet "$file" 2>/dev/null || true
    lint_out="$(ruff check "$file" 2>&1 || true)"
    ;;
  ts|tsx|js|jsx)
    _prettier_inplace "$file"
    eslint_d --fix "$file" 2>/dev/null || true
    lint_out="$(eslint_d "$file" 2>&1 || true)"
    ;;
  lua)
    stylua "$file" 2>/dev/null || true
    ;;
  json|html|css)
    _prettier_inplace "$file"
    ;;
  toml)
    taplo format "$file" 2>/dev/null || true
    ;;
  cpp|cc|cxx|c|h|hpp|hxx)
    clang-format -i "$file" 2>/dev/null || true
    ;;
esac

if [[ -n "$lint_out" ]]; then
  jq -n --arg ctx "Lint output for $file:\n$lint_out" '{
      hookSpecificOutput: {
          hookEventName: "PostToolUse",
          additionalContext: $ctx
      }
  }'
fi
