#!/bin/bash
# =============================================================================
# debian.sh — Debian/Ubuntu-specific setup (apt packages, manual installs)
# Called by bootstrap.sh — do not run directly
# =============================================================================

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$DOTFILES_DIR/lib/utils.sh"

ARCH="$(detect_arch)"

# -- Helper: install from GitHub release binary --------------------------------

install_github_release() {
  local cmd="$1"       # command name to check
  local repo="$2"      # GitHub repo (owner/name)
  local pattern="$3"   # filename pattern for the binary asset

  if command_exists "$cmd"; then
    log_success "$cmd already installed"
    return
  fi

  log_info "Installing $cmd from $repo..."
  local latest
  latest=$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" | jq -r '.tag_name')
  latest="${latest#v}"  # strip leading 'v'

  local url="https://github.com/$repo/releases/download/v${latest}/${pattern}"
  url=$(echo "$url" | sed "s/{VERSION}/$latest/g")

  local tmpdir
  tmpdir=$(mktemp -d)

  if [[ "$pattern" == *.tar.gz ]]; then
    curl -fsSL "$url" | tar xz -C "$tmpdir"
    # Find the binary (usually the command name)
    local bin
    bin=$(find "$tmpdir" -type f -name "$cmd" | head -1)
    if [ -z "$bin" ]; then
      bin=$(find "$tmpdir" -type f -executable | head -1)
    fi
    sudo install -m 755 "$bin" "/usr/local/bin/$cmd"
  elif [[ "$pattern" == *.deb ]]; then
    curl -fsSL "$url" -o "$tmpdir/pkg.deb"
    sudo dpkg -i "$tmpdir/pkg.deb" || sudo apt-get install -f -y
  elif [[ "$pattern" == *.zip ]]; then
    curl -fsSL "$url" -o "$tmpdir/pkg.zip"
    unzip -o "$tmpdir/pkg.zip" -d "$tmpdir"
    local bin
    bin=$(find "$tmpdir" -type f -name "$cmd" | head -1)
    if [ -z "$bin" ]; then
      bin=$(find "$tmpdir" -type f -executable | head -1)
    fi
    sudo install -m 755 "$bin" "/usr/local/bin/$cmd"
  fi

  rm -rf "$tmpdir"
  log_success "$cmd installed"
}

# -- Core APT Packages --------------------------------------------------------

install_apt_packages() {
  log_step "Installing core APT packages"

  sudo apt-get update -qq

  local packages=(
    # Build essentials
    build-essential
    gcc
    g++
    make
    pkg-config
    libssl-dev
    libffi-dev

    # Core tools
    git
    curl
    wget
    jq
    tree
    unzip
    zip
    software-properties-common
    apt-transport-https
    ca-certificates
    gnupg
    lsb-release

    # Shell & terminal
    zsh
    tmux

    # Editors
    neovim

    # Network
    net-tools
    openssh-server
    openssh-client

    # System monitoring
    htop

    # Search (available in apt)
    ripgrep
    fd-find
    fzf

    # Misc
    mlocate
    toilet
    fonts-firacode
  )

  sudo apt-get install -y "${packages[@]}"
  log_success "Core APT packages installed"

  # fd-find installs as 'fdfind', create symlink to 'fd'
  if command_exists fdfind && ! command_exists fd; then
    sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
    log_success "Created fd symlink for fdfind"
  fi

  # bat might install as 'batcat' on older Ubuntu
  if command_exists batcat && ! command_exists bat; then
    sudo ln -sf "$(which batcat)" /usr/local/bin/bat
    log_success "Created bat symlink for batcat"
  fi
}

# -- GitHub CLI ---------------------------------------------------------------

install_gh_cli() {
  log_step "GitHub CLI"

  if command_exists gh; then
    log_success "GitHub CLI already installed"
    return
  fi

  log_info "Installing GitHub CLI..."
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt-get update -qq
  sudo apt-get install -y gh
  log_success "GitHub CLI installed"
}

# -- Docker -------------------------------------------------------------------

install_docker() {
  log_step "Docker"

  if command_exists docker; then
    log_success "Docker already installed"
    return
  fi

  log_info "Installing Docker..."
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker "$USER"
  log_success "Docker installed (logout/login for group to take effect)"
}

# -- Neovim (latest via PPA if apt version is old) ----------------------------

install_neovim_latest() {
  # Check if neovim version is >= 0.9 (needed for lazy.nvim)
  local nvim_version
  nvim_version=$(nvim --version 2>/dev/null | head -1 | grep -oP '\d+\.\d+' || echo "0.0")

  if awk "BEGIN {exit !($nvim_version >= 0.9)}"; then
    log_success "Neovim $nvim_version is recent enough"
    return
  fi

  log_info "Installing latest Neovim from GitHub releases..."
  if [ "$ARCH" = "amd64" ]; then
    install_github_release "nvim" "neovim/neovim" "nvim-linux-x86_64.tar.gz"
  else
    install_github_release "nvim" "neovim/neovim" "nvim-linux-arm64.tar.gz"
  fi
}

# -- Modern CLI Tools (not in apt) -------------------------------------------

