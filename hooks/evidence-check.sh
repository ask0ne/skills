#!/bin/bash
# Event: Stop
# If this turn changed code/data (Edit/Write/NotebookEdit, git commit/push, SQL writes) and
# the final reply claims done/fixed/shipped but has no "Evidence:" line, blocks once and
# asks for the exact command/output that proves it. Won't loop (honours stop_hook_active).
# Requires: jq, python3

in=$(cat 2>/dev/null)
[ "$(jq -r '.stop_hook_active // false' <<<"$in")" = "true" ] && exit 0
tp=$(jq -r '.transcript_path // ""' <<<"$in")
[ -f "$tp" ] || exit 0

python3 - "$tp" <<'PY'
import json, re, sys
rows = []
for l in open(sys.argv[1], errors='ignore'):
    try: rows.append(json.loads(l))
    except Exception: pass

def is_prompt(d):
    if d.get('type') != 'user' or d.get('isMeta') or d.get('toolUseResult') is not None: return False
    c = (d.get('message') or {}).get('content')
    t = c if isinstance(c, str) else ' '.join(b.get('text', '') for b in c or [] if isinstance(b, dict) and b.get('type') == 'text')
    t = t.strip()
    return bool(t) and not t.startswith(('<task-notification', '<local-command', '<bash-', 'Caveat:', '[Request interrupted'))

start = max((i for i, d in enumerate(rows) if is_prompt(d)), default=-1)
turn = rows[start + 1:]
changed, last = False, ''
for d in turn:
    if d.get('type') != 'assistant': continue
    for b in (d.get('message') or {}).get('content') or []:
        if not isinstance(b, dict): continue
        if b.get('type') == 'tool_use':
            n, i = b.get('name', ''), b.get('input') or {}
            if n in ('Edit', 'Write', 'MultiEdit', 'NotebookEdit') and not re.search(r'/(scratchpad|\.claude/projects)/', i.get('file_path', '')):
                changed = True
            if n == 'Bash' and re.search(r'git (commit|push)|psql .*(update|insert|delete) ', i.get('command', ''), re.I):
                changed = True
        if b.get('type') == 'text':
            last = b.get('text', '')
if not changed or not last: sys.exit(0)
if re.search(r'^\s*\**evidence\**\s*:', last, re.I | re.M): sys.exit(0)
if not re.search(r'\b(done|fixed|implemented|shipped|pushed|works|working|verified|complete[d]?|landed|resolved)\b', last, re.I): sys.exit(0)
print(json.dumps({"decision": "block", "reason": "Done-claim without proof. Add an `Evidence:` line to the reply: the exact command/query/screenshot you ran this turn and the key output that proves the claim (build exit 0, test count, row count, UI snapshot). Nothing run → say what is unverified instead of claiming done."}))
PY
exit 0
