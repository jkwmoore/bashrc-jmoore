#!/bin/bash
## See https://linuxhandbook.com/run-alias-as-sudo/
alias sudo='sudo '
alias ports='ss -plunt'
alias chown='chown --preserve-root'
alias chmod='chmod --preserve-root'
alias chgrp='chgrp --preserve-root'
## Usage: nocomment /etc/squid.conf
alias nocomment="grep -Ev '''^(#|$)'''"
alias bashrc="vim ~/.bashrc && source ~/.bashrc"
## Colorize the ls output ##
alias ls='ls --color=auto'
## Use a long listing format ##
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias tree="find . -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'"
alias ssh-key-check='for file in /etc/ssh/*sa_key.pub; do ssh-keygen -lf "$file"; done'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias ..='cd ..'
alias .2='cd ../../'
alias .3='cd ../../../'
alias .4='cd ../../../../'
alias .5='cd ../../../../..'
alias dps='docker ps'
alias docker-rm-all='docker rm -f $(docker ps -aq)'
alias docker-rmi-all='docker rmi -f $(docker images -aq)'
alias docker-stop-all='docker stop $(docker ps -aq)'
alias docker-compose-up='docker-compose up --build --force-recreate --remove-orphans'
alias g='git'
alias gr='git rm -rf'
alias gs='git status'
alias ga='g add'
alias gc='git commit -m'
alias gl='git log'