install_modern_cli_tools() {
  log_step "Installing modern CLI tools"

  local deb_arch
  if [ "$ARCH" = "amd64" ]; then
    deb_arch="amd64"
  else
    deb_arch="arm64"
  fi

  # -- eza (ls replacement) --
  if ! command_exists eza; then
    log_info "Installing eza..."
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
      | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
      | sudo tee /etc/apt/sources.list.d/gierens.list > /dev/null
    sudo apt-get update -qq
    sudo apt-get install -y eza
    log_success "eza installed"
  else
    log_success "eza already installed"
  fi

  # -- bat (cat replacement) --
  if ! command_exists bat && ! command_exists batcat; then
    sudo apt-get install -y bat 2>/dev/null || true
  fi
  log_success "bat available"

  # -- git-delta (diff pager) --
  install_github_release "delta" "dandavison/delta" \
    "git-delta_{VERSION}_${deb_arch}.deb"

  # -- lazygit (git TUI) --
  install_github_release "lazygit" "jesseduffield/lazygit" \
    "lazygit_{VERSION}_Linux_${ARCH}.tar.gz"

  # -- lazydocker (docker TUI) --
  install_github_release "lazydocker" "jesseduffield/lazydocker" \
    "lazydocker_{VERSION}_Linux_${ARCH}.tar.gz"

  # -- yazi (file manager) --
  install_github_release "yazi" "sxyazi/yazi" \
    "yazi-$(uname -m)-unknown-linux-gnu.zip"

  # -- k9s (kubernetes TUI) --
  install_github_release "k9s" "derailed/k9s" \
    "k9s_Linux_${deb_arch}.tar.gz"

  # -- bottom (system monitor) --
  install_github_release "btm" "ClementTsang/bottom" \
    "bottom_${deb_arch}.deb"

  # -- dust (du replacement) --
  install_github_release "dust" "bootandy/dust" \
    "dust-v{VERSION}-$(uname -m)-unknown-linux-gnu.tar.gz"

  # -- duf (df replacement) --
  install_github_release "duf" "muesli/duf" \
    "duf_{VERSION}_linux_${deb_arch}.deb"

  # -- procs (ps replacement) --
  install_github_release "procs" "dalance/procs" \
    "procs-v{VERSION}-$(uname -m)-linux.zip"

  # -- sd (sed replacement) --
  install_github_release "sd" "chmln/sd" \
    "sd-v{VERSION}-$(uname -m)-unknown-linux-gnu.tar.gz"

  # -- hyperfine (benchmarking) --
  install_github_release "hyperfine" "sharkdp/hyperfine" \
    "hyperfine_{VERSION}_${deb_arch}.deb"

  # -- tokei (code statistics) --
  install_github_release "tokei" "XAMPPRocky/tokei" \
    "tokei-$(uname -m)-unknown-linux-gnu.tar.gz"
}

# -- Tools via install scripts ------------------------------------------------

install_script_tools() {
  log_step "Installing tools via official install scripts"

  # -- Starship prompt --
  if ! command_exists starship; then
    log_info "Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
    log_success "Starship installed"
  else
    log_success "Starship already installed"
  fi

  # -- Atuin (shell history) --
  if ! command_exists atuin; then
    log_info "Installing Atuin..."
    curl -sSf https://setup.atuin.sh | bash
    log_success "Atuin installed"
  else
    log_success "Atuin already installed"
  fi

  # -- Zoxide (smart cd) --
  if ! command_exists zoxide; then
    log_info "Installing Zoxide..."
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    log_success "Zoxide installed"
  else
    log_success "Zoxide already installed"
  fi

  # -- mise (version manager) --
  if ! command_exists mise; then
    log_info "Installing mise..."
    curl https://mise.run | sh
    log_success "mise installed"
  else
    log_success "mise already installed"
  fi
}

# -- Nerd Fonts ---------------------------------------------------------------

install_fonts() {
  log_step "Installing custom fonts"

  local font_dir="$HOME/.local/share/fonts"
  local src_dir="$DOTFILES_DIR/assets/fonts"
  mkdir -p "$font_dir"

  if [ -d "$src_dir" ]; then
    for font in "$src_dir"/*.ttf "$src_dir"/*.otf; do
      [ -f "$font" ] || continue
      local fname
      fname=$(basename "$font")
      if [ ! -f "$font_dir/$fname" ]; then
        cp "$font" "$font_dir/"
        log_success "Installed font: $fname"
      else
        log_success "Font already installed: $fname"
      fi
    done
    fc-cache -f "$font_dir" 2>/dev/null || true
  fi

  # Install JetBrains Mono Nerd Font
  if [ ! -f "$font_dir/JetBrainsMonoNerdFont-Regular.ttf" ]; then
    log_info "Installing JetBrains Mono Nerd Font..."
    local tmpdir
    tmpdir=$(mktemp -d)
    curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" \
      -o "$tmpdir/JetBrainsMono.zip"
    unzip -o "$tmpdir/JetBrainsMono.zip" -d "$font_dir" '*.ttf'
    rm -rf "$tmpdir"
    fc-cache -f "$font_dir"
    log_success "JetBrains Mono Nerd Font installed"
  else
    log_success "JetBrains Mono Nerd Font already installed"
  fi
}

# -- Set Default Shell --------------------------------------------------------

set_default_shell() {
  log_step "Setting default shell to zsh"

  if [ "$SHELL" = "$(which zsh)" ]; then
    log_success "Default shell is already zsh"
    return
  fi

  local zsh_path
  zsh_path=$(which zsh)

  # Ensure zsh is in /etc/shells
  if ! grep -q "$zsh_path" /etc/shells; then
    echo "$zsh_path" | sudo tee -a /etc/shells
  fi

  chsh -s "$zsh_path"
  log_success "Default shell set to zsh (takes effect on next login)"
}

# -- Main (called from bootstrap.sh) -----------------------------------------

run_debian_setup() {
  log_step "Starting Debian/Ubuntu setup"

  install_apt_packages
  install_neovim_latest
  install_gh_cli
  install_docker
  install_modern_cli_tools
  install_script_tools
  install_fonts
  set_default_shell
}

# Allow running standalone for testing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_debian_setup
fi
