#!/bin/bash
# =============================================================================
# utils.sh — Shared utility functions for dotfiles bootstrap
# =============================================================================

set -euo pipefail

# -- Colors & Logging ---------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

log_info()    { printf "${BLUE}[INFO]${RESET}    %s\n" "$1"; }
log_success() { printf "${GREEN}[OK]${RESET}      %s\n" "$1"; }
log_warn()    { printf "${YELLOW}[WARN]${RESET}    %s\n" "$1"; }
log_error()   { printf "${RED}[ERROR]${RESET}   %s\n" "$1" >&2; }
log_step()    { printf "\n${BOLD}${MAGENTA}==>${RESET} ${BOLD}%s${RESET}\n" "$1"; }

# -- OS Detection -------------------------------------------------------------

detect_os() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux)
      if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
          ubuntu|debian|pop|linuxmint|elementary|zorin) echo "debian" ;;
          *) echo "unsupported" ;;
        esac
      else
        echo "unsupported"
      fi
      ;;
    *) echo "unsupported" ;;
  esac
}

detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64) echo "amd64" ;;
    aarch64|arm64) echo "arm64" ;;
    *) echo "unknown" ;;
  esac
}

# -- Helpers -------------------------------------------------------------------

command_exists() {
  command -v "$1" &>/dev/null
}

# Check if running as root (for Debian)
ensure_not_root() {
  if [ "$(id -u)" -eq 0 ]; then
    log_error "Do not run this script as root. It will ask for sudo when needed."
    exit 1
  fi
}

# -- Directory Creation --------------------------------------------------------

create_directories() {
  log_step "Creating required directories"

  local dirs=(
    "$HOME/.config/nvim"
    "$HOME/.config/wezterm"
    "$HOME/.config/ghostty"
    "$HOME/.config/alacritty"
    "$HOME/.config/starship"
    "$HOME/.ssh"
    "$HOME/.vifm"
    "$HOME/.config/terminator"
  )

  for dir in "${dirs[@]}"; do
    if [ ! -d "$dir" ]; then
      mkdir -p "$dir"
      log_success "Created $dir"
    fi
  done
}

# -- Symlink Management --------------------------------------------------------

create_symlink() {
  local src="$1"
  local dest="$2"

  # Ensure source exists (file or directory)
  if [ ! -e "$src" ]; then
    log_warn "Source not found, skipping: $src"
    return
  fi

  # Ensure destination's parent directory exists
  mkdir -p "$(dirname "$dest")"

  # Backup existing path (real file or directory, not a symlink)
  if [ ! -L "$dest" ] && [ -e "$dest" ]; then
    local backup="${dest}.backup.$(date +%Y%m%d%H%M%S)"
    mv "$dest" "$backup"
    log_warn "Backed up existing path: $dest -> $backup"
  fi

  # Remove existing symlink if it points somewhere else
  if [ -L "$dest" ]; then
    rm "$dest"
  fi

  ln -sf "$src" "$dest"
  log_success "Linked: $dest -> $src"
}

setup_symlinks() {
  local dotfiles_dir="$1"

  log_step "Setting up symlinks"

  # Symlink mapping: source (relative to dotfiles) -> target (absolute)
  create_symlink "$dotfiles_dir/config/zsh/zshrc"              "$HOME/.zshrc"
  create_symlink "$dotfiles_dir/config/zsh/p10k.zsh"           "$HOME/.p10k.zsh"
  create_symlink "$dotfiles_dir/config/tmux/tmux.conf.local"   "$HOME/.tmux.conf.local"
  create_symlink "$dotfiles_dir/config/nvim/init.lua"          "$HOME/.config/nvim/init.lua"
  create_symlink "$dotfiles_dir/config/wezterm/wezterm.lua"    "$HOME/.config/wezterm/wezterm.lua"
  create_symlink "$dotfiles_dir/config/ghostty/config"         "$HOME/.config/ghostty/config"
  create_symlink "$dotfiles_dir/config/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
  create_symlink "$dotfiles_dir/config/git/gitconfig"          "$HOME/.gitconfig"
  create_symlink "$dotfiles_dir/config/starship/starship.toml" "$HOME/.config/starship.toml"
  create_symlink "$dotfiles_dir/config/ssh/config"             "$HOME/.ssh/config"
  create_symlink "$dotfiles_dir/config/vim/vimrc"              "$HOME/.vimrc"
  create_symlink "$dotfiles_dir/config/vifm/vifmrc"            "$HOME/.vifm/vifmrc"
  create_symlink "$dotfiles_dir/config/shell/inputrc"          "$HOME/.inputrc"
  create_symlink "$dotfiles_dir/config/shell/editrc"           "$HOME/.editrc"

  # Claude Code: custom slash commands and subagents
  create_symlink "$dotfiles_dir/.claude/commands"              "$HOME/.claude/commands"
  create_symlink "$dotfiles_dir/.claude/agents"                "$HOME/.claude/agents"

  # tmux base config (from gpakosz/.tmux clone)
  if [ -f "$HOME/.tmux/.tmux.conf" ]; then
    create_symlink "$HOME/.tmux/.tmux.conf" "$HOME/.tmux.conf"
  fi
}

# -- Banner --------------------------------------------------------------------

print_banner() {
  printf "${CYAN}"
  cat << 'EOF'

  ██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗
  ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝
  ██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗
  ██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║
  ██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║
  ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝

  Next-Gen Developer Environment Bootstrap
  https://github.com/imaqsood/dotfiles

EOF
  printf "${RESET}"
}

# -- Summary -------------------------------------------------------------------

print_summary() {
  local os="$1"

  log_step "Setup Complete!"

  printf "\n${BOLD}  Installed tools:${RESET}\n"
  printf "  %-15s %s\n" "Shell:"     "zsh + oh-my-zsh + powerlevel10k"
  printf "  %-15s %s\n" "Editor:"    "neovim (lazy.nvim + telescope + treesitter)"
  printf "  %-15s %s\n" "Terminal:"  "wezterm + ghostty"
  printf "  %-15s %s\n" "Mux:"       "tmux (gpakosz/.tmux)"
  printf "  %-15s %s\n" "Versions:"  "mise (node, ruby, python, java, go)"
  printf "  %-15s %s\n" "Search:"    "ripgrep, fd, fzf"
  printf "  %-15s %s\n" "Git TUI:"   "lazygit + git-delta"
  printf "  %-15s %s\n" "Docker:"    "lazydocker + k9s"
  printf "  %-15s %s\n" "Files:"     "eza, bat, yazi, dust, duf"
  printf "  %-15s %s\n" "History:"   "atuin"
  printf "  %-15s %s\n" "Nav:"       "zoxide"
  printf "  %-15s %s\n" "AI:"        "claude-code, gh copilot"

  printf "\n${BOLD}  Next steps:${RESET}\n"
  printf "  1. Restart your terminal (or run: ${CYAN}exec zsh${RESET})\n"
  printf "  2. Run ${CYAN}p10k configure${RESET} if prompt looks wrong\n"
  printf "  3. Run ${CYAN}atuin login${RESET} to sync shell history (optional)\n"
  printf "  4. Run ${CYAN}mise use --global node@lts ruby@latest python@latest${RESET}\n"

  if [ "$os" = "macos" ]; then
    printf "  5. Restart Finder for macOS defaults: ${CYAN}killall Finder${RESET}\n"
  fi

  printf "\n"
}
