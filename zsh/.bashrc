[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fastfetch='fastfetch --config ~/.config/fastfetch/config.jsonc --file ~/Pictures/fetch-logo.txt'
PS1='[\u@\h \W]\$ '

eval "$(ssh-agent -s)" > ssh.txt
