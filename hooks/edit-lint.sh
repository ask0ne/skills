#!/bin/bash
# Event: PostToolUse (matcher: Edit|Write|MultiEdit)
# Lean-comment rule: if an edit adds a comment block of 3+ consecutive lines to a code
# file, blocks with a nudge to cut it to one short line. Docs/data files
# (md, txt, json, yaml, csv, env) are exempt. Shebang lines don't count.
# Requires: jq, awk

in=$(cat 2>/dev/null)
f=$(jq -r '.tool_input.file_path // ""' <<<"$in")
txt=$(jq -r '[.tool_input.new_string, .tool_input.content, (.tool_input.edits // [] | .[].new_string)] | map(select(.)) | join("\n")' <<<"$in")
[ -n "$f" ] && [ -n "$txt" ] || exit 0

case "$f" in
  *.md|*.txt|*.json|*.jsonl|*.csv|*.tsv|*.yml|*.yaml|*.env) exit 0;;
esac

run=$(awk '
  /^[[:space:]]*#!/ {next}
  /^[[:space:]]*(\/\/|#|\/\*|\*|--)/ {c++; if(c>m)m=c; next}
  {c=0}
  END{print m+0}' <<<"$txt")
[ "$run" -ge 3 ] || exit 0

jq -nc --arg r "Lean-comment rule: ${run}-line comment block in $(basename "$f"). Cut to one short line max; the why goes in the commit message or docs." '{decision:"block", reason:$r}'
exit 0
