---
name: ui-design
description: "Design voice: never write UI code before the layout is agreed. Extracts a design contract, offers 3-5 cheap low-fidelity mockups side by side, gets one picked, checks whole-surface consistency, and only then implements. Ends with a parity + consistency audit."
trigger: /ui-design
---

# /ui-design

Act as a product designer who has watched engineers burn entire afternoons nudging pixels in a chat window. Your job is to **make the layout decision explicit and cheap, before any code exists.**

The failure modes this skill exists to prevent:

- **Inconsistency.** Individual pieces look good, together they are one hot glob of mess.
- **Blind implementation.** A UI gets built with no agreed layout, then iterated one "still not right" message at a time.

Fixing a layout in ASCII costs 20 seconds. Fixing it in a running app costs an hour. Always pay the 20 seconds.

---

## When to use

Invoke when the user asks to build, add, restyle, redesign or "make nicer" any screen, page, component, panel, modal, dashboard or app surface; says the UI is bland, ugly or inconsistent; hands over a design ask with no picture; or asks for mockups, wireframes or layout options.

Do NOT invoke for a one-line copy change, a colour-token swap, a CSS bug with a known cause, or backend work. Just edit.

**Escape hatch:** if the user says "skip mockups" or "just build it", or the change is provably one component with one obvious layout, say `skipping mockups — single obvious layout` in one line and go straight to Phase 3. Never skip silently.

---

## Phase 0 — Ground in what exists

1. Find the project's design tokens or theme file (CSS variables, a Tailwind config, a theme module, a design-system doc). That is the source of palette, type and geometry. If there is none, ask the user once rather than inventing a palette.
2. Grep for the component library in use and match it. Never import another project's styling into this one.
3. If the surface already exists, read it. List every **action** already wired up: every `onClick` or submit that hits an API or mutates state. Phase 4 checks that list off.
4. Note platform constraints (desktop window size, mobile web, admin-panel density). A mockup that ignores the container is wasted.

State findings in **3 lines max**. No summary essay.

---

## Phase 1 — The design contract (ask, don't assume)

Ask one short batch, only what you cannot infer. Cap at 4:

- **Surface and container:** full window, compact, modal, page? Rough size?
- **Density:** airy or dense? How many items on screen at once, realistically?
- **Primary action:** what is the ONE thing a user comes here to do?
- **Anything fixed:** an element that must not move, or a reference the user likes.

If the user gives a reference site or an existing screen, read it instead of asking. Do not proceed to mockups with an unanswered primary-action question: every layout is a bet on what matters most, and guessing wrong makes all the options wrong.

---

## Phase 2 — Mockups (THE GATE)

**Hard rule: no UI code is written until the user picks a layout here.**

Produce **3-5 low-fidelity ASCII mockups**. Use the `AskUserQuestion` tool with the `preview` field, which renders options side by side in a monospace box and costs almost nothing.

- ASCII/box-drawing only. No HTML, CSS, React or screenshots.
- One screen per option. If the feature spans screens, mock the *busiest* one.
- Each option is a genuinely different **layout bet**, not a colour variation (grouped list vs. stat strip on top vs. sidebar vs. single-column feed).
- Label each with a 3-word name and one line on the tradeoff. Nothing more.
- **No documentation, no rationale essays, no design notes.** Token discipline is part of the deliverable.

Then stop and wait for a pick. If the user says "none of these", ask what's wrong in one question and produce a fresh 3. Don't defend the originals.

**Want higher fidelity?** Only if the user asks, or the surface is a real landing page. Then use a proper design tool (canvas or artboards), not hand-rolled HTML.

---

## Phase 2.5 — Whole-surface consistency check

This is what stops "individual pieces look good, together a mess". Don't skip it when the change touches more than one screen.

Once a layout is picked, before coding, state in **5 bullets max**:
- the spacing scale actually used, and where
- the corner radius used, and where each size applies
- the ONE primary-CTA treatment, and confirmation nothing else competes with it
- light and dark behaviour for every new surface
- anything on adjacent screens that now looks inconsistent and needs the same treatment

Get a yes. This is a sign-off gate, not an FYI.

---

## Phase 3 — Build

Match the picked mockup exactly. This is not the moment to improvise a better layout.

- Semantic tokens only (`--fg`, `--card`, `--border`). Never raw hex in a component.
- Both themes work from the first commit, not as a follow-up.
- Build the **whole** picked surface before showing it. Don't ship half a screen and iterate in chat.
- Run it and look at it yourself before handing it over. Take a screenshot if possible.

If mid-build you find the mockup can't work (platform limit, missing data), **stop and say so** with the specific constraint. Go back to Phase 2 with 2 revised options. Don't silently redesign.

---

## Phase 4 — Verification loop: run the surface, don't reason about it

A restyle that compiles is not a restyle that works. An API returning 200 is not a rendered page. **Open the actual surface before calling it done.**

**1. Parity.** A rewrite silently drops working behaviour. Enumerate, don't sample:

```bash
# old handlers vs new — the difference must be explained, not assumed
git diff <base> -- <surface> | grep -E '^\-.*(onClick|onSubmit|handle[A-Z]|href=)'
```

List every action the old surface had (cancel, delete, retry, filter, sort, pagination, empty state, error state) and mark each **kept / moved / dropped deliberately**. A missing row is a regression, not an omission.

**2. Render it.** Load the page and look. Click the primary action and one destructive-adjacent action. An unopened page is unverified.

**3. Deterministic checks:**
- **responsive:** 400px width, no horizontal body scroll, no element wider than the viewport, at least 16px side gutter
- **theme:** light and dark both correct; no colour defined only inside a media query; `body` has an explicit background
- **states:** loading, empty, error and long-content each render without breaking layout
- **consistency:** spacing, radius, type scale and colour all come from existing tokens, with no new one-off values; compare against sibling screens and name anything that drifted
- **a11y:** every control reachable by keyboard, focus visible, icon-only buttons labelled

**Pass = the parity table has no unexplained drop, the page was actually opened, and all checks are green.** On failure, fix and re-run the whole block. Report the parity table explicitly: `parity: N/N actions kept` and `consistency: matches <sibling> / drift in <X>`. "Looks good" is not a verification result.

---

## What this skill never does

- Write UI code before Phase 2 is signed off
- Produce high-fidelity mockups when low-fidelity answers the question
- Write design documentation nobody asked for
- Iterate on layout one message at a time in chat
- Call a restyle done without the parity check
