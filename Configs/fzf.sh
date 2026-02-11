# ═══════════════════════════════════════════════════════════════
# TecnoBash - fzf Wrapper (isolated)
# ═══════════════════════════════════════════════════════════════

function tb_fzf() {
    env -u FZF_DEFAULT_COMMAND \
        -u FZF_DEFAULT_OPTS \
        -u FZF_CTRL_T_COMMAND \
        -u FZF_ALT_C_COMMAND \
        -u FZF_TMUX \
        command fzf "$@"
}
