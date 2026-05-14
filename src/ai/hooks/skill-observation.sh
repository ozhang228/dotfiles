#!/usr/bin/env bash
# Stop hook: prompt Claude to save skill observations when code work happened.
# Fires when uncommitted code changes exist — same signal as self-reinforcement.
set -euo pipefail

INPUT=$(cat)
ACTIVE=$(echo "$INPUT"     | jq -r '.stop_hook_active // false')
MODE=$(echo "$INPUT"       | jq -r '.permission_mode // empty')
LOOP_COUNT=$(echo "$INPUT" | jq -r '.loop_count // 1')

[ "$ACTIVE" = "true" ]              && echo '{"decision": "approve"}' && exit 0
[ "$LOOP_COUNT" -gt 1 ] 2>/dev/null && echo '{"decision": "approve"}' && exit 0
[ "$MODE" = "plan" ]                && echo '{"decision": "approve"}' && exit 0

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
[ -z "$REPO_ROOT" ] && echo '{"decision": "approve"}' && exit 0

# Only fire when there is uncommitted work — proxy for a meaningful session
CODE_CHANGED=$(git diff --name-only HEAD 2>/dev/null | head -1)
STAGED_CODE=$(git diff --cached --name-only 2>/dev/null | head -1)
[ -z "$CODE_CHANGED" ] && [ -z "$STAGED_CODE" ] && echo '{"decision": "approve"}' && exit 0

jq -n '{"decision": "block", "reason": "SKILL-OBSERVATION CHECK: Did you notice any skill misfires, false positives, gaps, or improvement opportunities this session (e.g. a skill fired on wrong trigger, failed to fire, produced output you rewrote, or a recurring task with no skill)? If YES: save them as skill-observation memory entries now. If NO: briefly confirm so this does not re-fire."}'
