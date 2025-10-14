# TODO: Make this config machine diagnostic

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="af-magic" # set by `omz`

plugins=(git z zsh-autosuggestions zsh-syntax-highlighting)

export LANG=en_US.UTF-8

if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vi'
else
  export EDITOR='nvim'
  export VISUAL='nvim'
fi

source $ZSH/oh-my-zsh.sh
source $HOME/.cargo/env

# This will be of specific computer
export PATH=$HOME/go/bin:$PATH
export PATH=$HOME/.local/bin:$PATH
export PATH=$HOME/.local/share/JetBrains/Toolbox/scripts:$PATH
export PATH=$HOME/dev/Vendors/zig-x86_64-linux-0.15.1:$PATH

alias dfs='git --git-dir=$HOME/dev/dotfiles --work-tree=$HOME'

# TODO: bat is different name on different OS, make this OS diagnostic
alias cat=bat

autoload -U +X bashcompinit && bashcompinit

[[ $commands[starship] ]] && eval "$(starship init zsh)"
[[ $commands[atuin]    ]] && eval "$(atuin init zsh --disable-up-arrow)"

[[ $commands[kind]   ]] && source <(kind completion zsh)
[[ $commands[gh]     ]] && source <(gh completion --shell zsh)
[[ $commands[helm]   ]] && source <(helm completion zsh)
[[ $commands[argocd] ]] && source <(argocd completion zsh)
[[ $commands[aws]    ]] && complete -C /usr/bin/aws_completer aws

if [[ $commands[eza] ]] then
    alias l='eza --all --long --group-directories-first --binary --icons'
fi

if [[ $commands[terraform] ]] then
    alias tf=terraform
    complete -o nospace -C /usr/bin/terraform terraform
fi

if [[ $commands[kubectl] ]] then
    source <(kubectl completion zsh)
    kdo=(--dry-run=client -o=yaml)
    alias k=kubectl
fi

