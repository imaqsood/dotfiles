FROM ubuntu:latest

ARG USER_ID
ARG GROUP_ID

RUN addgroup --gid $GROUP_ID maqsood
RUN adduser --disabled-password --gecos '' --uid $USER_ID --gid $GROUP_ID maqsood

ENV HOME /home/maqsood
ENV DEBIAN_FRONTEND noninteractove

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
  wget \
  curl \
  git  \
  vifm \
  zsh  \
  apt-transport-https \
  ca-certificates \
  gnupg \
  lsb-release \
  fonts-firacode \
  mlocate \
  net-tools \
  openssh-server \
  htop \
  fd-find \
  silversearcher-ag \
  ripgrep \
  tmux \
  vim-athena \
  neovim \
  nodejs \
  yarn

RUN sudo apt-get install -y gnupg gnupg2

RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

RUN git clone https://github.com/spaceship-prompt/spaceship-prompt.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/spaceship-prompt --depth=1 && \
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting && \
    git clone https://github.com/chrissicool/zsh-256color ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-256color && \
    git clone https://github.com/gpakosz/.tmux.git $HOME/.tmux && \
    git clone https://github.com/VundleVim/Vundle.vim.git $HOME/.vim/bundle/Vundle.vim && \
    git clone https://github.com/junegunn/fzf.git $HOME/.fzf --depth 1


RUN  gpg2 --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB && \
  curl -sSL https://rvm.io/mpapis.asc | gpg --import - && \
  curl -sSL https://rvm.io/pkuczynski.asc | gpg --import - && \
  curl -sSL https://get.rvm.io | bash -s stable


# RUN rvm install 3.0 && rvm use 3.0

RUN ssh-keygen -t rsa -b 4096 -C 'maqsood.ulde@gmail.com' -f $HOME/.ssh/git -N ''
RUN ssh-keygen -t rsa -b 4096 -C 'maqsood.ulde@gmail.com' -f $HOME/.ssh/id_rsa -N ''


COPY . $HOME/dotfiles

RUN chown -R maqsood:maqsood $HOME

RUN dotfiles/docinstall

USER $USER_ID

CMD bash
