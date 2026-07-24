# Server-safe zsh config (Linux headless, no Warp/1Password/brew).
# Stow package: zsh-server. Mirrors ~/dotfiles/zsh/.zshrc's interactive stack
# (zinit + plugins + starship + history + keybindings) minus macOS-only bits.

# PATH: user-local bins (starship lives in ~/.local/bin)
for d in "$HOME/.local/bin" "$HOME/.cargo/bin" "$HOME/go/bin"; do
  [ -d "$d" ] && case ":$PATH:" in *":$d:"*) ;; *) PATH="$d:$PATH";; esac
done

# --- zinit bootstrap ---
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# --- plugins ---
zinit ice wait lucid
zinit light zsh-users/zsh-completions

zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions   # sync: reliable ghost-text over ssh/pty

# --- completions ---
fpath=(~/.zsh/completions $fpath)
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qNmh-24) ]]; then
  compinit -C
else
  compinit
fi
zinit cdreplay -q

# fzf-tab after compinit/cdreplay
command -v fzf >/dev/null && zinit light Aloxaf/fzf-tab

# --- prompt ---
command -v starship >/dev/null && eval "$(starship init zsh)"

# --- keybindings ---
bindkey -e
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
bindkey '^[w' kill-region
bindkey '^[[1;3D' backward-word        # alt+left
bindkey '^[[1;3C' forward-word         # alt+right
bindkey '^[^?' backward-kill-word      # alt+backspace
bindkey '^[[3;3~' kill-word            # alt+fn+delete

# --- history ---
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

# --- completion styling ---
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# --- aliases ---
alias c='clear'
command -v nvim >/dev/null && alias vim='nvim'

# git
alias gfp="git fetch && git pull"
alias gfd="git fetch origin develop:develop"
alias gfm="git fetch origin master:master"
alias glatest="git for-each-ref --sort=committerdate refs/heads/ --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))'"
alias gs="git status"
alias grh="git reset --hard && git clean -df"

# docker
alias doup="docker compose up -d"
alias dodo="docker compose down"
alias dodov="docker compose down -v"

# cli tool swaps (Debian binary-name quirks)
command -v batcat >/dev/null && alias cat="batcat"
command -v fdfind >/dev/null && alias fd="fdfind"
command -v eza >/dev/null && \
  alias ls="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions"

# --- shell integrations ---
# fzf: 0.48+ has `fzf --zsh`; older Debian pkg ships source files
if command -v fzf >/dev/null; then
  if fzf --zsh >/dev/null 2>&1; then
    eval "$(fzf --zsh)"
  else
    for f in /usr/share/doc/fzf/examples/key-bindings.zsh \
             /usr/share/doc/fzf/examples/completion.zsh \
             /usr/share/zsh/vendor-completions/_fzf; do
      [ -r "$f" ] && source "$f"
    done
  fi
fi

command -v zoxide >/dev/null && eval "$(zoxide init --cmd cd zsh)"

export GPG_TTY=$(tty)
