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
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias h='cd ~'
alias ..='cd ..'
alias .2='cd ../../'
alias .3='cd ../../../'
alias .4='cd ../../../../'
alias .5='cd ../../../../..'
alias d='docker '
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
alias vscodeusers='ps -eo user:20,pid,pcpu,cmd:256 | grep vscode | grep -v grep | tr -s " " | cut -d " " -f1,2,3 | less'
# Feed it emails with heredoc formatting
alias extract_emails="grep -Eioh '([[:alnum:]_.-]+@[[:alnum:]_.-]+?\.[[:alpha:].]{2,6})'"
# HPC related Aliases
alias ml='module'
alias mp='module purge'
alias mav='module avail'
alias squeuel='squeue --format="%.18i %.18P %.45j %.8T %.10M %.9l %.6D %R" --me'
alias ssh-nopubkey='ssh -o PubkeyAuthentication=no'
