# AI development workflow

A guide to the AI tooling wired into these dotfiles: two Claude Code accounts,
in-editor AI in Neovim, Claude panes + session management in tmux, and a
git-worktree helper for running parallel agents.

This documents **our customizations** — the keybindings, functions, and config
that live in this repo. For each tool's full feature set, follow the **reference
links**; only what we changed or added is spelled out here.

> Convention: `<leader>` is **Space**. `prefix` is the tmux prefix (`Ctrl-a` /
> `Ctrl-b`).

---

## Contents

1. [One-time setup](#one-time-setup)
2. [Claude Code: accounts & shared config](#claude-code-accounts--shared-config)
3. [Neovim: in-editor AI](#neovim-in-editor-ai)
4. [tmux: Claude panes & sessions](#tmux-claude-panes--sessions)
5. [Shell: parallel work with worktrees](#shell-parallel-work-with-worktrees)
6. [A day in the workflow](#a-day-in-the-workflow)
7. [Troubleshooting](#troubleshooting)
8. [All reference links](#all-reference-links)

---

## One-time setup

```sh
# 1. Shared Claude config → symlinked into each account dir (idempotent)
./bin/setup-claude.sh

# 2. Tools from Brewfile (sesh is the new one for AI workflow)
brew bundle --file=Brewfile        # or: brew install sesh

# 3. Reload the shell (loads claude-use, gwt)
exec zsh

# 4. tmux plugins (resurrect / continuum / extrakto)
#    reload config, then install:
tmux source ~/.tmux.conf
#    press: prefix + I

# 5. Log in to each Claude account once
claude-use personal && claude     # then /login, then /exit
claude-use work     && claude     # then /login (enterprise)

# 6. Neovim plugins install automatically on first launch
nvim                               # :Lazy to watch
```

---

## Claude Code: accounts & shared config

We run **two accounts** on one machine — work (enterprise) and personal (free) —
each with isolated credentials/history but **shared** config.

### Switch accounts — `claude-use`

| Command | Effect |
|---|---|
| `claude-use work` | point shell at the work account (`~/.claude`) |
| `claude-use personal` | point shell at the personal account (`~/.claude-personal`) |
| `claude-use status` | show the active account |
| `claude-use -s <acct>` | switch **and** persist as the new default |

How it works: each account is a separate `CLAUDE_CONFIG_DIR`. `claude` (and the
Neovim/tmux integrations) pick up whichever the current shell selected.

> **macOS note:** the OAuth token lives in one system Keychain entry, so the
> *first* switch in a fresh shell may prompt a `/login`. Config, history, and
> projects stay isolated per account regardless.

### What's shared vs local

Symlinked from `.claude/` in this repo into **both** account dirs by
[`bin/setup-claude.sh`](../bin/setup-claude.sh):

| Shared (versioned) | Per-account (never committed) |
|---|---|
| `CLAUDE.md` — global instructions | credentials (Keychain / `.credentials.json`) |
| `settings.json` — enabled plugins, etc. | `projects/`, `sessions/`, `history.jsonl` |
| `agents/`, `commands/`, `skills/` | `.claude.json`, `statsig/`, `telemetry/` |
| | `settings.local.json` — machine overrides |

Edit any shared file once → it applies to both accounts. Add a new account by
extending `CLAUDE_DIRS` in `bin/setup-claude.sh` and adding a branch to
`claude-use` in `config/zsh/zshrc`.

See also [`.claude/README.md`](../.claude/README.md) ·
[Claude Code docs](https://code.claude.com/docs) ·
[the `.claude` directory](https://code.claude.com/docs/en/claude-directory)

---

## Neovim: in-editor AI

Three pieces, by purpose: **full agentic sessions** (Claude Code), **quick
in-buffer chat/edits** (CodeCompanion), and **inline completion** (Copilot).

### Claude Code in a terminal split — `claude-code.nvim`

Runs the `claude` CLI in a split, inheriting the shell's `CLAUDE_CONFIG_DIR`
(so it uses the account `claude-use` picked).

| Key | Action |
|---|---|
| `<leader>cc` | toggle Claude Code split |
| `<leader>cC` | continue the last conversation |
| `<leader>cr` | resume — pick a past conversation |
| `<C-,>` | toggle (plugin default, also works) |

Reference: <https://github.com/greggh/claude-code.nvim>

### Quick chat & inline edits — `CodeCompanion`

Uses your **Copilot subscription** as the model (no API key). Complements Claude
Code: use this for fast asks without leaving the buffer.

| Key | Mode | Action |
|---|---|---|
| `<leader>ai` | n, v | toggle AI chat buffer |
| `<leader>aa` | n, v | action palette (explain, fix, test, …) |
| `<leader>ae` | n, v | inline edit (rewrite selection / generate) |

Our config sets the adapter to `copilot` for both chat and inline; everything
else is upstream default.

Reference: <https://codecompanion.olimorris.dev>

### Inline completion — Copilot via `copilot.lua` + `nvim-cmp`

We migrated off `copilot.vim`: Copilot suggestions now appear **inside the
nvim-cmp menu** (no separate keymap to fight). Inline ghost-text and the panel
are disabled on purpose.

| Key | Action |
|---|---|
| `<Tab>` / `<S-Tab>` | cycle completion items (Copilot + LSP + snippets) |
| `<CR>` | accept the selected item |
| `<C-Space>` | open completions manually |
| `<C-e>` | dismiss the menu |

A ` ` indicator in the statusline (lualine) shows when Copilot is attached.

Reference: [copilot.lua](https://github.com/zbirenbaum/copilot.lua) ·
[copilot-cmp](https://github.com/zbirenbaum/copilot-cmp)

---

## tmux: Claude panes & sessions

All bindings below are **our additions** in
[`config/tmux/tmux.conf.local`](../config/tmux/tmux.conf.local). They use `prefix`
(`Ctrl-a`).

### Summon Claude

| Binding | Action |
|---|---|
| `prefix + C` | Claude Code in a split beside the current pane |
| `prefix + A` | Claude Code in a floating popup (closes on exit) |

Both launch via an interactive shell, so they inherit the account `claude-use`
selected.

### Grab text for prompts — `extrakto`

| Binding | Action |
|---|---|
| `prefix + o` | fuzzy-pick any path / hash / URL / word on screen to copy or insert |

(Rebound off the default `prefix + Tab`, which gpakosz uses for last-window.)
Reference: <https://github.com/laktak/extrakto>

### Switch sessions / projects — `sesh`

| Binding | Action |
|---|---|
| `prefix + T` | popup: fuzzy-pick a session, directory, or zoxide result to jump to / create |

Requires `sesh` + `fzf`. This is the entry point for the per-worktree session
workflow below. Reference: <https://github.com/joshmedeski/sesh>

### Session persistence — `resurrect` + `continuum`

Auto-restores your last session on tmux start and auto-saves every ~15 min
(with pane contents). Our custom config: `@continuum-restore on`,
`@resurrect-capture-pane-contents on`.

| Binding | Action |
|---|---|
| `prefix + Ctrl-s` | save now (upstream default) |
| `prefix + Ctrl-r` | restore now (upstream default) |

> First run shows "resurrect file not found" until you save once — that's
> expected. Press `prefix + Ctrl-s` to create the first save.

References: [resurrect](https://github.com/tmux-plugins/tmux-resurrect) ·
[continuum](https://github.com/tmux-plugins/tmux-continuum)

---

## Shell: parallel work with worktrees

Run several Claude sessions at once — one git worktree + tmux session per task.
Defined in [`config/zsh/zshrc`](../config/zsh/zshrc).

| Command | Action |
|---|---|
| `gwt <branch> [base]` | create/reuse a worktree for `<branch>` (off `base`, default `HEAD`) and open a session rooted there |
| `gwt` | fzf-pick an existing worktree and jump to it |
| `gwt-rm <branch>` | remove a worktree by branch and prune |

- Worktrees live under `$WORKTREE_HOME/<repo>/<branch>` (default
  `~/dev/worktrees`).
- Prefers `sesh` when inside tmux, falls back to `tmux new-session`, then `cd`.
- Works correctly whether run from the main checkout or inside a worktree.

> `gwt` shadows oh-my-zsh's lesser-used `gwt='git worktree'` alias. Use
> `git worktree …` directly if you need the raw command.

---

## A day in the workflow

```sh
# Pick the account for this work
claude-use work

# Spin up an isolated worktree + session for a task
gwt fix/login-bug          # new branch off HEAD, own dir, own tmux session

# In that session: open the editor, summon Claude beside it
nvim
#   <leader>cc   → Claude Code split, give it the task
#   <leader>ai   → quick CodeCompanion question without leaving the buffer
#   <Tab>        → accept Copilot completions inline

# Need a file path / error from another pane to paste into Claude?
#   prefix + o   → extrakto grabs it

# Jump between concurrent tasks
#   prefix + T   → sesh switcher   (or `gwt` to fzf-pick worktrees)

# Done with the task
gwt-rm fix/login-bug
```

Sessions survive reboots (continuum), so you can pick up exactly where you left
off.

---

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `claude-use` / `gwt` not found | Run `exec zsh` to reload the shell. |
| First switch asks to `/login` again | Expected on macOS (single Keychain entry). Log in once per account. |
| tmux: "resurrect file not found" | Expected before the first save — press `prefix + Ctrl-s`. |
| `prefix + T` / `gwt` does nothing | `sesh` not installed — `brew install sesh`. |
| tmux bindings missing after edit | Reload: `prefix + r` or `tmux source ~/.tmux.conf`. |
| nvim AI keys do nothing | Plugins still installing — check `:Lazy`. |
| CodeCompanion: no model / auth error | Authenticate Copilot in nvim: `:Copilot auth`. |
| Claude pane opens wrong account | The pane uses the shell's `CLAUDE_CONFIG_DIR`; run `claude-use …` before launching, or `-s` to persist. |

---

## All reference links

- **Claude Code** — <https://code.claude.com/docs>
- **claude-code.nvim** — <https://github.com/greggh/claude-code.nvim>
- **CodeCompanion** — <https://codecompanion.olimorris.dev>
- **copilot.lua** — <https://github.com/zbirenbaum/copilot.lua>
- **copilot-cmp** — <https://github.com/zbirenbaum/copilot-cmp>
- **sesh** — <https://github.com/joshmedeski/sesh>
- **extrakto** — <https://github.com/laktak/extrakto>
- **tmux-resurrect** — <https://github.com/tmux-plugins/tmux-resurrect>
- **tmux-continuum** — <https://github.com/tmux-plugins/tmux-continuum>
- **git worktree** — <https://git-scm.com/docs/git-worktree>
