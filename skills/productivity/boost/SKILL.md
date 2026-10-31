---
name: boost
description: "Parallelize the task at hand. Triages whether the work actually splits, then fans it out across subagents (or a workflow) with the right isolation and a stated cost — instead of grinding through it serially."
trigger: /boost
---

# /boost

The user calls this when something is taking too long. The job is to **split the
remaining work and run it concurrently** — not to spawn agents for their own
sake.

Most tasks that *feel* slow are slow for one of two reasons:
1. **Genuinely wide** — N independent things to look at. Fan-out wins big.
2. **Genuinely deep** — one dependency chain. Fan-out makes it *slower* and
   produces conflicting edits.

**Triage before you spawn.** A fleet on a serial task burns tokens, floods
context, and ends with agents overwriting each other.

## Pushing back is the job

**Invoking `/boost` is not evidence the task parallelizes.** It is a symptom
report ("this feels slow"), not a diagnosis. Diagnosing it is your half of the
work.

Declining is a **success**, not a failure to help. The most valuable output of
this skill is often one line: *"this won't parallelize — here's why, and here's
the faster path."* Do not spawn agents to look responsive.

Say no plainly, in one line, without hedging or apologising. Then give the
faster serial path in the same breath. Never spawn a token fleet as a
consolation prize.

If the user pushes back on your pushback and still wants the fan-out — build it.
Their call, stated once, then execute in full. Do not re-argue.

### Default answer is NO for these shapes

| Shape | Why fan-out loses |
|---|---|
| **One bug, one trace** ("why did this user get X?") | One causal chain. N agents = N overlapping guesses and no owner of the answer. |
| **The answer already exists** (saved queries, docs, a CLAUDE.md, a code index) | One lookup beats 8 agents. Look before you fan out. |
| **Under ~4 units** | Spawn + prompt + merge overhead exceeds the work. Just do it. |
| **Units share a file, or a checkout** | Concurrent writes to one tree corrupt each other. Serial, or worktrees. |
| **Needs the user's judgment mid-way** | Agents can't ask. They will guess, confidently, and be wrong. |
| **Vague scope** ("clean up the codebase") | Vague prompts × N = N piles of unusable output. Narrow the scope first, *then* consider boosting. |
| **Prod / money / outbound-message writes** | Never delegated. Full stop. |
| **The slowness is one long build/query/deploy** | Wall-clock is the tool's, not yours. Agents change nothing. |

### The honest failure modes to name

When declining, name the specific one — it is more useful than "it won't help":

- *"N agents will each find the same three things"* — redundancy, not coverage
- *"the units aren't independent; #2 needs #1's answer first"* — it's a pipeline or it's serial
- *"the bottleneck is my reading, not my searching"* — fan-out speeds up finding, not understanding
- *"scope is too vague to write 6 useful prompts"* — the prompt is the work; if you can't write it, agents can't do it
- *"you'd be reviewing 6 diffs instead of 1"* — parallel writes move cost onto the user, they don't remove it

### Required decline format

```
boost declined: <shape> — <the specific failure mode>
faster: <the actual serial path, one line>
```

Nothing more. No apology, no consolation fan-out, no essay.

---

## Triggers

Invoke when the user says `/boost`, "this is taking too long", "speed this up",
"parallelize this", "fan this out", "use subagents", "spawn agents", "do these
at once", or when a task they just gave obviously spans many repos/files/modules.

It may be called **mid-task**. In that case boost the *remainder*, not the whole
thing — state what's already done and split only what's left.

---

## Step 1 — Triage (always, out loud, ≤4 lines)

Answer three questions:

1. **What are the independent units?** Repos, files, modules, cohorts,
   findings, endpoints, migrations. Name them and count them.
2. **Do any unit's results feed another unit's input?** If yes, that's a
   pipeline, not a fan-out — or it's serial.
3. **Does anything write?** Reads parallelize freely. Writes need isolation.

Then state the verdict as one line:
`boost: <N> independent units, <read|write>, mechanism: <X>, est ~<n> agents`

If it doesn't split: say so in one line, give the fastest serial path, and stop.
Do not spawn anything.

---

## Step 2 — Pick the mechanism by shape

| Shape | Mechanism |
|---|---|
| **Wide read** — audit/search/inventory across N repos, files, modules | `Agent` × N, `subagent_type: "Explore"` (locate) or `"general-purpose"` (locate + reason). All in ONE message so they run concurrently. |
| **Wide read, needs full session context** — each unit needs everything discussed so far | `Agent` × N with `subagent_type: "fork"`. Costs more; use only when the context genuinely matters. |
| **Wide verify** — N findings/claims each needing an independent check | `Agent` × N, one finding each, adversarial prompt ("try to disprove this"). |
| **Wide write, independent files** — N changes that never touch the same file | `Agent` × N with `isolation: "worktree"`. Never let two agents write the same checkout. |
| **Pipeline** — review→verify, extract→validate, per dimension | `Workflow` tool with `pipeline()`. Each dimension verifies as soon as its own review lands. |
| **Deep / serial / one file / needs user input mid-way** | **No agents.** Do it yourself, serially. |

