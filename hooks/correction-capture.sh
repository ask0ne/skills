#!/bin/bash
# Event: UserPromptSubmit
# When a prompt reads as a correction ("you're wrong", "I told you") or an explicit rule
# ("remember this", "from now on"), injects context telling Claude to fix the thing first
# and then persist the lesson (memory file, hook proposal, or "no rule needed").
# Corrections are rate-limited to one per 10 minutes per session; explicit rules always fire.
# Requires: jq, grep, date

in=$(cat 2>/dev/null)
p=$(jq -r '.prompt // ""' <<<"$in" 2>/dev/null | tr '[:upper:]' '[:lower:]')
sid=$(jq -r '.session_id // "x"' <<<"$in" 2>/dev/null)
[ ${#p} -lt 6 ] && exit 0
case "$p" in /*|"<task-notification"*) exit 0;; esac

kind=""
if grep -qE "remember (this|that)|from now on|never (do|add|use|write)|always (use|do|write)|standing rule" <<<"$p"; then
  kind="explicit rule"
elif grep -qE "you'?re wrong|you are wrong|that'?s wrong|is wrong|wrong (csv|number|count|file|query|table)|i told you|i said|not what i (asked|said|meant)|why (are|did) you (forget|ignore|add|change|remove)|you (forgot|missed|ignored|keep)|drop that idea|cannot be the (issue|cause)|this cannot be|didn'?t ask (for|you)" <<<"$p"; then
  kind="correction"
fi
[ -n "$kind" ] || exit 0

mark="${TMPDIR:-/tmp}/.claude-correction-${sid}"
if [ "$kind" = "correction" ] && [ -f "$mark" ] && [ $(( $(date +%s) - $(cat "$mark") )) -lt 600 ]; then exit 0; fi
date +%s > "$mark" 2>/dev/null

jq -nc --arg k "$kind" '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:("CORRECTION CAPTURE (" + $k + "): fix the thing first. Then, before the turn ends, persist the lesson so it never repeats: (1) check memory/MEMORY.md for an existing file covering it and update that, else write a feedback memory with **Why:** + **How to apply:**, quoting the user'"'"'s words. (2) If it must hold 100% of the time and is mechanically checkable, propose a hook in one line, and do not build it unasked. (3) If it was a one-off slip with no general lesson, say \"no rule needed\" in one line. Report which of the three you did, in one line.")}}'
exit 0
