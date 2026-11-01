# gm [slug] — resume a thread saved by /nox, inside its own worktree.
# Add to ~/.zshrc:  source ~/.claude/gm.zsh
unalias gm 2>/dev/null
gm() {
  local d=~/.claude/threads f wt n i
  local -a fs
  for f in $d/*.md(Nom); do grep -q '^status: \(active\|paused\)' $f && fs+=$f; done
  if [[ -n $1 ]]; then f=$d/$1.md; [[ -f $f ]] || { echo "no thread: $1"; return 1; }
  elif (( ${#fs} == 0 )); then echo "no open threads: run /nox in a session first"; return 1
  elif (( ${#fs} == 1 )); then f=$fs[1]
  else
    for i in {1..${#fs}}; do
      printf '%2d  %-28s %s  %s\n' $i ${fs[$i]:t:r} "$(sed -n 's/^updated: //p' $fs[$i])" "$(sed -n 's/^branch: //p' $fs[$i])"
    done
    read "n?which? "; f=$fs[$n]; [[ -n $n && -f $f ]] || return 1
  fi
  wt=$(sed -n 's/^worktree: //p' $f | head -1)
  [[ -d $wt ]] || { echo "worktree gone ($wt), staying here"; wt=$PWD; }
  cd $wt && claude "/gm ${f:t:r}"
}
