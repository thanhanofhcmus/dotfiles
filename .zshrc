export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="af-magic" # set by `omz`

plugins=(git z zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh
# source $HOME/.cargo/env

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

alias dotfiles='git --git-dir=$HOME/dev/dotfiles --work-tree=$HOME'

alias l='exa --all --long --group-directories-first --binary --icons'
alias k=kubectl
alias cat=bat

export PATH=$HOME/.local/bin:$PATH
export PATH=$HOME/.local/share/JetBrains/Toolbox/scripts:$PATH

eval "$(starship init zsh)"
