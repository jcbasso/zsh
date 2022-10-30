source ~/.zsh/gitstatus/gitstatus.plugin.zsh

local green='%{%F{green}%}'
local yellow='%{%F{yellow}%}'
local blue='%{%F{blue}%}'
local cyan='%{%F{cyan}%}'
local red='%{%F{red}%}'
local magenta='%{%F{magenta}%}'
local reset='%{%f%}'

function gitstatus_prompt_update() {
  emulate -L zsh
  typeset -g  GITSTATUS_PROMPT=''

  # Call gitstatus_query synchronously. Note that gitstatus_query can also be called
  # asynchronously; see documentation in gitstatus.plugin.zsh.
  gitstatus_query 'MY' || return 1  # error
  
  if [[ $VCS_STATUS_RESULT == 'ok-sync' ]] then
    local      clean="$green"
    local   modified="$yellow"
    local  untracked="$blue"
    local conflicted="$red"

    local p

    local where  # branch name, tag or commit
    if [[ -n $VCS_STATUS_LOCAL_BRANCH ]]; then
      where=" $VCS_STATUS_LOCAL_BRANCH"
    elif [[ -n $VCS_STATUS_TAG ]]; then
      p+='#'
      where=$VCS_STATUS_TAG
    else
      p+='@'
      where=${VCS_STATUS_COMMIT[1,8]}
    fi

    (( $#where > 32 )) && where[13,-13]=""  # truncate long branch names and tags
    p+="${clean}${where//\%/%%}"             # escape %

    # ⇣42 if behind the remote.
    (( VCS_STATUS_COMMITS_BEHIND )) && p+=" ${clean}⇣${VCS_STATUS_COMMITS_BEHIND}"
    # ⇡42 if ahead of the remote; no leading space if also behind the remote: ⇣42⇡42.
    (( VCS_STATUS_COMMITS_AHEAD && !VCS_STATUS_COMMITS_BEHIND )) && p+=" "
    (( VCS_STATUS_COMMITS_AHEAD  )) && p+="${clean}⇡${VCS_STATUS_COMMITS_AHEAD}"
    # ⇠42 if behind the push remote.
    (( VCS_STATUS_PUSH_COMMITS_BEHIND )) && p+=" ${clean}⇠${VCS_STATUS_PUSH_COMMITS_BEHIND}"
    (( VCS_STATUS_PUSH_COMMITS_AHEAD && !VCS_STATUS_PUSH_COMMITS_BEHIND )) && p+=" "
    # ⇢42 if ahead of the push remote; no leading space if also behind: ⇠42⇢42.
    (( VCS_STATUS_PUSH_COMMITS_AHEAD  )) && p+="${clean}⇢${VCS_STATUS_PUSH_COMMITS_AHEAD}"
    # *42 if have stashes.
    (( VCS_STATUS_STASHES        )) && p+=" ${clean}*${VCS_STATUS_STASHES}"
    # 'merge' if the repo is in an unusual state.
    [[ -n $VCS_STATUS_ACTION     ]] && p+=" ${conflicted}${VCS_STATUS_ACTION}"
    # ~42 if have merge conflicts.
    (( VCS_STATUS_NUM_CONFLICTED )) && p+=" ${conflicted}~${VCS_STATUS_NUM_CONFLICTED}"
    # +42 if have staged changes.
    (( VCS_STATUS_NUM_STAGED     )) && p+=" ${modified}+${VCS_STATUS_NUM_STAGED}"
    # !42 if have unstaged changes.
    (( VCS_STATUS_NUM_UNSTAGED   )) && p+=" ${modified}!${VCS_STATUS_NUM_UNSTAGED}"
    # ?42 if have untracked files. It's really a question mark, your font isn't broken.
    (( VCS_STATUS_NUM_UNTRACKED  )) && p+=" ${untracked}?${VCS_STATUS_NUM_UNTRACKED}"

    GITSTATUS_PROMPT="${p} "
  fi
  
  GITSTATUS_PROMPT+="${reset}"
  
  # Prompt
  local newline=$'\n'
  local priv="%(!.${cyan}.${yellow})%f"
  local pwd="${magenta}%~${reset}"

  PS1="%B${pwd} ${GITSTATUS_PROMPT:+ $GITSTATUS_PROMPT}${newline}"
  PS1+="${priv}%b "
  PS2="%B${priv}%b "
  # RPROMPT="%t"
}

# Start gitstatusd instance with name "MY". The same name is passed to
# gitstatus_query in gitstatus_prompt_update. The flags with -1 as values
# enable staged, unstaged, conflicted and untracked counters.
gitstatus_stop 'MY' && gitstatus_start -s -1 -u -1 -c -1 -d -1 'MY'

# On every prompt, fetch git status and set prompt.
autoload -Uz add-zsh-hook
add-zsh-hook precmd gitstatus_prompt_update

# Enable/disable the right prompt options.
setopt no_prompt_bang prompt_percent prompt_subst
