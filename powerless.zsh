################################################
### This is the ZSH powerless main script.
###
### How to call: source powerless.zsh <ENABLE_CUSTOM_COLORS>
################################################

# Set options and settings.
setopt PROMPT_SUBST
setopt PROMPT_SP

# Specify colors.
if [[ $1 == true ]]; then
  color_text="0"
  color_user_host="79"
  color_code_wrong="196"
  color_pwd="75"
  color_git_ok="79"
  color_git_dirty="203"
  color_git_staged="yellow"
  color_venv="33"
  color_prompt_bg="white"
else
  color_text="black"
  color_user_host="green"
  color_code_wrong="red"
  color_pwd="blue"
  color_git_ok="green"
  color_git_dirty="red"
  color_git_staged="yellow"
  color_venv="yellow"
  color_prompt_bg="white"
fi

# Specify common variables.
prompt_char="Ξ"
rc='%{%f%k%E%}'
bold_start='%{%B%}'
bold_end='%{%b%}'

truncate-path() {
  local current_path=$1
  local prefix=''

  if [[ '~' = "${current_path:0:1}" ]]; then
    current_path=${current_path:1}
    prefix='~'
  fi

  IFS='/' read -rA dirs <<< $current_path

  if [[ ${#dirs} -gt 3 ]]; then
    printf "../%s/%s" $dirs[-2] $dirs[-1]
  else
    printf "%s%s" $prefix $current_path
  fi
}


get-user-host() {  
  [[ -n "$SSH_CLIENT" ]] && echo -n "$bold_start%{%F{$1}%K{$2}%} %n@%M $bold_end$rc"
}

get-git-brach() { 
  echo $(git symbolic-ref --short HEAD 2> /dev/null)
}

get-pwd() {
  local git_branch=$1
  local current_path=$(print -rD $PWD)

  if [[ -n "$git_branch" ]]; then
    current_path="/$(git rev-parse --show-prefix)"
  fi

  current_path=$(truncate-path $current_path)

  echo -n "$bold_start%{%F{$2}%K{$3}%} $current_path $bold_end$rc"
}

get-git-info() { 
  local git_branch=$1
   
  if [[ -n "$git_branch" ]]; then
    # Unstaged changes
    git diff --quiet --ignore-submodules --exit-code HEAD > /dev/null 2>&1
        
    if [[ "$?" != "0" ]]; then
      git_symbols="%{%F{$2}%K{$4}%} Δ "
    fi

    # Staged changes
    git diff --quiet --ignore-submodules --name-only --cached --exit-code HEAD > /dev/null 2>&1

    if [[ "$?" != "0" ]]; then
      git_symbols="%{%F{$2}%K{$5}%} + "
    fi

    IFS='/' read -rA origin <<< $(git config --get remote.origin.url)
    local repo_name="${origin[-1]%.*}"
  
    echo -n "$bold_start$git_symbols%{%F{$2}%K{$3}%} $repo_name|$git_branch $bold_end$rc"
  fi
}

get-venv-info() {
    if [ -n "$VIRTUAL_ENV" ]; then
        echo -n "$bold_start%{%F{$1}%K{$2}%} $(basename $VIRTUAL_ENV) $bold_end$rc"
    fi
}

get-newline() {
  echo -n "\n$rc" 
}

get-prompt() {
  local prompt="$(date +%H%M) $prompt_char"
  local bg="$2"

  if [[ (-n "$last_code") && ($last_code -ne 0) ]]; then
    bg="$3"
  fi

  echo -n "$bold_start%{%F{$1}%K{$bg}%} $prompt $rc$bold_end "
}

powerless-prompt() {
  local git_branch=$(get-git-brach)

  get-venv-info $color_text $color_venv
  get-user-host $color_text $color_user_host
  get-git-info "$git_branch" $color_text $color_git_ok $color_git_dirty $color_git_staged
  get-pwd "$git_branch" $color_text $color_pwd

  get-newline
  get-prompt $color_text $color_prompt_bg $color_code_wrong
}

precmd-powerless() {
  last_code=$?
  
  if [[ $is_first_prompt -eq 999 ]]; then
    echo -n "\n"
  else
    is_first_prompt=999
  fi
}

# Attach the hook functions.
[[ ${precmd_functions[(r)precmd-powerless]} != "precmd-powerless" ]] && precmd_functions+=(precmd-powerless)

# Set the prompts.
PROMPT='$(powerless-prompt)'
