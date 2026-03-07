#!/hint/zsh

# Bootstrap loader for the 'et' function.
# On first call, sources the real implementation from src/et.zsh,
# which overwrites this stub, then forwards the call.

function et() {
  emulate -LR zsh

  local plugin_dir="${${(%):-%x}:a:h}"
  source "${plugin_dir}/src/et.zsh"
  et "$@"
}
