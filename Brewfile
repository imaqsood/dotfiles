# =============================================================================
# Brewfile — macOS Homebrew packages for next-gen developer environment
# Usage: brew bundle --file=Brewfile
# =============================================================================

# -- Taps ---------------------------------------------------------------------

tap "homebrew/services"

# -- Core CLI Tools -----------------------------------------------------------

brew "git"
brew "zsh"
brew "tmux"
brew "neovim"
brew "curl"
brew "wget"
brew "jq"
brew "tree"
brew "coreutils"
brew "openssh"
brew "htop"
brew "neofetch"
brew "gh"                          # GitHub CLI
brew "watch"

# -- Modern CLI Replacements (Rust-powered) -----------------------------------

brew "eza"                         # ls replacement (actively maintained exa fork)
brew "bat"                         # cat with syntax highlighting
brew "fd"                          # find replacement
brew "ripgrep"                     # grep replacement (rg)
brew "fzf"                         # fuzzy finder
brew "zoxide"                      # smarter cd — learns your directories
brew "git-delta"                   # beautiful git diffs with syntax highlighting
brew "sd"                          # sed replacement — simpler find & replace
brew "dust"                        # du replacement — visual disk usage
brew "duf"                         # df replacement — disk free with colors
brew "procs"                       # ps replacement — modern process viewer
brew "bottom"                      # top/htop replacement — system monitor (btm)
brew "hyperfine"                   # time replacement — benchmarking tool
brew "tokei"                       # cloc replacement — fast code statistics

# -- TUI Tools (Terminal User Interfaces) -------------------------------------

brew "lazygit"                     # git TUI — staging, rebasing, conflicts visually
brew "lazydocker"                  # docker TUI — logs, stats, container management
brew "k9s"                         # kubernetes TUI — navigate & manage clusters
brew "yazi"                        # terminal file manager — fast, image previews

# -- Shell Enhancements -------------------------------------------------------

brew "starship"                    # cross-shell prompt (alternative to powerlevel10k)
brew "atuin"                       # shell history in SQLite — searchable, syncable

# -- Version Manager (replaces pyenv, rbenv, nvm, sdkman) --------------------

brew "mise"                        # unified version manager for all languages

# -- DevOps & Cloud -----------------------------------------------------------

brew "kubernetes-cli"              # kubectl
brew "helm"                        # kubernetes package manager
brew "terraform"                   # infrastructure as code

# -- Languages & Runtimes -----------------------------------------------------

brew "go"
brew "rust"
brew "lua"
brew "luajit"

# -- GUI Applications (Casks) -------------------------------------------------

cask "wezterm"                     # GPU-accelerated terminal with Lua scripting
cask "ghostty"                     # native macOS terminal by Mitchell Hashimoto
# cask "docker"                    # Docker Desktop (install manually — permissions issues with brew adopt)

# -- Nerd Fonts (for terminal icons & glyphs) ---------------------------------

cask "font-jetbrains-mono-nerd-font"
cask "font-fira-code-nerd-font"
cask "font-meslo-lg-nerd-font"
cask "font-hack-nerd-font"
