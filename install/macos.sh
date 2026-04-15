#!/bin/bash
# =============================================================================
# macos.sh — macOS-specific setup (Homebrew, packages, system defaults)
# Called by bootstrap.sh — do not run directly
# =============================================================================

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$DOTFILES_DIR/lib/utils.sh"

# -- Xcode Command Line Tools ------------------------------------------------

install_xcode_cli() {
  log_step "Xcode Command Line Tools"

  if xcode-select -p &>/dev/null; then
    log_success "Xcode CLI tools already installed"
  else
    log_info "Installing Xcode Command Line Tools..."
    xcode-select --install
    # Wait for installation to complete
    until xcode-select -p &>/dev/null; do
      sleep 5
    done
    log_success "Xcode CLI tools installed"
  fi
}

# -- Homebrew -----------------------------------------------------------------

install_homebrew() {
  log_step "Homebrew"

  if command_exists brew; then
    log_success "Homebrew already installed"
    log_info "Updating Homebrew..."
    brew update
  else
    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon
    if [ "$(detect_arch)" = "arm64" ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      eval "$(/usr/local/bin/brew shellenv)"
    fi

    log_success "Homebrew installed"
  fi
}

# -- Brew Bundle --------------------------------------------------------------

install_packages() {
  log_step "Installing packages from Brewfile"

  local brewfile="$DOTFILES_DIR/Brewfile"

  if [ ! -f "$brewfile" ]; then
    log_error "Brewfile not found at $brewfile"
    return 1
  fi

  log_info "Running brew bundle (this may take a while on first run)..."
  brew bundle --file="$brewfile"

  log_success "All Homebrew packages installed"
}

# -- Fonts --------------------------------------------------------------------

install_fonts() {
  log_step "Installing custom fonts"

  local font_dir="$HOME/Library/Fonts"
  local src_dir="$DOTFILES_DIR/assets/fonts"

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
  fi
}

# -- macOS System Defaults ----------------------------------------------------

configure_macos_defaults() {
  log_step "Configuring macOS system defaults"

  # -- Finder --
  # Show hidden files
  defaults write com.apple.finder AppleShowAllFiles -bool true
  # Show file extensions
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  # Show path bar in Finder
  defaults write com.apple.finder ShowPathbar -bool true
  # Show status bar in Finder
  defaults write com.apple.finder ShowStatusBar -bool true
  # Default to list view
  defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
  # Keep folders on top when sorting by name
  defaults write com.apple.finder _FXSortFoldersFirst -bool true
  # Disable warning when changing file extension
  defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
  # Avoid creating .DS_Store files on network & USB volumes
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
  defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

  # -- Keyboard --
  # Fast key repeat rate
  defaults write NSGlobalDomain KeyRepeat -int 2
  # Short delay until key repeat
  defaults write NSGlobalDomain InitialKeyRepeat -int 15
  # Disable press-and-hold for keys (enable key repeat everywhere)
  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

  # -- Dock --
  # Minimize windows using scale effect
  defaults write com.apple.dock mineffect -string "scale"
  # Auto-hide the Dock
  defaults write com.apple.dock autohide -bool true
  # Remove auto-hide delay
  defaults write com.apple.dock autohide-delay -float 0
  # Speed up auto-hide animation
  defaults write com.apple.dock autohide-time-modifier -float 0.3
  # Don't show recent applications in Dock
  defaults write com.apple.dock show-recents -bool false

  # -- Trackpad --
  # Enable tap to click
  defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

  # -- Screenshots --
  # Save screenshots to ~/Screenshots
  mkdir -p "$HOME/Screenshots"
  defaults write com.apple.screencapture location -string "$HOME/Screenshots"
  # Save screenshots as PNG
  defaults write com.apple.screencapture type -string "png"
  # Disable screenshot shadow
  defaults write com.apple.screencapture disable-shadow -bool true

  # -- Misc --
  # Expand save/print panels by default
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
  defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
  defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true
  # Disable smart quotes and dashes (annoying when writing code)
  defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
  defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

  log_success "macOS defaults configured (restart Finder: killall Finder)"
}

# -- Main (called from bootstrap.sh) -----------------------------------------

run_macos_setup() {
  log_step "Starting macOS setup"

  install_xcode_cli
  install_homebrew
  install_packages
  install_fonts
  configure_macos_defaults
}

# Allow running standalone for testing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_macos_setup
fi
