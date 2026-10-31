---
name: wip
description: "Mid-session checklist of THIS session's work: done (with re-checked evidence), in progress, blocked on you, not started, measured against the goal or plan. Built from the conversation plus live git/PR/deploy state. Read-only. Not a day-end save, not a summary of a target (tldr). Trigger: /wip, \"where are we\", \"what's left\", \"what's pending\", \"anything left to push\", \"did we X\", \"recap\"."
trigger: /wip
---

# /wip

Named `wip`, not `status`: `/status` and `/recap` are built-in Claude Code commands. Read-only: no commits, stash, kills or writes. A "done" with no visible proof is a guess.

## Step 1: Anchor the goal and the items

- Goal: the original ask, or the PRD/plan named this session. One line, the user's words.
- Items: every requirement, fix, decision and promise made this session.
- `did we X?`: run the same loop for item X only. Answer yes/no first.

## Step 2: Re-check reality, every repo touched this session

```bash
cd "<worktree>"; git fetch origin --quiet
git branch --show-current; git status --porcelain | wc -l
git rev-parse --abbrev-ref @{u} 2>/dev/null && git rev-list --count @{u}..HEAD   # unpushed
gh pr list --head "$(git branch --show-current)" --state all --json number,state,baseRefName
git merge-base --is-ancestor <sha> origin/<deploy-branch> && echo "in <deploy-branch>"
gh run list --branch <deploy-branch> -L 3 --json name,conclusion,headSha   # merged is not deployed
```

Rebased since merge: use `git cherry origin/<deploy-branch> <branch>` instead. Non-git items (migrations, data changes, schedules, templates, cloud functions) get a read-only re-check, or are marked `unverified`. List running servers and background agents under In progress.

## Shape

Verdict first: `<N>/<M> done · <what's live where> · <what waits on you>`. No preamble.

| # | Item | State | Evidence / next |
|---|---|---|---|

States: `done` · `in progress` · `blocked: you` (decision, push OK, production write) · `blocked: <other>` · `not started`. Deploy column words: `local` / `committed` / `pushed` / `PR #n open` / `merged` / `deployed`. Then `Next:` one concrete action. About 40 lines.

## Verification loop: re-check, don't recall

1. every `done` row cites a command or read run in Step 2 of THIS answer, not an earlier message.
2. merged and deployed are never merged into one word; each environment claim has its own merge-base or CI run.
3. every item from Step 1 has a row, so nothing silently drops between answers.
4. every number carries its source tag; nothing checkable is left `unverified` without a reason.

**Pass = all four.** On any failure, fix the row and re-run that check. Do not report a row as done from memory. End with `Evidence:` naming the commands and the outputs that prove it.
