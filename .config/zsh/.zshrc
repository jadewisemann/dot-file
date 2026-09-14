if [[ -r /opt/homebrew/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh ]]; then
    source /opt/homebrew/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh
elif [[ -r /usr/local/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh ]]; then
    source /usr/local/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh
fi

if command -v lsd >/dev/null 2>&1; then
    alias ls='lsd'
    alias l='lsd -l'
    alias la='lsd -a'
    alias lla='lsd -la'
    alias lt='lsd --tree'
fi

if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi
