# ---- Interactive only ----
[[ -o interactive ]] || return

# ---- Environment ----
# Homebrew on Linux
if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

export EDITOR="code --wait"
export VISUAL="code --wait"

typeset -U path PATH

# ---- Navigation ----
setopt AUTO_CD
cdpath=(~ ~/projects)

# ---- Key bindings ----
bindkey '^[[1;5D' backward-word        # Ctrl+Left
bindkey '^[[1;5C' forward-word         # Ctrl+Right
bindkey '^H'      backward-kill-word   # Ctrl+Backspace

# ---- History ----
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_VERIFY
setopt EXTENDED_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

# ---- Completion ----
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

eval "$(dircolors -b)"
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# ---- Prompt (Agnoster-style) ----
setopt PROMPT_SUBST
autoload -Uz vcs_info add-zsh-hook

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr '+'
zstyle ':vcs_info:git:*' unstagedstr '!'
zstyle ':vcs_info:git:*' formats '%b %u%c'
zstyle ':vcs_info:git:*' actionformats '%b (%a) %u%c'

_prompt_sep=$'\ue0b0'
_prompt_branch=$'\ue0a0'
_prompt_esc=$'\e'

_pseg() {
  local bg=$1 fg=$2 text=$3
  local r g b
  r=$((16#${bg:1:2})) g=$((16#${bg:3:2})) b=$((16#${bg:5:2}))
  local bg_seq="${_prompt_esc}[48;2;${r};${g};${b}m"
  r=$((16#${fg:1:2})) g=$((16#${fg:3:2})) b=$((16#${fg:5:2}))
  local fg_seq="${_prompt_esc}[38;2;${r};${g};${b}m"
  if [[ -n $_prompt_bg ]]; then
    r=$((16#${_prompt_bg:1:2})) g=$((16#${_prompt_bg:3:2})) b=$((16#${_prompt_bg:5:2}))
    local prev_fg="${_prompt_esc}[38;2;${r};${g};${b}m"
    _prompt_str+="%{${bg_seq}${prev_fg}%}${_prompt_sep}%{${fg_seq}%} $text "
  else
    _prompt_str+="%{${bg_seq}${fg_seq}%} $text "
  fi
  _prompt_bg=$bg
}

_my_precmd() {
  local RETVAL=$?
  vcs_info
  if [[ "$(git rev-parse --is-bare-repository 2>/dev/null)" == "true" ]]; then
    vcs_info_msg_0_=""
  fi

  _prompt_bg=''
  _prompt_str=''

  # Status indicators (error, root, background jobs)
  local sym=''
  [[ $RETVAL -ne 0 ]] && sym+=$'\u2718 '
  [[ $UID -eq 0 ]] && sym+=$'\u26a1 '
  [[ $(jobs -l 2>/dev/null | wc -l) -gt 0 ]] && sym+=$'\u2699 '
  [[ -n $sym ]] && _pseg '#1a1b26' '#e0af68' "${sym% }"

  # User@Host
  _pseg '#9ece6a' '#1a1b26' '%n@%m'

  # Directory
  _pseg '#7aa2f7' '#1a1b26' '%~'

  # Git
  if [[ -n ${vcs_info_msg_0_} ]]; then
    if [[ ${vcs_info_msg_0_} == *'!'* || ${vcs_info_msg_0_} == *'+'* ]]; then
      _pseg '#ff9e64' '#1a1b26' "${_prompt_branch} ${vcs_info_msg_0_}"
    else
      _pseg '#e0af68' '#1a1b26' "${_prompt_branch} ${vcs_info_msg_0_}"
    fi
  fi

  # End
  local r=$((16#${_prompt_bg:1:2})) g=$((16#${_prompt_bg:3:2})) b=$((16#${_prompt_bg:5:2}))
  _prompt_str+="%{${_prompt_esc}[49m${_prompt_esc}[38;2;${r};${g};${b}m%}${_prompt_sep}%{${_prompt_esc}[0m%} "
  PROMPT="$_prompt_str"
}
add-zsh-hook precmd _my_precmd

# ---- Aliases ----
alias ll='eza -alF --group-directories-first'
alias la='eza -a'
alias ls='eza'
alias l='eza'
alias python=python3
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias diff='diff --color=auto'
alias ip='ip --color=auto'

# ---- Plugins ----
[[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ---- Tool hooks ----
eval "$(direnv hook zsh)"
source /usr/share/doc/fzf/examples/key-bindings.zsh
source /usr/share/doc/fzf/examples/completion.zsh
eval "$(zoxide init zsh)"

# ---- Functions ----
gwa() {
  local branch=$1
  if [[ -z "$branch" ]]; then
    echo "Usage: gwa <branch-name>"
    return 1
  fi

  # Resolve git root so this works from any worktree or subdirectory
  local git_root
  git_root=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null | sed 's|/\.git$||')
  if [[ -z "$git_root" ]]; then
    echo "Error: not inside a git repository"
    return 1
  fi

  local folder="${branch//\//-}"
  local worktree_path="$git_root/$folder"

  # Bail early if folder already exists
  if [[ -d "$worktree_path" ]]; then
    echo "Worktree folder already exists: $worktree_path"
    cd "$worktree_path" || return
    return 0
  fi

  # Fetch latest remote refs
  git -C "$git_root" fetch --quiet

  if git -C "$git_root" rev-parse --verify "$branch" >/dev/null 2>&1 || \
     git -C "$git_root" rev-parse --verify "origin/$branch" >/dev/null 2>&1; then
    echo "Creating worktree for existing branch: $branch"
    git -C "$git_root" worktree add "$worktree_path" "$branch"
  else
    # Detect base branch dynamically
    local base
    base=$(git -C "$git_root" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
    if [[ -z "$base" ]]; then
      if git -C "$git_root" rev-parse --verify main >/dev/null 2>&1; then
        base=main
      elif git -C "$git_root" rev-parse --verify master >/dev/null 2>&1; then
        base=master
      else
        echo "Error: cannot determine base branch"
        return 1
      fi
    fi
    echo "Creating new branch and worktree: $branch (based on $base)"
    git -C "$git_root" worktree add -b "$branch" "$worktree_path" "origin/$base"
    git -C "$git_root" branch --set-upstream-to="origin/$base" "$branch"
  fi

  cd "$worktree_path" || return

  if [[ -f "$git_root/envrc.template" ]]; then
    ln -sf "$git_root/envrc.template" .envrc
    echo "Linked envrc.template"
  fi

  direnv allow
  echo "Worktree ready in: $worktree_path"
}

gclone() {
  local url=$1
  if [[ -z "$url" ]]; then
    echo "Usage: gclone <remote-url> [project-dir-name]"
    return 1
  fi

  local dir_name=$2
  if [[ -z "$dir_name" ]]; then
    dir_name=$(basename "$url" .git)
  fi

  echo "Setting up project in: $dir_name"
  mkdir -p "$dir_name" && cd "$dir_name" || return

  echo "Cloning bare repository..."
  git clone --bare "$url" .git

  echo "Configuring remote fetch refspec..."
  git --git-dir=.git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"

  echo "Fetching remote data..."
  git --git-dir=.git fetch origin

  if git --git-dir=.git show-ref --verify --quiet refs/remotes/origin/main; then
    git --git-dir=.git worktree add main main
  else
    git --git-dir=.git worktree add main master
  fi

  echo "Done! Bare repo initialized and 'main' worktree created."
  cd main || return
}
