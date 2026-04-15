#!/bin/bash
# =============================================================================
# bootstrap.sh — Main entry point for dotfiles setup
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/imaqsood/dotfiles/main/bootstrap.sh | bash
#   OR
#   git clone https://github.com/imaqsood/dotfiles.git ~/dev/dotfiles
#   cd ~/dev/dotfiles && ./bootstrap.sh
#
# Supports: macOS (Homebrew) and Debian/Ubuntu (apt)
# Safe to run multiple times (idempotent)
# =============================================================================

set -euo pipefail

# Resolve the directory this script lives in (handles symlinks too)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR

# Source shared utilities
source "$DOTFILES_DIR/lib/utils.sh"

# -- Preflight checks ---------------------------------------------------------

ensure_not_root

# -- Main flow ----------------------------------------------------------------

main() {
  print_banner

  local os
  os=$(detect_os)
  local arch
  arch=$(detect_arch)

  log_info "Detected OS: $os ($arch)"

  if [ "$os" = "unsupported" ]; then
    log_error "Unsupported operating system. This script supports macOS and Debian/Ubuntu."
    exit 1
  fi

  # -- Step 1: Platform-specific package installation --
  case "$os" in
    macos)
      source "$DOTFILES_DIR/install/macos.sh"
      run_macos_setup
      ;;
    debian)
      source "$DOTFILES_DIR/install/debian.sh"
      run_debian_setup
      ;;
  esac

  # -- Step 2: Cross-platform tools (oh-my-zsh, plugins, tmux, etc.) --
  source "$DOTFILES_DIR/install/common.sh"
  run_common_setup

  # -- Step 3: Create required directories --
  create_directories

  # -- Step 4: Create symlinks --
  setup_symlinks "$DOTFILES_DIR"

  # -- Step 5: Summary --
  print_summary "$os"
}

main "$@"
