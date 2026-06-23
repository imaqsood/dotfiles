# Global instructions

Shared across all Claude Code accounts (work + personal) on this machine.
Versioned in dotfiles → `.claude/CLAUDE.md`. Keep it portable: no secrets, no
work-only context (put those in a project-level `CLAUDE.md` or
`~/.claude/CLAUDE.local.md`).

## Environment

- macOS (Apple Silicon), zsh, tmux, Neovim.
- Toolchain: `mise` (node/ruby/python/go/java), `rg`/`fd`/`fzf` for search,
  `eza`/`bat`/`yazi` for files, `lazygit` + `git-delta` for git, `atuin` history,
  `zoxide` nav.
- Prefer these modern tools over their classic equivalents when running commands
  (`rg` over `grep`, `fd` over `find`, `bat` over `cat` for viewing).

## How I like you to work

- Be concise and direct. Lead with the answer; skip preamble and filler.
- When you change code, match the surrounding style — don't reformat unrelated lines.
- Prefer editing existing files over creating new ones; don't add docs/READMEs
  unless asked.
- Run the project's own linters/tests before claiming something works. If a step
  was skipped or a test failed, say so plainly.
- Ask before doing anything hard to reverse (force-push, history rewrite, deleting
  files I didn't create, anything outward-facing).

## Git

- Don't commit or push unless I ask.
- Never commit secrets, credentials, or internal URLs.
