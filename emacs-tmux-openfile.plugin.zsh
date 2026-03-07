#!/hint/zsh

# Private bootstrap stub — sources the real implementation on first call,
# which redefines __emacs-tmux-openfile.et, then forwards the call.
function __emacs-tmux-openfile.et() {
  emulate -LR zsh
  local plugin_dir="${${(%):-%x}:a:h}"
  source "${plugin_dir}/src/et.zsh"
  __emacs-tmux-openfile.et "$@"
}

# Public wrapper under the user-configured name (default: et).
# ETO_CMD_NAME is read at source time and baked into the wrapper body,
# so the name is resolved once and never read again at call time.
(){
  local _cmd="${ETO_CMD_NAME:-et}"
  functions[$_cmd]="__emacs-tmux-openfile.et ${_cmd} \"\$@\""
}
