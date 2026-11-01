---
name: nox
description: "End of day: save where this session's work stopped to ~/.claude/threads/<slug>.md (worktree, branch, git state, next action) so the `gm` shell command resumes it tomorrow in the same worktree. Local only, no git commits. Trigger: /nox, \"nox\", \"eod\", \"wrapping up\", \"done for the day\"."
trigger: /nox
---

# /nox

One command at day end. Write the bookmark, verify it, say goodnight. Don't ask unless Step 1 is ambiguous.

A thread = **where the work stopped and what's next**. Lessons go to memory, how the code works goes to the docs. Link, don't copy.

## Step 1 — Pick the thread

```bash
git rev-parse --show-toplevel 2>/dev/null || pwd
bash -c 'grep -l "^status: \(active\|paused\)" ~/.claude/threads/*.md 2>/dev/null'   # bash: zsh aborts on a no-match glob
```

- A thread whose `worktree:` equals this toplevel, or whose Goal this session clearly continued → update it.
- None → new kebab-case slug from the work (`checkout-retry-bug`, `onboarding-copy`).
- Session spans two unrelated pieces of work → one thread each.
- Ask one short question only if two threads plausibly match.

## Step 2 — Collect facts, one call

```bash
cd "<toplevel>"
base=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/main)
git branch --show-current
git status --porcelain | head -30
git fetch origin --quiet; git rev-list --left-right --count $base...HEAD   # behind ahead
git log -3 --format='%h %s (%cr)'
git rev-parse --abbrev-ref @{u} 2>/dev/null && git rev-list --count @{u}..HEAD       # unpushed commits
git stash list | head -3
```

Not a git dir → record `branch: -`. Uncommitted files stay where they are: no WIP commit, no stash, unless asked. Running dev servers and background tasks go under **Open**; don't kill them.

## Step 3 — Write `~/.claude/threads/<slug>.md`

```markdown
---
slug: <slug>
status: paused
worktree: <absolute toplevel>
branch: <branch>
updated: <YYYY-MM-DD>
---
## Goal
<one line>

## Status
<3-5 lines: what's done, what's half-done, dated. Unchecked claim → "(unverified)">

## Next actions
1. <first concrete action: a command, file, or question, not "continue">

## Open
<blocked on whom/what, uncommitted files, unpushed commits, running things, other repos touched and their worktrees>

## Gotchas
<only what bit today; skip if none>

## Log
- <YYYY-MM-DD> <one line>
```

Updating: rewrite Status / Next actions / Open, append one Log line, keep the rest. Absolute dates only. No secrets, database URLs or tokens.

## Step 4 — Verify

```bash
f=~/.claude/threads/<slug>.md
wt=$(sed -n 's/^worktree: //p' "$f"); test -d "$wt" && echo "wt ok" || echo "WT MISSING"
[ "$(sed -n 's/^branch: //p' "$f")" = "$(git -C "$wt" branch --show-current 2>/dev/null || echo -)" ] && echo "branch ok"
grep -q "^updated: $(date +%F)" "$f" && echo "date ok"
grep -A1 '^## Next actions' "$f" | tail -1
```

**Pass = all four:** worktree exists and equals the toplevel, branch matches, `updated` is today, Next actions has a concrete item 1 (or "None pending" with status `done-for-now`). On any failure, fix the file and re-run this block. Do not report saved until it passes.

## Step 5 — Report (3 lines)

- `Saved <slug> → ~/.claude/threads/<slug>.md`
- what's left loose: uncommitted / unpushed / running, or "tree clean"
- `Tomorrow: gm` (or `gm <slug>` if more than one thread is open)
