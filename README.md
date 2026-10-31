# skills

my claude code skills, subagents, hooks and status line. all mine, all written the hard way: make a mistake, turn it into a rule.

## install

### skills and subagents

```
/plugin marketplace add ask0ne/skills
/plugin install ask0ne-skills@ask0ne
```

or paste this into claude code to get a single skill (swap the name and path):

```
install the claude code skill "boost": fetch https://raw.githubusercontent.com/ask0ne/skills/main/skills/productivity/boost/SKILL.md and save it, unchanged, to ~/.claude/skills/boost/SKILL.md. then tell me how to trigger it.
```

### hooks and the status line

these live in `settings.json`, so they are not part of the plugin. each one is a script plus a small wiring file. copy a prompt below and paste it into claude code, it does the install. hooks need `jq`.

these are scripts that run on your machine. read them first, links are in the reference.

**kill-guard**

```
install the claude code hook "kill-guard" (needs jq): save https://raw.githubusercontent.com/ask0ne/skills/main/hooks/kill-guard.sh to ~/.claude/hooks/kill-guard.sh and chmod +x it. then merge a settings.json entry for it under hooks.PreToolUse, using the event, matcher and timeout in https://raw.githubusercontent.com/ask0ne/skills/main/hooks/kill-guard.json; the command is: bash "$HOME/.claude/hooks/kill-guard.sh". keep every existing hook, no duplicates. tell me what it does and how to test it.
```

**pre-push-build-check**

```
install the claude code hook "pre-push-build-check" (needs jq): save https://raw.githubusercontent.com/ask0ne/skills/main/hooks/pre-push-build-check.sh to ~/.claude/hooks/pre-push-build-check.sh and chmod +x it. then merge a settings.json entry for it under hooks.PreToolUse, using the event, matcher and timeout in https://raw.githubusercontent.com/ask0ne/skills/main/hooks/pre-push-build-check.json; the command is: bash "$HOME/.claude/hooks/pre-push-build-check.sh". keep every existing hook, no duplicates. tell me what it does and how to test it.
```

**evidence-check**

```
install the claude code hook "evidence-check" (needs jq): save https://raw.githubusercontent.com/ask0ne/skills/main/hooks/evidence-check.sh to ~/.claude/hooks/evidence-check.sh and chmod +x it. then merge a settings.json entry for it under hooks.Stop, using the event, matcher and timeout in https://raw.githubusercontent.com/ask0ne/skills/main/hooks/evidence-check.json; the command is: bash "$HOME/.claude/hooks/evidence-check.sh". keep every existing hook, no duplicates. tell me what it does and how to test it.
```

**correction-capture**

```
install the claude code hook "correction-capture" (needs jq): save https://raw.githubusercontent.com/ask0ne/skills/main/hooks/correction-capture.sh to ~/.claude/hooks/correction-capture.sh and chmod +x it. then merge a settings.json entry for it under hooks.UserPromptSubmit, using the event, matcher and timeout in https://raw.githubusercontent.com/ask0ne/skills/main/hooks/correction-capture.json; the command is: bash "$HOME/.claude/hooks/correction-capture.sh". keep every existing hook, no duplicates. tell me what it does and how to test it.
```

**edit-lint**

```
install the claude code hook "edit-lint" (needs jq): save https://raw.githubusercontent.com/ask0ne/skills/main/hooks/edit-lint.sh to ~/.claude/hooks/edit-lint.sh and chmod +x it. then merge a settings.json entry for it under hooks.PostToolUse, using the event, matcher and timeout in https://raw.githubusercontent.com/ask0ne/skills/main/hooks/edit-lint.json; the command is: bash "$HOME/.claude/hooks/edit-lint.sh". keep every existing hook, no duplicates. tell me what it does and how to test it.
```

**statusline**

```
install this claude code status line (needs jq): save https://raw.githubusercontent.com/ask0ne/skills/main/statusline/statusline.sh to ~/.claude/statusline.sh and chmod +x it. then set "statusLine" in ~/.claude/settings.json to the json at https://raw.githubusercontent.com/ask0ne/skills/main/statusline/statusline.json, keeping every other key. tell me what each part of the line shows.
```

## reference

### productivity

* [`/boost`](skills/productivity/boost/SKILL.md): decides if slow work can split, fans it out safely, or says no
* [`/eli5`](skills/productivity/eli5/SKILL.md): re-explains the last answer in small words when you say huh
* [`/wip`](skills/productivity/wip/SKILL.md): read-only checklist of this session: what is done, with proof, and what is not

### engineering

* [`/ui-design`](skills/engineering/ui-design/SKILL.md): makes you pick an ascii mockup before any ui code gets written

### subagents

* [`build-verifier`](agents/build-verifier.md): runs the full build and test suite in one repo and returns only the distilled verdict
* [`parity-auditor`](agents/parity-auditor.md): read-only audit of what a change removed or broke
* [`path-tracer`](agents/path-tracer.md): traces one execution path end to end to explain why a specific outcome happened

### hooks

* [`kill-guard`](hooks/kill-guard.sh) (pretooluse): blocks pkill and killall so claude finds the exact pid first
* [`pre-push-build-check`](hooks/pre-push-build-check.sh) (pretooluse): runs npm run build before git push and blocks the push if it fails
* [`evidence-check`](hooks/evidence-check.sh) (stop): blocks a done claim that has no evidence line, once
* [`correction-capture`](hooks/correction-capture.sh) (userpromptsubmit): turns your corrections and rules into saved memory so they stick
* [`edit-lint`](hooks/edit-lint.sh) (posttooluse): nags when an edit adds a comment block longer than two lines

### status line

* [`statusline`](statusline/statusline.sh): model, effort, branch, cost, context used, session tokens, duration, burn rate

## license

MIT, see [LICENSE](LICENSE).
