# ~/.bashrc: executed by bash(1) for non-login shells.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# History configuration
HISTCONTROL=ignoreboth
HISTSIZE=5000
HISTFILESIZE=10000
shopt -s histappend

# Update window size after each command
shopt -s checkwinsize

# Enable ** for recursive globbing (useful for modern scripting)
shopt -s globstar

# Make less more friendly for non-text input files
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Enable color support for ls and grep
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Developer-friendly aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias up='cd ..'

# Load custom aliases if present
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Enable programmable completion
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# NVM Configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
export NODE_EXTRA_CA_CERTS="/usr/local/share/ca-certificates/zscalar.crt"

# Git completion and prompt
if [ -f /usr/share/bash-completion/completions/git ]; then
    source /usr/share/bash-completion/completions/git
elif [ -f /etc/bash_completion.d/git ]; then
    source /etc/bash_completion.d/git
elif [ -f ~/.git-completion.bash ]; then
    source ~/.git-completion.bash
fi

if [ -f /usr/share/git-core/contrib/completion/git-prompt.sh ]; then
    source /usr/share/git-core/contrib/completion/git-prompt.sh
elif [ -f /usr/lib/git-core/git-sh-prompt ]; then
    source /usr/lib/git-core/git-sh-prompt
elif [ -f ~/.git-prompt.sh ]; then
    source ~/.git-prompt.sh
fi

# Git prompt configuration
GIT_PS1_SHOWDIRTYSTATE=1
GIT_PS1_SHOWSTASHSTATE=1
GIT_PS1_SHOWUNTRACKEDFILES=1
GIT_PS1_SHOWUPSTREAM="auto"
GIT_PS1_SHOWCOLORHINTS=1

# Color definitions
COLOR_RESET='\[\033[0m\]'
COLOR_USER='\[\033[01;32m\]'      # Green
COLOR_DIR='\[\033[01;34m\]'       # Blue
COLOR_GIT='\[\033[01;33m\]'       # Yellow
COLOR_TIME='\[\033[01;35m\]'      # Magenta
COLOR_PROMPT='\[\033[01;37m\]'    # White

# Enhanced PS1 with directory, git status, and time
PS1="${COLOR_USER}\u@\h${COLOR_RESET}:${COLOR_DIR}\w${COLOR_RESET}"
PS1="${PS1}${COLOR_GIT}\$(__git_ps1 ' (%s)')${COLOR_RESET}"
PS1="${PS1} ${COLOR_TIME}[\@]${COLOR_RESET}${COLOR_PROMPT}\$${COLOR_RESET} "

# Syntax highlighting for common tools (built-in color support)
alias diff='diff --color=auto'
alias ip='ip -color=auto'

# Quick Git aliases for developers
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate --all'
alias gd='git diff'

# Show Git log with colors
export GIT_LOG_COLOR='always'
