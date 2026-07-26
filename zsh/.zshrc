# zmodload zsh/zprof
# Cross-platform zsh config — macOS and Linux run this same file. Every
# platform-specific block is guarded on the binary or path it needs, so a
# machine missing a tool skips it instead of erroring.
export DOTFILES_DIR="${HOME}/dotfiles"

# secrets management — machines with the 1Password CLI only
if command -v op >/dev/null; then
  secrets_out_path="${DOTFILES_DIR}/zsh/secrets-out.zsh"

  if [ ! -f "$secrets_out_path" ]; then
      echo "Creating ${secrets_out_path}..."
      op --account "my.1password.com" read op://Personal/zshrc_secrets/notesPlain --out-file "${DOTFILES_DIR}/zsh/secrets-out.zsh"
  fi

  alias update-secrets='rm "${DOTFILES_DIR}/zsh/secrets-out.zsh" && op --account "my.1password.com" read op://Personal/zshrc_secrets/notesPlain --out-file "${DOTFILES_DIR}/zsh/secrets-out.zsh" && source "${DOTFILES_DIR}/zsh/secrets-out.zsh"'
  source "$secrets_out_path"
  unset secrets_out_path
fi

# Inlined `brew shellenv` output — saves ~30ms fork; path_helper already ran via /etc/zprofile
if [[ -f "/opt/homebrew/bin/brew" ]] then
  export HOMEBREW_PREFIX="/opt/homebrew" HOMEBREW_CELLAR="/opt/homebrew/Cellar" HOMEBREW_REPOSITORY="/opt/homebrew"
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
  export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"
  fpath[1,0]="/opt/homebrew/share/zsh/site-functions"
  export FPATH
fi

# User-local bins, after brew so they win. Linux keeps starship/herdr/deja here.
for d in "$HOME/go/bin" "$HOME/.cargo/bin" "$HOME/.local/bin"; do
  [ -d "$d" ] && case ":$PATH:" in *":$d:"*) ;; *) export PATH="$d:$PATH";; esac
done

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in zsh plugins (async loading with turbo mode)
zinit ice wait lucid
zinit light zsh-users/zsh-completions

# zle plugins — Warp uses its own input editor, these never render there
if [[ "$TERM_PROGRAM" != "WarpTerminal" || "$HERDR_ENV" == "1" ]]; then
  # syntax highlighting via zsh-patina (activated at end of file);
  # fall back to zsh-syntax-highlighting on machines without the binary
  if ! command -v zsh-patina >/dev/null; then
    zinit light zsh-users/zsh-syntax-highlighting
  fi
  # Ghost-text suggestions come from deja (activated near the end of this
  # file), which stands down if zsh-autosuggestions is loaded.
fi

# Load completions (full compinit audit at most once per 24h, else cached -C)
fpath=(~/.zsh/completions $fpath)
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qNmh-24) ]]; then
  compinit -C
else
  compinit
fi

zinit cdreplay -q

# fzf-tab must load after compinit / cdreplay
if [[ "$TERM_PROGRAM" != "WarpTerminal" || "$HERDR_ENV" == "1" ]] && command -v fzf >/dev/null; then
  zinit light Aloxaf/fzf-tab
fi

# Starship prompt (faster than oh-my-posh)
# Warp renders its own native prompt (HonorPS1=false) — starship would fork on every Enter for nothing
if [[ "$TERM_PROGRAM" != "WarpTerminal" || "$HERDR_ENV" == "1" ]] && command -v starship >/dev/null; then
  eval "$(starship init zsh)"
fi

# Keybindings
bindkey -e
# completion using arrow keys (based on history)
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
bindkey '^[w' kill-region

# History
HISTSIZE=1000000000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt no_share_history
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Aliases
command -v nvim >/dev/null && alias vim='nvim'
alias c='clear'

# git
alias gfp="git fetch && git pull"
alias gfd="git fetch origin develop:develop"
alias gfm="git fetch origin master:master"
# alias gfpt="git fetch && git reset --hard origin/$(git rev-parse --abbrev-ref HEAD)"
# alias ggsup="git branch --set-upstream-to=origin/$(current_branch)"
alias glatest="git for-each-ref --sort=committerdate refs/heads/ --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))'"
alias gs="git status"
alias grh="git reset --hard && git clean -df"

# docker (v2 subcommand — the standalone docker-compose binary is gone on both OSes)
alias doup="docker compose up -d"
alias dodo="docker compose down"
alias dodov="docker compose down -v"

# nx
alias nx="npx nx"

# prisma
alias studio="npx prisma studio"
alias dbpush="npx prisma db push"
alias pformat="npx prisma format"

# weather
alias lu="curl 'wttr.in/Luzern?Fn2'"
alias we="curl 'wttr.in/?Fn2'"

