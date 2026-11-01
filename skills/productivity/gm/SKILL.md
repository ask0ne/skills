---
name: gm
description: "Start of day: resume a thread saved by /nox. Reads ~/.claude/threads/<slug>.md, re-checks git reality since it was saved, and gives where-it-stands plus the first next action. Launched by the `gm` shell command (see shell/gm.zsh), which cds into the thread's worktree first. Trigger: /gm [slug], \"resume yesterday\", \"where were we\"."
trigger: /gm
---

# /gm [slug]

Normally arrives as `/gm <slug>` from the `gm` shell function, already in the right worktree. Read-only until you say go.

## Step 1 — Load the thread

- Slug given → `~/.claude/threads/<slug>.md`.
- No slug → thread whose `worktree:` equals `git rev-parse --show-toplevel`; else list `status: active|paused` threads (slug · updated · Goal) and ask which.
- Read it, then read only the files its Next action item 1 names.

## Step 2 — Re-check reality since `updated:`

```bash
cd "<worktree>"
base=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/main)
git branch --show-current                                   # still the thread's branch?
git status --porcelain | head -30                           # dirty files match Open?
git fetch origin --quiet
git rev-list --left-right --count $base...HEAD              # behind ahead
git merge-base --is-ancestor HEAD $base && echo "MERGED into $base"
git log $base --since="<updated>" --format='%h %an %s' | head -10   # what moved overnight
```

If Status or Open names a database row, deploy or external job, re-check it read-only. Can't check → keep it marked "(unverified)".

## Step 3 — Verify, then mark active

**Pass = every Status and Open claim is either re-confirmed or explicitly flagged as changed/unverified.** On a mismatch (branch merged, files gone, the base branch moved under the key paths) do not report the stale version. Rewrite Status first, then re-run Step 2's block.

Then set `status: active`, `updated: <today>`, append Log `- <today> resumed`.

## Step 4 — Report (≤10 lines)

- one-line Goal + where it stands
- what changed since `updated` (or "nothing moved")
- **first next action**, concrete
- ask before starting it only if it writes outside this worktree (push, a database, anything shared)
