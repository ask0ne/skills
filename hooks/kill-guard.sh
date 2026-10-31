#!/usr/bin/env bash
# Event: PreToolUse (matcher: Bash)
# Denies pkill/killall: pattern kills match unrelated processes (a substring like "cat"
# once closed an unrelated desktop app). Tells Claude to find exact PIDs and kill those.
# Requires: jq, grep
cmd=$(jq -r '.tool_input.command // ""')
if printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:](])(pkill|killall)([[:space:]]|$)'; then
  jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",
    permissionDecisionReason:"No pkill/killall: patterns match unrelated apps (pkill -f cat closed an unrelated app). Find exact PIDs with `pgrep -fl <pattern>`, read the list, then `kill <pid>`. For a background task you started, use TaskStop."}}'
fi
exit 0
