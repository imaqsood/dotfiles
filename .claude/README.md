# Claude Code config (versioned)

Portable, shared Claude Code configuration carried across machines and across
both accounts (work enterprise + personal free). Everything here is symlinked
into each account's config dir by [`bin/setup-claude.sh`](../bin/setup-claude.sh).

## What's tracked

| Path             | Purpose                                              |
|------------------|------------------------------------------------------|
| `CLAUDE.md`      | Global instructions (coding style, tooling, how I work) |
| `settings.json`  | Shared settings (enabled plugins, etc.) — **no secrets** |
| `agents/`        | Custom subagents                                     |
| `commands/`      | Custom slash commands                                |
| `skills/`        | Custom skills (e.g. `vpn-connect`)                   |

Everything else under a live `~/.claude*` dir is runtime state and is **git-ignored**:
credentials, `projects/`, `sessions/`, `history.jsonl`, `.claude.json`,
`statsig/`, `telemetry/`, and any `settings.local.json` (machine-local overrides).

## Dual-account model

Two accounts, two config dirs, one shared config:

| Account            | `CLAUDE_CONFIG_DIR`   | Auth                         |
|--------------------|-----------------------|------------------------------|
| work (enterprise)  | `~/.claude` (default) | enterprise OAuth org         |
| personal (free)    | `~/.claude-personal`  | claude.ai OAuth              |

Each dir holds its own credentials, history, and projects. The files in this repo
are symlinked into **both**, so one edit to `CLAUDE.md` or a command applies to
both accounts.

### Switching

`claude-use` (defined in `config/zsh/zshrc`):

```sh
claude-use work        # point this shell at the work account
claude-use personal    # point this shell at the personal account
claude-use status      # show current account
claude-use -s personal # switch AND persist as the new default
```

**macOS caveat:** the OAuth token is stored in the system Keychain (a single
entry, not per-config-dir). Config, history, and projects stay fully isolated per
dir, but the *first* switch in a fresh shell may prompt a `/login`. Re-auth once
per account and you're set for the session.

## Bootstrap

```sh
./bin/setup-claude.sh        # standalone — links shared config into all account dirs
```

Also runs automatically as part of `./bootstrap.sh`. Idempotent; backs up any real
file it would replace with a symlink.

To add another account, add its dir to `CLAUDE_DIRS` in `bin/setup-claude.sh` and a
branch to `claude-use` in `zshrc`.
