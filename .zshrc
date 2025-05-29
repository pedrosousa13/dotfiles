# Amazon Q pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh"
# secrets management
export DOTFILES_DIR="${HOME}/dotfiles"
secrets_out_path="${DOTFILES_DIR}/zsh/secrets-out.zsh"

if [ ! -f "$secrets_out_path" ]; then
    echo "Creating ${secrets_out_path}..."
    op --account "my.1password.com" read op://Personal/zshrc_secrets/notesPlain --out-file "${DOTFILES_DIR}/zsh/secrets-out.zsh"
fi

alias update-secrets='rm "${DOTFILES_DIR}/zsh/secrets-out.zsh" && op --account "my.1password.com" read op://Personal/zshrc_secrets/notesPlain --out-file "${DOTFILES_DIR}/zsh/secrets-out.zsh" && source "${DOTFILES_DIR}/zsh/secrets-out.zsh"'
source "${DOTFILES_DIR}/zsh/secrets-out.zsh"

if [[ -f "/opt/homebrew/bin/brew" ]] then
  # If you're using macOS, you'll want this enabled
  eval "$(/opt/homebrew/bin/brew shellenv)"
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

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Add in snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found

# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q

eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/catppuccin_frappe.omp.json)"

if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  eval "$(oh-my-posh init zsh)"
fi

# Keybindings
bindkey -e
# completion using arrow keys (based on history)
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
bindkey '^[w' kill-region

# History
HISTSIZE=5000
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


# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

if type brew &>/dev/null; then
    FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
    autoload -Uz compinit
    compinit
fi

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

# env
export PATH="$(yarn global bin):$PATH"

# fnm
export PATH="/Users/pedrosousa/Library/Application Support/fnm:$PATH"
eval "$(fnm env --use-on-cd)"


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

# Amazon Q post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh"

