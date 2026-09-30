# ==============================================================================
# DoomOS Default Bash Profile
# ==============================================================================

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Shell History Settings
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000

# Modern CLI Replacements & Aliases
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first'
alias cat='bat --style=plain'
alias grep='grep --color=auto'

# Fastfetch System Summary on Interactive Login
if command -v fastfetch >/dev/null 2>&1; then
    fastfetch
fi

# Initialize Starship Cross-Shell Prompt
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi
