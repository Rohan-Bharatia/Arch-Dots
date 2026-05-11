[[ -o interactive ]] || return

export TERMINAL='kitty'
export EDITOR='nvim'
export VISUAL='nvim'
export MAKEFLAGS="-j$(nproc)"

HISTSIZE=50000
SAVEHIST=25000
HISTFILE=$HOME/.zsh_history

setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt EXTENDED_GLOB

if [[ -d /usr/share/zsh/site-functions ]] && ! (( ${fpath[(Ie)/usr/share/zsh/site-functions]} )); then
    fpath+=/usr/share/zsh/site-functions
fi

autoload -Uz compinit
autoload -Uz history-search-end
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh-24) ]]; then
    compinit -C
else
    compinit
    touch "${ZDOTDIR:-$HOME}/.zcompdump"
fi

zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

setopt correct
setopt correct_all

bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward

bindkey -v
export KEYTIMEOUT=40

autoload -U edit-command-line
zle -N edit-command-line
bindkey -M vicmd v edit-command-line

autoload -U history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "${terminfo[kcuu1]:-^[[A}" history-beginning-search-backward-end
bindkey "${terminfo[kcud1]:-^[[B}" history-beginning-search-forward-end

setopt INTERACTIVE_COMMENTS
setopt GLOB_DOTS
setopt NO_CASE_GLOB
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS

alias ls='ls --color=auto'
alias la='ls -A'
alias ll='ls -alF'
alias l='ls -CF'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -I'
alias ln='ln -v'
alias disk_usage='sudo btrfs filesystem usage /'
alias df='df -hT'
alias fastfetch='fastfetch --config ~/.config/fastfetch/config.jsonc --file $HOME/.local/fastfetch/lunar-landing.txt'
if command -v eza >/dev/null; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza --icons --group-directories-first -l --git'
    alias la='eza --icons --group-directories-first -la --git'
    alias lt='eza --icons --group-directories-first --tree --level=2'
else
    alias ls='ls --color=auto'
    alias ll='ls -lh'
    alias la='ls -A'
fi
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias ncdu='gdu'


sudo() {
    if [[ "$1" == "nvim" ]]; then
        shift
        if [[ $# -eq 0 ]]; then
            echo "Error: sudoedit requires a filename."
            return 1
        fi
        command sudoedit "$@"
    else
        command sudo "$@"
    fi
}

function yazi() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

mkcd() {
    mkdir -p "$1" && cd "$1"
}

pkg_hogs_all() {
    expac '%m\t%n' | sort -rn | head -n "${1:-20}" | numfmt --to=iec-i --suffix=B --field=1
}

pkg_hogs() {
    # pacman -Qeq lists explicit names -> expac reads from stdin (-)
    pacman -Qeq | expac '%m\t%n' - | sort -rn | head -n "${1:-20}" | numfmt --to=iec-i --suffix=B --field=1
}

pkg_new() {
    expac --timefmt='%Y-%m-%d %T' '%l\t%n' | sort -r | head -n "${1:-20}"
}

pkg_old() {
    expac --timefmt='%Y-%m-%d %T' '%l\t%n' | sort | head -n "${1:-20}"
}

STARSHIP_CACHE="$HOME/.starship-init.zsh"
STARSHIP_BIN="$(command -v starship)"
if [[ -n "$STARSHIP_BIN" ]]; then
    if [[ ! -f "$STARSHIP_CACHE" || "$STARSHIP_BIN" -nt "$STARSHIP_CACHE" ]]; then
    starship init zsh --print-full-init >! "$STARSHIP_CACHE"
    fi
    source "$STARSHIP_CACHE"
fi
FZF_CACHE="$HOME/.fzf-init.zsh"
FZF_BIN="$(command -v fzf)"
if [[ -n "$FZF_BIN" ]];
then
if $FZF_BIN --zsh > /dev/null 2>&1; then
        if [[ ! -f "$FZF_CACHE" || "$FZF_BIN" -nt "$FZF_CACHE" ]]; then
        $FZF_BIN --zsh >! "$FZF_CACHE"
        fi
        source "$FZF_CACHE"
    else
        if [[ -f $HOME/.fzf.zsh ]]; then
            source $HOME/.fzf.zsh
        fi
    fi
fi
if [ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=60'
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fi
if [[ -f "/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source "/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
unset STARSHIP_CACHE STARSHIP_BIN FZF_CACHE FZF_BIN
if [[ -z "$DISPLAY" ]] && [[ "$(tty)" == "/dev/tty1" ]]; then
    if uwsm check may-start; then
    exec uwsm start hyprland.desktop
fi
