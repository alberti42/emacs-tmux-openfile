#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf '%s\n' "usage: ${0##*/} [-k] FILE" >&2
  printf '%s\n' "       ${0##*/} --cmdfile" >&2
  printf '%s\n' "       ${0##*/} --list" >&2
  printf '%s\n' "options:" >&2
  printf '%s\n' "  -k, --keep-focus  do not move focus to the Emacs pane after opening" >&2
}

[[ -n ${TMUX-} ]] || { printf '%s\n' "${0##*/}: error: not inside tmux" >&2; exit 1; }

keep_focus=0
opt=${1-}

if [[ $opt == "-k" || $opt == "--keep-focus" ]]; then
  keep_focus=1
  shift
fi

opt=${1-}

if [[ $opt == "--list" ]]; then
  tmux list-panes -F $'#{pane_index}\t#{pane_id}\t#{pane_current_command}\t#{pane_tty}'
  exit 0
fi

cmdfile=$(tmux show-options -w -qv @emacs_openfile_cmdfile 2>/dev/null || true)

if [[ $opt == "--cmdfile" ]]; then
  [[ -n $cmdfile ]] || exit 1
  printf '%s\n' "$cmdfile"
  exit 0
fi

file=${1-}
[[ -n $file ]] || { usage; exit 2; }

[[ -n $cmdfile ]] || {
  printf '%s\n' "${0##*/}: error: no @emacs_openfile_cmdfile set for this tmux window" >&2
  printf '%s\n' "${0##*/}: hint: load tmux-openfile.el and run M-x tmux-openfile-enable, then start Emacs in a tty inside this tmux window" >&2
  exit 1
}

[[ -f $cmdfile && ! -L $cmdfile && -O $cmdfile ]] || {
  printf '%s\n' "${0##*/}: error: unsafe cmdfile: $cmdfile" >&2
  exit 1
}

# In-place update (no temp+rename) so Emacs file-notify watches keep working.
printf '%s\n' "$file" >| "$cmdfile"

# Move focus to the Emacs pane (unless --keep-focus was given).
if [[ $keep_focus -eq 0 ]]; then
  paneid=$(tmux show-options -w -qv @emacs_openfile_paneid 2>/dev/null || true)
  [[ -n $paneid ]] && tmux select-pane -t "$paneid"
fi
