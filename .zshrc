export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="af-magic" # set by `omz`

plugins=(git zsh-fzf-history-search z zsh-syntax-highlighting zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh
source $HOME/.cargo/env


# MACOS envs

# This is for installation of mysql-client package without mysql packge only
# If user chooses to install mysql package, remove mysql-client package and disable this line
export PATH="/usr/local/opt/mysql-client/bin:$PATH"
# use brew for zig 
# export PATH="/Users/anlap/Vendors/zig:$PATH"
export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
export PATH="$PATH:${HOME}/go/bin"

alias load-nvm="source $HOME/.nvm-loader.sh"

[[ $commands[kubectl] ]] && source <(kubectl completion zsh)
[[ $commands[gh] ]] && source <(gh completion --shell zsh)
# [[ $commands[helm] ]] && source <(helm completion zsh)
# [[ $commands[docker] ]] && source <(docker completion zsh)

export LANG=en_US.UTF-8

if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vi'
else
  export EDITOR='nvim'
  export VISUAL='nvim'
fi


alias py=python
alias claer=clear
alias ckear=clear
alias ckaer=clear

alias k=kubectl
alias kdev='kubectl --kubeconfig="$HOME/.kube/config.dev"'

[ -f "/Users/anlap/.ghcup/env" ] && source "/Users/anlap/.ghcup/env" # ghcup-env
