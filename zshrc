# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH=$HOME/.oh-my-zsh
export DOTFILES=$HOME/maqdotfiles
export FZF_DEFAULT_COMMAND="find . -path '*/\.*' -type d -prune -o -type f -print -o -type l -print 2> /dev/null | sed s/^..//"
export ZPLUG_HOME=$HOME/.zplug


# ZSH_THEME="robbyrussell"
# ZSH_THEME="spaceship"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  fzf
  git
  tmux
  docker
  docker-compose
  zsh-syntax-highlighting
  zsh-autosuggestions
  zsh-256color
)

source $HOME/.zplug/init.zsh
source $ZSH/oh-my-zsh.sh
bindkey -v

[ -f  $DOTFILES/my_bash ] && source $DOTFILES/my_bash
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh


alias cop="git add -N .; git diff --name-only | xargs rubocop $@"
alias ls="colorls"

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
