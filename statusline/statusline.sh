#!/usr/bin/env bash
# Claude Code status line (two-colour pastel, one line):
#   [model effort-glyph] | (branch) | $cost | ⏳ context% | session tokens | duration | burn rate
# Branch is green on main/master, salmon anywhere else. Context goes salmon at 85%+,
# duration goes khaki past 24h, burn rate (context delta per turn) shows only when |delta| >= 500.
# Requires: jq, awk, git. Reads the status-line JSON on stdin.

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir')
model=$(echo "$input" | jq -r '.model.display_name')
effort=$(echo "$input" | jq -r '.effort.level // .effort // empty')
transcript=$(echo "$input" | jq -r '.transcript_path // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

dur_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
dur_sec=$((dur_ms / 1000))
duration=$(printf '%dm%02ds' $((dur_sec/60)) $((dur_sec%60)))

# session tokens: whole-transcript sum of input + output + cache_creation
sess_tokens=0
[ -n "$transcript" ] && [ -f "$transcript" ] && sess_tokens=$(jq -R 'fromjson? | select(.message.usage) | .message.usage
    | (.input_tokens//0)+(.output_tokens//0)+(.cache_creation_input_tokens//0)' "$transcript" \
  | awk '{t+=$1} END{print t+0}')
sess_fmt=$(awk -v t="$sess_tokens" 'BEGIN{printf (t>=1000000)?sprintf("%.1fM",t/1000000):((t>=1000)?sprintf("%.1fk",t/1000):t)}')

in_git_repo=false
branch=""
if git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  in_git_repo=true
  branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
fi

# burn rate: ctx delta between the last two assistant turns (dupes collapsed)
burn=0
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  burn=$(tail -300 "$transcript" \
    | jq -R 'fromjson? | select(.message.usage) | .message.usage
             | (.input_tokens//0)+(.cache_read_input_tokens//0)+(.cache_creation_input_tokens//0)' \
    | uniq | tail -2 | awk 'NR==1{p=$1} NR==2{print $1-p}')
  burn=${burn:-0}
fi

# pastel palette (256-colour) — readable, not shouty. Separators stay dim.
GREEN='\033[38;5;114m'      # soft green  — branch on main/master
RED='\033[38;5;210m'        # soft salmon — any other branch, and 85%+ warnings
YELLOW='\033[38;5;187m'     # pale khaki  — duration past 24h
ORANGE='\033[38;5;216m'     # pale peach  — hot burn rate
C_COST='\033[38;5;179m'     # soft gold   — $ spend
C_CTX='\033[38;5;110m'      # soft blue   — context used
C_TOK='\033[38;5;146m'      # lavender    — session tokens
C_DUR='\033[38;5;108m'      # sage        — duration
C_BURN='\033[38;5;180m'     # tan         — burn rate
C_MODEL='\033[38;5;139m'    # dusty mauve — model + effort
DIM='\033[2m'
RESET='\033[0m'

case "$branch" in
  main|master) branch_color="$GREEN" ;;
  *)           branch_color="$RED" ;;
esac

# model, effort glyph, branch, cost
model_tag="$model"
case "$(echo "$effort" | tr '[:upper:]' '[:lower:]')" in
  low)             effort_emoji="▂" ;;    # 1/4  — slightly filled
  medium)          effort_emoji="▄" ;;    # 1/2  — half
  high)            effort_emoji="█" ;;    # full
  ultra)           effort_emoji="█▄" ;;   # 1.5 blocks
  xhigh)           effort_emoji="██" ;;   # 2 blocks
  max)             effort_emoji="███" ;;  # 3 blocks
  *)               effort_emoji="" ;;
esac
[ -n "$effort_emoji" ] && model_tag="$model $effort_emoji"
printf "${C_MODEL}[%s]${RESET}" "$model_tag"
sep=" ${DIM}|${RESET} "
$in_git_repo && printf "${sep}${branch_color}(%s)${RESET}" "${branch:-detached}"
printf "${sep}${C_COST}\$%s${RESET}" "$(awk -v c="$cost" 'BEGIN{printf "%.2f", c}')"
printf " ${DIM}|${RESET} "

# context used (red at 85%+), session tokens, duration (dim, yellow past 24h), burn rate
used=$(awk -v u="$used_pct" 'BEGIN{printf "%.0f", u}')
ctx_color="$C_CTX"
[ "$used" -ge 85 ] && ctx_color="$RED"
printf "${ctx_color}⏳ %s%%${RESET}" "$used"
printf " ${DIM}|${RESET} ${C_TOK}%s${RESET}" "$sess_fmt"
dur_color="$C_DUR"
[ "$dur_sec" -ge 86400 ] && dur_color="$YELLOW"
printf " ${DIM}|${RESET} ${dur_color}%s${RESET}" "$duration"
if [ "$burn" -ne 0 ] 2>/dev/null && { [ "$burn" -ge 500 ] || [ "$burn" -le -500 ]; }; then
  burn_color="$C_BURN"
  [ "$burn" -ge 15000 ] && burn_color="$ORANGE"
  printf " ${DIM}|${RESET} ${burn_color}%s${RESET}" "$(awk -v b="$burn" 'BEGIN{a=(b<0)?-b:b; s=(b<0)?"↓":"↑"; printf (a>=1000)?sprintf("%s%.1fk",s,a/1000):sprintf("%s%d",s,a)}')"
fi

printf "\n"
