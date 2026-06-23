#!/bin/bash
# =============================================================================
# setup-claude.sh — Link shared Claude Code config into every account dir
#
# Dual-account model (work enterprise + personal free) on macOS:
#   work     -> CLAUDE_CONFIG_DIR=~/.claude            (default; enterprise OAuth)
#   personal -> CLAUDE_CONFIG_DIR=~/.claude-personal   (free OAuth)
#
# Each config dir keeps its OWN credentials, projects/, and history. This script
# only symlinks the *shared, portable* config (CLAUDE.md, settings.json, agents,
# commands, skills) from the dotfiles repo into both dirs, so one edit applies to
# both accounts. Switch accounts at runtime with `claude-use work|personal`
# (defined in config/zsh/zshrc).
#
# Safe to run multiple times (idempotent). No secrets are touched or stored.
# =============================================================================

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES_DIR/lib/utils.sh"

# Account config dirs to populate. Add more here if you grow more accounts.
CLAUDE_DIRS=(
  "$HOME/.claude"
  "$HOME/.claude-personal"
)

# Shared config to link into each dir (relative to dotfiles/.claude).
# Per-file/dir symlinks only — never link the whole config dir (it holds
# per-account credentials and runtime state that must stay local).
SHARED_ITEMS=(
  "CLAUDE.md"
  "settings.json"
  "agents"
  "commands"
  "skills"
)

setup_claude() {
  log_step "Linking shared Claude Code config"

  local src_root="$DOTFILES_DIR/.claude"

  for dir in "${CLAUDE_DIRS[@]}"; do
    mkdir -p "$dir"
    log_info "Config dir: ${dir/#$HOME/~}"
    for item in "${SHARED_ITEMS[@]}"; do
      create_symlink "$src_root/$item" "$dir/$item"
    done
  done

  printf "\n"
  log_success "Shared config linked into ${#CLAUDE_DIRS[@]} account dir(s)."
  printf "  Next: log in to each account once —\n"
  printf "    %s\n" "claude-use work     && claude   # then /login (enterprise)"
  printf "    %s\n" "claude-use personal && claude   # then /login (personal)"
  printf "  macOS note: the OAuth token lives in the system Keychain (one entry),\n"
  printf "  so the first switch in a shell may ask you to /login again. Config,\n"
  printf "  history, and projects stay isolated per dir regardless.\n\n"
}

# Allow running standalone or sourcing into bootstrap.sh
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  setup_claude
fi
