# zmodload zsh/zprof
export DOTFILES_DIR="${HOME}/dotfiles"
secrets_out_path="${DOTFILES_DIR}/zsh/secrets-out.zsh"

# secrets management
if [ ! -f "$secrets_out_path" ]; then
    echo "Creating ${secrets_out_path}..."
    op --account "my.1password.com" read op://Personal/zshrc_secrets/notesPlain --out-file "${DOTFILES_DIR}/zsh/secrets-out.zsh"
fi

alias update-secrets='rm "${DOTFILES_DIR}/zsh/secrets-out.zsh" && op --account "my.1password.com" read op://Personal/zshrc_secrets/notesPlain --out-file "${DOTFILES_DIR}/zsh/secrets-out.zsh" && source "${DOTFILES_DIR}/zsh/secrets-out.zsh"'
source "${DOTFILES_DIR}/zsh/secrets-out.zsh"

# Inlined `brew shellenv` output — saves ~30ms fork; path_helper already ran via /etc/zprofile
if [[ -f "/opt/homebrew/bin/brew" ]] then
  export HOMEBREW_PREFIX="/opt/homebrew" HOMEBREW_CELLAR="/opt/homebrew/Cellar" HOMEBREW_REPOSITORY="/opt/homebrew"
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
  export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"
  fpath[1,0]="/opt/homebrew/share/zsh/site-functions"
  export FPATH
fi


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
if [[ "$TERM_PROGRAM" != "WarpTerminal" ]]; then
  # syntax highlighting via zsh-patina (activated at end of file);
  # fall back to zsh-syntax-highlighting on machines without the binary
  if ! command -v zsh-patina >/dev/null; then
    zinit ice wait lucid
    zinit light zsh-users/zsh-syntax-highlighting
  fi

  zinit ice wait lucid
  zinit light zsh-users/zsh-autosuggestions

  zinit ice wait lucid
  zinit light Aloxaf/fzf-tab
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

# Starship prompt (faster than oh-my-posh)
# Warp renders its own native prompt (HonorPS1=false) — starship would fork on every Enter for nothing
if [[ "$TERM_PROGRAM" != "WarpTerminal" ]]; then
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
alias vim='nvim'
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

# docker
alias doup="docker-compose up -d"
alias dodo="docker-compose down"
alias dodov="docker-compose down -v"

# nx
alias nx="npx nx"

# prisma
alias studio="npx prisma studio"
alias dbpush="npx prisma db push"
alias pformat="npx prisma format"

# weather
alias lu="curl 'wttr.in/Luzern?Fn2'"
alias we="curl 'wttr.in/?Fn2'"

alias claudy="claude --dangerously-skip-permissions"

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
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

# cli plugins
alias cat="bat"

#---- Eza (better ls) -----
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
export PATH="/Users/pedrosousa/Library/Application Support/fnm:$PATH"
eval "$(fnm env --use-on-cd --shell zsh)"


# Android SDK/Studio
#export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home
#export ANDROID_HOME=$HOME/Library/Android/sdk
#export PATH=$PATH:$ANDROID_HOME/emulator
#export PATH=$PATH:$ANDROID_HOME/platform-tools

# Rust
export PATH="$HOME/.cargo/bin:$PATH"

# Q post block. Keep at the bottom of this file.
# GPG
export GPG_TTY=$(tty)

# pnpm
export PNPM_HOME="/Users/pedrosousa/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
export PATH="$HOME/.local/bin:$PATH"

# opencode
export PATH=/Users/pedrosousa/.opencode/bin:$PATH

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
[ -s "/Users/pedrosousa/.bun/_bun" ] && source "/Users/pedrosousa/.bun/_bun"

# zsh-patina syntax highlighting — must stay at end of file, zle terminals only
if [[ "$TERM_PROGRAM" != "WarpTerminal" ]] && command -v zsh-patina >/dev/null; then
  eval "$(zsh-patina activate)"
fi
