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

LOCAL_MACHINE_DIR="$HOME/.local_machine"

if [[ -d $LOCAL_MACHINE_DIR ]]; then
  for f in $LOCAL_MACHINE_DIR/*.(sh|zsh)(N); do
    source "$f"
  done
fi

alias dfs='git --git-dir=$HOME/dev/dotfiles --work-tree=$HOME'

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