# claudy = work account (default ~/.claude), claudly = personal (~/.claude-personal)
alias claudy="claude --dangerously-skip-permissions"
alias claudly='CLAUDE_CONFIG_DIR="$HOME/.claude-personal" claude --dangerously-skip-permissions'

# npm
unalias npm 2>/dev/null
npm() {
  case "$1" in
    install|i|add)
      if ! command -v npq-hero &>/dev/null; then
        command npm install -g npq &>/dev/null
      fi
      if command -v npq-hero &>/dev/null; then
        npq-hero "$@" 2>/dev/null || {
          echo "falling back to npm" >&2
          command npm "$@"
        }
      else
        command npm "$@"
      fi
      ;;
    *)
      command npm "$@"
      ;;
  esac
}


# Shell integrations
# fzf 0.48+ has `fzf --zsh`; older Debian packages ship source files instead
if command -v fzf >/dev/null; then
  if fzf --zsh >/dev/null 2>&1; then
    eval "$(fzf --zsh)"
  else
    for f in /usr/share/doc/fzf/examples/key-bindings.zsh \
             /usr/share/doc/fzf/examples/completion.zsh; do
      [ -r "$f" ] && source "$f"
    done
  fi
fi

command -v zoxide >/dev/null && eval "$(zoxide init --cmd cd zsh)"

# cli plugins (Debian ships bat and fd under different binary names)
if command -v bat >/dev/null; then
  alias cat="bat"
elif command -v batcat >/dev/null; then
  alias cat="batcat"
fi
command -v fd >/dev/null || { command -v fdfind >/dev/null && alias fd="fdfind" }

#---- Eza (better ls) -----
command -v eza >/dev/null && \
  alias ls="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions"

pkg() {
  local pkg_manager
  pkg_manager=$(npx --yes identify-package-manager -n)
  if [ "$pkg_manager" = "yarn" ]; then
    yarn "$@"
  else
    npm run "$@"
  fi
}

# fnm (lazy loading)
[ -d "$HOME/Library/Application Support/fnm" ] && export PATH="$HOME/Library/Application Support/fnm:$PATH"
command -v fnm >/dev/null && eval "$(fnm env --use-on-cd --shell zsh)"


# Android SDK/Studio
#export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home
#export ANDROID_HOME=$HOME/Library/Android/sdk
#export PATH=$PATH:$ANDROID_HOME/emulator
#export PATH=$PATH:$ANDROID_HOME/platform-tools

# Q post block. Keep at the bottom of this file.
# GPG
export GPG_TTY=$(tty)

# pnpm
for d in "$HOME/Library/pnpm" "$HOME/.local/share/pnpm"; do
  if [ -d "$d" ]; then
    export PNPM_HOME="$d"
    case ":$PATH:" in
      *":$PNPM_HOME:"*) ;;
      *) export PATH="$PNPM_HOME:$PATH" ;;
    esac
  fi
done
# pnpm end

# opencode
[ -d "$HOME/.opencode/bin" ] && export PATH="$HOME/.opencode/bin:$PATH"

# wt shell init, cached to file — regenerated when the wt binary updates
if command -v wt >/dev/null 2>&1; then
  _wt_init="$HOME/.cache/wt-init.zsh"
  if [[ ! -s "$_wt_init" || "$(command -v wt)" -nt "$_wt_init" ]]; then
    mkdir -p "$HOME/.cache"
    command wt config shell init zsh > "$_wt_init"
  fi
  source "$_wt_init"
  unset _wt_init
fi

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# deja — predictive ghost-text suggestions, replaces zsh-autosuggestions.
# Tab stays with fzf-tab, so deja's alternatives picker is unbound.
#
# Only initialise once per shell. deja wraps every ZLE widget, and a second
# `eval` in the same shell (any `source ~/.zshrc`) wraps its own wrappers —
# the widgets then recurse until zsh aborts with
# "_deja_line_init: maximum nested function level reached".
if [[ "$TERM_PROGRAM" != "WarpTerminal" || "$HERDR_ENV" == "1" ]] \
   && command -v deja >/dev/null \
   && (( ! ${+functions[_deja_precmd]} )); then
  export DEJA_CYCLE_KEY=''
  eval "$(deja init zsh)"
fi

# zsh-patina syntax highlighting — must stay at end of file, zle terminals only
if { [[ "$TERM_PROGRAM" != "WarpTerminal" ]] || [[ "$HERDR_ENV" == "1" ]]; } && command -v zsh-patina >/dev/null; then
  eval "$(zsh-patina activate)"
fi

# Radio France (cmus TUI)
alias radio='cmus'

# Word navigation/deletion in raw ZLE (herdr panes, ssh) — Warp prompt unaffected
bindkey '^[[1;3D' backward-word       # option+left
bindkey '^[[1;3C' forward-word        # option+right
bindkey '^[^?' backward-kill-word     # option+backspace (esc-del)
bindkey '^[[3;3~' kill-word           # option+fn+delete (forward)
