#!/usr/bin/env bash
# Event: PreToolUse (matcher: Bash)
# Blocks `git push` if `npm run build` fails in the target repo. Handles `git -C <dir> push`.
# Skips repos with no package.json or no "build" script.
# Requires: jq, git, npm
# Single check (npm run build), no other package managers; add when needed.
input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // ""')
cwd=$(echo "$input" | jq -r '.cwd // "."')

echo "$command" | grep -qE '(^|[;&|]|\s)git( -C ("[^"]+"|[^ ]+))? push($|\s)' || exit 0

dir=$(echo "$command" | grep -oE 'git -C ("[^"]+"|[^ ]+) push' | head -1 | sed -E 's/^git -C //; s/ push$//; s/^"//; s/"$//')
[ -n "$dir" ] && case "$dir" in /*) ;; *) dir="$cwd/$dir";; esac
repo_root=$(git -C "${dir:-$cwd}" rev-parse --show-toplevel 2>/dev/null) || exit 0
[ -f "$repo_root/package.json" ] || exit 0
jq -e '.scripts.build' "$repo_root/package.json" >/dev/null 2>&1 || exit 0

build_output=$(cd "$repo_root" && npm run build 2>&1)
build_status=$?

if [ "$build_status" -ne 0 ]; then
  tail_output=$(echo "$build_output" | tail -60)
  jq -n --arg reason "npm run build FAILED in $repo_root — push blocked. Fix the build first.

$tail_output" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$reason}}'
fi
exit 0
