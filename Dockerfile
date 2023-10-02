FROM ubuntu:latest

ARG USER_ID
ARG GROUP_ID

RUN addgroup --gid $GROUP_ID maqsood
RUN adduser --disabled-password --gecos '' --uid $USER_ID --gid $GROUP_ID maqsood

ENV HOME /home/maqsood
ENV DEBIAN_FRONTEND noninteractove

SHELL ["/bin/bash", "-c"]

RUN mkdir -p $HOME
RUN mkdir -p $HOME/dotfiles
RUN mkdir -p $HOME/.config/nvim
RUN mkdir -p $HOME/.ssh
WORKDIR $HOME

RUN apt-get update && apt-get install sudo

RUN DEBIAN_FRONTEND=noninteractove apt-get install --assume-yes tzdata
RUN unlink /etc/localtime && ln -s /usr/share/zoneinfo/Asia/Kolkata /etc/localtime

RUN curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -

RUN sudo apt-get remove --assume-yes 'vim*' && \
  sudo apt-get update && \
  sudo apt-get install --assume-yes \
  wget curl git vifm zsh apt-transport-https ca-certificates \
  lsb-release fonts-firacode mlocate net-tools openssh-server \
  htop fzf fd-find silversearcher-ag ripgrep tmux vim-athena \
  neovim nodejs yarn gnupg gnupg2 autoconf patch build-essential \
  rustc libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libgmp-dev \
  libncurses5-dev libffi-dev libgdbm6 libgdbm-dev libdb-dev uuid-dev fd

RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && \
    sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

RUN git clone https://github.com/spaceship-prompt/spaceship-prompt.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/spaceship-prompt --depth=1 && \
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting && \
    git clone https://github.com/chrissicool/zsh-256color ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-256color && \
    git clone https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k --depth=1 && \
    git clone https://github.com/gpakosz/.tmux.git $HOME/.tmux && \
    git clone https://github.com/junegunn/fzf.git $HOME/.fzf --depth 1 && \
    git clone https://github.com/rbenv/rbenv.git $HOME/.rbenv && echo 'eval "$($HOME/.rbenv/bin/rbenv init - bash)"' >> $HOME/.bashrc && source $HOME/.bashrc && \
    git clone https://github.com/rbenv/ruby-build.git "$($HOME/.rbenv/bin/rbenv root)"/plugins/ruby-build  && \
    git clone https://github.com/imaqsood/dotfiles.git $HOME/dotfiles &&  \
    $HOME/.rbenv/plugins/ruby-build/install.sh

RUN $HOME/.rbenv/bin/rbenv install 3.2.2

RUN echo -ne '\n' |  nvim +PlugInstall +qall

RUN ln -sf ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/spaceship-prompt/spaceship.zsh-theme ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/spaceship.zsh-theme -f && \
    ln -sf $HOME/dotfiles/zshrc $HOME/.zshrc && \
    ln -sf $HOME/dotfiles/tmux.conf $HOME/.tmux.conf && \
    ln -sf $HOME/dotfiles/tmux.conf.local $HOME/.tmux.conf.local && \
    ln -sf $HOME/dotfiles/ssh_config $HOME/.ssh/config && \
    ln -sf $HOME/dotfiles/vimrc_v1 $HOME/.config/nvim/init.vim && \
    ln -sf $HOME/dotfiles/vimrc_v1 $HOME/.vimrc && \
    ln -sf $HOME/dotfiles/inputrc $HOME/.inputrc && \
    ln -sf $HOME/dotfiles/editrc $HOME/.editrc && \
    ln -sf $HOME/dotfiles/p10k.zsh $HOME/.p10k.zsh


RUN ssh-keygen -t rsa -b 4096 -C 'maqsood.ulde@gmail.com' -f $HOME/.ssh/git -N ''
RUN ssh-keygen -t rsa -b 4096 -C 'maqsood.ulde@gmail.com' -f $HOME/.ssh/id_rsa -N ''


RUN chown -R maqsood:maqsood $HOME
RUN echo 'maqsood ALL = NOPASSWD: ALL' >  /etc/sudoers


# RUN dotfiles/docinstall

USER $USER_ID

CMD bash
