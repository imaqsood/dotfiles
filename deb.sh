#!/bin/bash

sudo apt-get update

### remove pkg
sudo apt-get remove --assume-yes 'vim*' >/dev/null 2>&1
sudo apt-get remove docker docker-engine docker.io containerd runc >/dev/null 2>&1

### Default default
sudo apt-get update && sudo apt-get install -y ca-certificates curl gnupg gnupg2

### Keys
# node
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
# githubcli
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo gpg --dearmor --yes -o /usr/share/keyrings/githubcli-archive-keyring.gpg
# rvm
curl -sSL https://rvm.io/mpapis.asc | gpg --import -

#
gpg2 --recv-keys \
409B6B1796C275462A1703113804BB82D39DC0E3 \
7D2BAF1CF37B13E2069D6956105BD0E739499BDB
