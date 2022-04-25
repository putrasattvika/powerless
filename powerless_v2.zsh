################################################
### This is the ZSH powerless main script.
###
### How to call: sou############################

# Set options and settings.
setopt PROMPT_SUBST
setopt PROMPT_SP

typeset -AHg FX FG BG

FX=(
    reset     "%{[00m%}"
    bold      "%{[01m%}" no-bold      "%{[22m%}"
    italic    "%{[03m%}" no-italic    "%{[23m%}"
    underline "%{[04m%}" no-underline "%{[24m%}"
    blink     "%{[05m%}" no-blink     "%{[25m%}"
    reverse   "%{[07m%}" no-reverse   "%{[27m%}"
)

for color in {000..032}; do
    FG[$color]="%{[38;5;${color}m%}"
    BG[$color]="%{[48;5;${color}m%}"
done

# Specify colors.
if [[ $1 == true ]]; then
  color_text="0"
  color_user_host="79"
  color_code_wrong="196"
  color_pwd="75"
  color_git_ok="79"
  color_git_dirty="203"
  color_venv="33"
else
  color_text="016"   # black
  color_user_host="002"   # green
  color_code_wrong="009"   # red
  color_pwd="004"   # blue
  color_git_ok="002"   # green
  color_git_dirty="009"   # red
  color_git_staged="003"   # yellow
  color_venv="006"   # yellow
  color_prompt_bg="015"   # white
fi

# Specify common variables.
days=(月 火 水 木 金 土 日)
days_color=(163 202 004 034 179 130 185)
bold_start='%{%B%}'
bold_end='%{%b%}'

get-dow-kanji() {
  echo -n "${days[$(date +%u)]}"
}

get-dow-color() {
  echo -n "${days_color[$(date +%u)]}"
}

begin-color() {
  echo -n "%{$FG[$1]%}%{$BG[$2]%}"
}

end-color() {
  echo -n "%{$reset_color%}"
}

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
  [[ -n "$SSH_CLIENT" ]] && echo -n "$bold_start$(begin-color $1 $2) %n@%M $bold_end$(end-color)"
}

get-git-brach() { 
  branch=$(git symbolic-ref --short HEAD 2> /dev/null)
  branch_exit_code="$?"

  tags=$(git tag -l --points-at HEAD 2> /dev/null | sed -z 's/\n/,/g' | head -c -1)
  tag_exit_code="$?"

  commit_hash=$(git rev-parse HEAD 2> /dev/null | head -c 7)
  commit_exit_code="$?"

  if [[ "$branch_exit_code" == "0" ]]; then
    echo "$branch"
  elif [[ "$tag_exit_code" == "0" ]] && [[ -n "$tags" ]]; then
    echo "tag:$tags"
  elif [[ "$commit_exit_code" == "0" ]]; then
    echo "$commit_hash"
  fi

  return 1
}

get-pwd() {
  local git_branch=$1
  local current_path=$(print -rD $PWD)

  if [[ -n "$git_branch" ]]; then
    current_path="/$(git rev-parse --show-prefix)"
  fi

  current_path=$(truncate-path $current_path)

  echo -n "$bold_start$(begin-color $2 $3) $current_path $bold_end$(end-color)"
}

get-git-info() { 
  local git_branch=$1
   
  if [[ -n "$git_branch" ]]; then
    # Unstaged changes
    git diff --quiet --ignore-submodules --exit-code HEAD > /dev/null 2>&1
        
    if [[ "$?" != "0" ]]; then
      git_symbols="$(begin-color $2 $4) Δ $(end-color)"
    fi

    # Staged changes
    git diff --quiet --ignore-submodules --name-only --cached --exit-code HEAD > /dev/null 2>&1

    if [[ "$?" != "0" ]]; then
      git_symbols="$(begin-color $2 $5) + $(end-color)"
    fi

    IFS='/' read -rA origin <<< $(git config --get remote.origin.url)
    local repo_name="${origin[-1]%.*}"
  
    echo -n "$bold_start$git_symbols$bold_end$bold_start$(begin-color $2 $3) $repo_name|$git_branch $bold_end$(end-color)"
  fi
}
get-venv-info() { 
  if [ -n "$VIRTUAL_ENV" ]; then 
    echo -n "$bold_start$(begin-color $1 $2) $(basename $VIRTUAL_ENV) $bold_end$(end-color)" 
  fi
} 

get-newline() { 
  echo -n "\n$(end-color)"
}

get-prompt() {
  local prompt_fg="$(get-dow-color)"
  local bg="$2"

  if [[ (-n "$last_code") && ($last_code -ne 0) ]]; then
    prompt_fg="$1"
    bg="$3"
  fi

  local prompt_time="$(begin-color $1 $bg)$bold_start $(date '+%d %H%M') $bold_end$(end-color)"
  local prompt_day="$(begin-color $prompt_fg $bg)$(get-dow-kanji) $(end-color) "

  echo -n "$prompt_time$prompt_day"
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
