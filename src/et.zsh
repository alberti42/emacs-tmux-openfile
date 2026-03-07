#!/usr/bin/env zsh

# emacs-tmux-openfile — open a file in a running Emacs from within tmux.
#
# Usable as a zsh plugin function (sourced via emacs-tmux-openfile.plugin.zsh)
# or executed directly as a script.

function et() {
  emulate -LR zsh
  setopt errexit nounset pipefail

  [[ -n ${TMUX-} ]] || { print -u2 "${0}: error: not inside tmux"; return 1; }

  local keep_focus=0
  local opt=${1-}

  if [[ $opt == "-k" || $opt == "--keep-focus" ]]; then
    keep_focus=1
    shift
  fi

  opt=${1-}

  if [[ $opt == "--list" ]]; then
    tmux list-panes -F $'#{pane_index}\t#{pane_id}\t#{pane_current_command}\t#{pane_tty}'
    return 0
  fi

  local cmdfile
  cmdfile=$(tmux show-options -w -qv @emacs_openfile_cmdfile 2>/dev/null || true)

  if [[ $opt == "--cmdfile" ]]; then
    [[ -n $cmdfile ]] || return 1
    print -r -- "$cmdfile"
    return 0
  fi

  local file=${1-}
  if [[ -z $file ]]; then
    print -u2 "usage: ${0} [-k] FILE"
    print -u2 "       ${0} --cmdfile"
    print -u2 "       ${0} --list"
    print -u2 "options:"
    print -u2 "  -k, --keep-focus  do not move focus to the Emacs pane after opening"
    return 2
  fi

  [[ -n $cmdfile ]] || {
    print -u2 "${0}: error: no @emacs_openfile_cmdfile set for this tmux window"
    print -u2 "${0}: hint: load tmux-openfile.el and run M-x tmux-openfile-enable, then start Emacs in a tty inside this tmux window"
    return 1
  }

  [[ -f $cmdfile && ! -L $cmdfile && -O $cmdfile ]] || {
    print -u2 "${0}: error: unsafe cmdfile: $cmdfile"
    return 1
  }

  # In-place update (no temp+rename) so Emacs file-notify watches keep working.
  print -r -- "$file" >| "$cmdfile"

  # Move focus to the Emacs pane (unless --keep-focus was given).
  if [[ $keep_focus -eq 0 ]]; then
    local paneid
    paneid=$(tmux show-options -w -qv @emacs_openfile_paneid 2>/dev/null || true)
    [[ -n $paneid ]] && tmux select-pane -t "$paneid"
  fi
}

# Allow direct execution as a script (not sourced as a plugin).
[[ "$ZSH_EVAL_CONTEXT" == *:file* ]] || et "$@"
