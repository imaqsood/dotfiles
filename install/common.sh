#!/bin/bash
# =============================================================================
# common.sh — Cross-platform setup (oh-my-zsh, plugins, tmux, mise, etc.)
# Called by bootstrap.sh — do not run directly
# =============================================================================

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$DOTFILES_DIR/lib/utils.sh"

# -- Oh My Zsh ----------------------------------------------------------------

install_oh_my_zsh() {
  log_step "Oh My Zsh"

  if [ -d "$HOME/.oh-my-zsh" ]; then
    log_success "Oh My Zsh already installed"
  else
    log_info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    log_success "Oh My Zsh installed"
  fi
}

# -- Zplug (zsh plugin manager) -----------------------------------------------

install_zplug() {
  log_step "Zplug"

  if [ -d "$HOME/.zplug" ]; then
    log_success "Zplug already installed"
  else
    log_info "Installing Zplug..."
    curl -sL --proto-redir -all,https \
      https://raw.githubusercontent.com/zplug/zplug/master/installer.zsh | zsh
    log_success "Zplug installed"
  fi
}

# -- Powerlevel10k Theme ------------------------------------------------------

install_powerlevel10k() {
  log_step "Powerlevel10k"

  local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

  if [ -d "$p10k_dir" ]; then
    log_success "Powerlevel10k already installed"
  else
    log_info "Installing Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
    log_success "Powerlevel10k installed"
  fi
}

# -- Zsh Plugins (standalone clones for oh-my-zsh custom) ---------------------

install_zsh_plugins() {
  log_step "Zsh plugins"

  local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  # plugin_name:repo_url pairs
  local plugins=(
    "zsh-autosuggestions:https://github.com/zsh-users/zsh-autosuggestions"
    "zsh-syntax-highlighting:https://github.com/zsh-users/zsh-syntax-highlighting"
    "zsh-history-substring-search:https://github.com/zsh-users/zsh-history-substring-search"
    "zsh-256color:https://github.com/chrissicool/zsh-256color"
  )

  for entry in "${plugins[@]}"; do
    local plugin="${entry%%:*}"
    local repo="${entry#*:}"
    local dest="$custom/plugins/$plugin"
    if [ -d "$dest" ]; then
      log_success "$plugin already installed"
    else
      log_info "Installing $plugin..."
      git clone --depth=1 "$repo" "$dest"
      log_success "$plugin installed"
    fi
  done
}

# -- tmux (gpakosz/.tmux) -----------------------------------------------------

install_tmux_config() {
  log_step "tmux (gpakosz/.tmux)"

  if [ -d "$HOME/.tmux" ]; then
    log_success "gpakosz/.tmux already cloned"
  else
    log_info "Cloning gpakosz/.tmux..."
    git clone https://github.com/gpakosz/.tmux.git "$HOME/.tmux"
    log_success "gpakosz/.tmux cloned"
  fi

  # Symlink the base tmux.conf
  if [ -f "$HOME/.tmux/.tmux.conf" ]; then
    ln -sf "$HOME/.tmux/.tmux.conf" "$HOME/.tmux.conf"
    log_success "Linked ~/.tmux.conf -> ~/.tmux/.tmux.conf"
  fi
}

# -- FZF (fuzzy finder key bindings & completion) -----------------------------

setup_fzf() {
  log_step "FZF"

  # On macOS, fzf is installed via Homebrew and needs key bindings setup
  if [ -f "$HOME/.fzf.zsh" ]; then
    log_success "FZF already configured"
    return
  fi

  # If installed via Homebrew
  if [ -d "$(brew --prefix 2>/dev/null)/opt/fzf" ]; then
    "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
    log_success "FZF configured (Homebrew)"
    return
  fi

  # If not installed, clone and install
  if [ ! -d "$HOME/.fzf" ]; then
    log_info "Installing FZF..."
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    "$HOME/.fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
    log_success "FZF installed and configured"
  else
    "$HOME/.fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
    log_success "FZF configured"
  fi
}

# -- mise (unified version manager) -------------------------------------------

setup_mise() {
  log_step "mise (version manager)"

  if ! command_exists mise; then
    log_warn "mise not found — install it via platform script first"
    return
  fi

  log_success "mise is available"
  log_info "Activate mise by running: eval \"\$(mise activate zsh)\""
  log_info "Install runtimes: mise use --global node@lts ruby@latest python@latest"
}

# -- Neovim (lazy.nvim bootstraps from init.lua) ------------------------------

setup_neovim() {
  log_step "Neovim"

  if command_exists nvim; then
    log_success "Neovim is installed"
    log_info "lazy.nvim will auto-install plugins on first launch"
  else
    log_warn "Neovim not found — install it via platform script first"
  fi
}

# -- GitHub Copilot CLI -------------------------------------------------------

setup_gh_copilot() {
  log_step "GitHub Copilot CLI"

  if ! command_exists gh; then
    log_warn "GitHub CLI (gh) not found — skipping Copilot setup"
    return
  fi

  if gh extension list 2>/dev/null | grep -q "copilot"; then
    log_success "GitHub Copilot CLI extension already installed"
  else
    log_info "Installing GitHub Copilot CLI extension..."
    gh extension install github/gh-copilot 2>/dev/null || log_warn "Could not install gh-copilot (may need auth first)"
  fi
}

# -- Main (called from bootstrap.sh) -----------------------------------------

run_common_setup() {
  install_oh_my_zsh
  install_zplug
  install_powerlevel10k
  install_zsh_plugins
  install_tmux_config
  setup_fzf
  setup_mise
  setup_neovim
  setup_gh_copilot
}

# Allow running standalone for testing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_common_setup
fi