Hard limits:
- Default cap **8 agents**. Do not go past ~15 without saying why.
- `Workflow` only when the shape is a real multi-stage pipeline. A plain
  fan-out does not need it — `Agent` × N is cheaper and easier to read.

---

## Step 3 — Write the prompts properly

This is where fan-out usually fails. Each subagent gets:

- **Its own narrow slice, named explicitly.** "Audit `payment-service`" not
  "help audit the repos."
- **The return shape you need**, spelled out. "Return: file:line, the symptom,
  and the exact name. No summary, no preamble." Unstructured returns are
  unmergeable.
- **The relevant standing rules**, because a subagent does NOT inherit this
  session's conversation (only `fork` does). At minimum:
  - Read-only unless it owns a worktree — say it in the prompt
  - **No prod writes, ever** — a subagent reports, never mutates
  - Any project-specific gotchas the agent would otherwise trip on
- **A pointer to existing answers** (saved queries, docs, a code index) so it
  doesn't rediscover them.

Send every independent `Agent` call **in one message**. Separate messages run
them serially, which defeats the entire point.

---

## Step 4 — Safety rails for parallel writes

Never let two agents write the same checkout. Use `isolation: "worktree"`.

**The dirty-tree trap:** working trees often carry uncommitted work. A worktree
branched off a dirty tree inherits that contamination, and a same-tree diff
will not reveal it.

So for any write fan-out:
- Base every worktree on your protected/prod branch (`origin/<it>`), never on the current dirty HEAD
- Have each agent report `git diff origin/<base> -- <its files>` — the actual
  hunks, not a file list
- The parent reviews those hunks before anything is committed
- Never let a subagent push. Merging and pushing is the parent's job

---

## Step 5 — State the cost before spawning

One line, before the calls:
`spawning <N> × <type> — est. <rough token cost>, wall-clock ~<X>× faster serial`

If a boost would plausibly burn a big share of the user's usage window, say so
and offer a narrower split (4 agents on the highest-value units instead of 10
on everything).

---

## Step 6 — Merge, don't relay

When results land:
- **Do not re-run their work.** You delegated it; take the result.
- **Do not dump raw agent output at the user.** Merge into one answer: the
  finding, where, and what to do. Deduplicate — parallel agents often find the
  same thing from different angles.
- **Reconcile conflicts explicitly.** If two agents disagree, say so and resolve
  it or flag it — do not silently pick one.
- **Do not treat a subagent's claim as verified fact.** They are often
  confidently wrong. Spot-check anything load-bearing before the user acts on it.
- If an agent is still running, say it's still running. Never predict or invent
  a pending result.

---

## Worked examples

**"Check error handling across all 6 services"** → wide read.
6 × `general-purpose`, one per service. Each returns
`name | trigger | file:line | gap`. One message. Merge into one table.

**"Audit these 12 report definitions"** → wide read, but the answers are
already saved somewhere. **Don't fan out.** One lookup beats 12 agents. Say that.

**"Fix the same nullable bug in 4 services"** → wide write.
4 × `general-purpose` with `isolation: "worktree"`, each based on the
protected branch, each returning its diff hunks. Parent reviews all 4, then
ships them one at a time.

**"Why did this one user get the wrong notification?"** → deep, serial.
**No agents.** One trace through one path. Fan-out would just produce 5
overlapping guesses.

---

## Verification loop — account for every agent before merging

Fan-out fails silently. An agent that returned nothing looks exactly like an
agent whose slice was empty, and a merged answer built on 3 of 5 results reads
as confident and complete. Close the loop before reporting.

**Roll call — one line per agent spawned:**

| agent | slice | returned? | non-empty? | merged? |
|---|---|---|---|---|

**Pass = all five:**
1. **count matches** — agents returned == agents spawned. No exceptions.
2. **no empty summaries** — an agent that returned nothing is a *failure*, not an
   empty result. Re-run that slice or say it is missing.
3. **coverage is complete** — every slice of the original task appears in exactly
   one agent's result. Nothing dropped, nothing double-counted.
4. **conflicts resolved** — where two agents disagree, you picked one and said
   why. Never merge contradictory findings into one smooth paragraph.
5. **no fabrication** — nothing in the merged answer that no agent actually
   reported. If a result is still pending, say pending.

For **write** fan-outs, additionally:

6. each worktree based on the protected branch, not a dirty HEAD — verify per agent
7. no two agents touched the same file — `git diff --name-only` across all
   worktrees, assert the union has no duplicates
8. every worktree cleaned up, or listed as deliberately kept

**On failure: re-run the missing slice.** Do not merge around a hole and do not
report a partial fan-out as complete. If an agent cannot be recovered, state
exactly which slice is unverified in the final answer.

State the cost you actually spent against the cost you quoted up front. If it
ran well over, say so — that calibrates the next triage.

---

## What this skill never does

- Spawn agents for a serial task, or for a task one lookup would answer
- Spawn a token fleet to look responsive after deciding it won't help
- Hedge a decline ("we could try...") instead of naming the failure mode and the faster path
- Send independent agents in separate messages
- Let a subagent write to prod, push, or share a checkout with another agent
- Base a write worktree on a dirty HEAD
- Relay raw agent output instead of one merged answer
- Report a pending agent's result as if it had arrived
