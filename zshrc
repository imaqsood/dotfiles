export ZSH=$HOME/.oh-my-zsh
export DOTFILES=$HOME/maqdotfiles
export FZF_DEFAULT_COMMAND="find . -path '*/\.*' -type d -prune -o -type f -print -o -type l -print 2> /dev/null | sed s/^..//"

ZSH_THEME="robbyrussell"
ZSH_THEME="spaceship"

plugins=(
	git
	tmux
  docker
  docker-compose
	zsh-syntax-highlighting
	zsh-autosuggestions
  zsh-256color
)

source $ZSH/oh-my-zsh.sh
bindkey -v

[ -f  $DOTFILES/my_bash ] && source $DOTFILES/my_bash
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

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
