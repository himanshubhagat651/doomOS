# ==============================================================================
# DoomOS Default Zsh Profile
# ==============================================================================

# Shell History Settings
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=20000
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS

# Modern CLI Replacements & Aliases
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first'
alias cat='bat --style=plain'
alias grep='grep --color=auto'

# Fastfetch System Summary on Interactive Login
if [[ -o interactive ]] && command -v fastfetch >/dev/null 2>&1; then
    fastfetch
fi

# Initialize Starship Cross-Shell Prompt
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi
