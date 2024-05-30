export ZSH=$HOME/.oh-my-zsh
export DOTFILES=$HOME/maqdotfiles
export FZF_DEFAULT_COMMAND="find . -path '*/\.*' -type d -prune -o -type f -print -o -type l -print 2> /dev/null | sed s/^..//"
export ZPLUG_HOME=$HOME/.zplug

# need to be loaded before theme and zplug
source $ZSH/oh-my-zsh.sh

bindkey -v

export ZSH_THEME="powerlevel10k/powerlevel10k"
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


source $HOME/.zplug/init.zsh

zplug "romkatv/powerlevel10k", as:theme, depth:1
zplug "zsh-users/zsh-autosuggestions"
zplug "zsh-users/zsh-syntax-highlighting", defer:2
zplug "zsh-users/zsh-history-substring-search"
zplug "chrissicool/zsh-256color"
zplug "plugins/git",   from:oh-my-zsh
zplug "plugins/git",   from:oh-my-zsh
zplug "plugins/tmux",   from:oh-my-zsh
zplug "plugins/docker",   from:oh-my-zsh
zplug "plugins/fzf",   from:oh-my-zsh
zplug "plugins/ruby",   from:oh-my-zsh
zplug "plugins/docker-compose",   from:oh-my-zsh

zplug load

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

alias cop="git add -N .; git diff --name-only | xargs rubocop $@"
alias ls="colorls"
alias branches="for branch in \$(git branch --format='%(refname:short)' $@); do echo \"\$branch -> \$(git describe --tags --abbrev=0 \$branch)\"; done"

# rvm
if [[ -d $HOME/.rvm ]]; then
  export PATH="$PATH:$HOME/.rvm/bin"
  [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
fi

# pyenv
if [[ -d $HOME/.pyenv ]]; then
  export PATH="$HOME/.pyenv/bin:$PATH"
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
fi

eval "$(rbenv init - zsh)"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
export PATH="/opt/homebrew/opt/curl/bin:$PATH"


[[ ! -f ~/.env ]] || source ~/.env

export PATH="$HOME/dev:$PATH"

export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"

export GIT_EDITOR=nvim
