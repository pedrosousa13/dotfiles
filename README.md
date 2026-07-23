# dotfiles

Personal dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## How it works

Each top-level directory is a Stow "package" that mirrors the file layout relative to `$HOME`. Stowing a package symlinks its files into your home directory.

For example, `claude/.claude/CLAUDE.md` becomes `~/.claude/CLAUDE.md`.

## Setup

```sh
brew install stow          # macOS
git clone <this-repo> ~/dotfiles
cd ~/dotfiles
brew install betterleaks             # secret scanner used by pre-commit hook
git config core.hooksPath hooks      # enable the hook (blocks committing secrets)
```

The repo must live directly under `$HOME` (Stow's default target is the parent directory). If you clone it elsewhere, pass `-t ~` to every stow command.

## Usage

Stow a package:

```sh
cd ~/dotfiles
stow claude
```

Remove a package's symlinks:

```sh
stow -D claude
```

Re-stow after adding/removing files in a package:

```sh
stow -R claude
```

If a real file already exists where a symlink would go, either delete it first, or let Stow absorb it into the repo:

```sh
stow --adopt claude        # moves the existing file into the package, then symlinks
```

## Packages

| Package    | What it configures                                            | Links to                                              |
| ---------- | ------------------------------------------------------------- | ----------------------------------------------------- |
| `agents`   | Skill install lockfile ([skills](https://github.com/vercel-labs/skills) CLI provenance) | `~/.agents/.skill-lock.json`  |
| `claude`   | Claude Code: instructions, settings, statusline               | `~/.claude/{CLAUDE.md,settings.json,statusline-account.sh}`, `~/.config/ccstatusline/settings.json` |
| `gh-dash`  | [gh-dash](https://github.com/dlvhdr/gh-dash) GitHub dashboard | `~/.config/gh-dash/config.yml`                        |
| `herdr`    | [Herdr](https://herdr.dev) terminal multiplexer (hyperkey bindings) | `~/.config/herdr/config.toml`                   |
| `hyprland` | Hyprland window manager (Linux)                               | `~/.config/hypr/hyprland.conf`                        |
| `vscode`   | VS Code settings (macOS path)                                 | `~/Library/Application Support/Code/User/settings.json` |
| `zed`      | Zed editor settings and keymap                                | `~/.config/zed/{settings,keymap}.json`                |
| `zsh`      | Zsh config                                                    | `~/.zshrc`                                            |

## Claude Code two-account setup

Work account uses the default `~/.claude`; personal uses `CLAUDE_CONFIG_DIR=~/.claude-personal` (see `claudy`/`claudly` aliases in `.zshrc`). Shared config (settings, skills, agents, commands, plugins) lives in `~/.claude`; the personal dir symlinks it and keeps only account data (auth, history, projects).

New machine:

```sh
stow claude agents
./claude/setup-personal.sh           # creates the ~/.claude-personal symlinks
npx get-shit-done-cc --global        # reinstalls gsd hooks + skills (settings.json references them)
claudy   # then /login (work)
claudly  # then /login (personal)
```

Non-committed local files:

- `~/.claude/statusline-accounts.env` — account emails read by `statusline-account.sh` (`PERSONAL_EMAIL=`, `WORK_EMAIL=`).
- Skills in `~/.agents/skills` are reinstalled by the [skills](https://github.com/vercel-labs/skills) CLI; `~/.agents/.skill-lock.json` records each skill's source.
- `settings.json` hooks hardcode an fnm node path — rerun the gsd install above if node versions differ.

Notes:

- `zsh/secrets-out.zsh` is gitignored and sourced by `.zshrc` via `$DOTFILES_DIR` — it is excluded from stowing by `zsh/.stow-local-ignore` (Stow reads ignore files from the package directory, not the repo root).
- `claude/setup-personal.sh` is excluded from stowing by `claude/.stow-local-ignore` — run it from the repo.
- Stow may fold directories: a clean machine gets `~/.config/gh-dash -> dotfiles/gh-dash/.config/gh-dash` (whole dir) instead of per-file links. Both are fine.
