# ═══════════════════════════════════════════════════════════════
# TecnoBash - fzf Wrapper (isolated)
# ═══════════════════════════════════════════════════════════════

function tb_fzf() {
    local fzf_bin
    fzf_bin="$(command -v fzf)" || return 1

    env -u FZF_DEFAULT_COMMAND \
        -u FZF_DEFAULT_OPTS \
        -u FZF_CTRL_T_COMMAND \
        -u FZF_ALT_C_COMMAND \
        -u FZF_TMUX \
        "$fzf_bin" "$@"
}

