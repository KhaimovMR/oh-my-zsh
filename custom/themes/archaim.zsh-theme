# vim:ft=zsh ts=2 sw=2 sts=2
#
# agnoster's Theme - https://gist.github.com/3712874
# A Powerline-inspired theme for ZSH
#
# # README
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://github.com/Lokaltog/powerline-fonts).
# Make sure you have a recent version: the code points that Powerline
# uses changed in 2012, and older versions will display incorrectly,
# in confusing ways.
#
# In addition, I recommend the
# [Solarized theme](https://github.com/altercation/solarized/) and, if you're
# using it on Mac OS X, [iTerm 2](https://iterm2.com/) over Terminal.app -
# it has significantly better color fidelity.
#
# If using with "light" variant of the Solarized color schema, set
# SOLARIZED_THEME variable to "light". If you don't specify, we'll assume
# you're using the "dark" variant.
#
# # Goals
#
# The aim of this theme is to only show you *relevant* information. Like most
# prompts, it will only show git information when in a git working directory.
# However, it goes a step further: everything from the current user and
# hostname to whether the last call exited with an error to whether background
# jobs are running in this shell will all be displayed automatically when
# appropriate.

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

bg_black=233
bg_dark_grey=235
bg_blue=025
bg_light_light_blue=024
bg_light_green=065
bg_light_blue=081
bg_white=015
bg_yellow=142
#bg_green=002
bg_green=076
bg_red=001
fg_light_green=010
fg_red=009
fg_black=016
fg_white=015
fg_blue=012
fg_yellow=011
fg_light_grey=252

CURRENT_BG=$bg_black
HAVE_STATUS_ICON=false
RE_NUMBER='^[0-9]+$'

case ${SOLARIZED_THEME:-dark} in
    light) CURRENT_FG='white';;
    *)     CURRENT_FG='black';;
esac

# Special Powerline characters

() {
  local LC_ALL="" LC_CTYPE="en_US.UTF-8"
  # NOTE: This segment separator character is correct.  In 2012, Powerline changed
  # the code points they use for their special characters. This is the new code point.
  # If this is not working for you, you probably have an old version of the
  # Powerline-patched fonts installed. Download and install the new version.
  # Do not submit PRs to change this unless you have reviewed the Powerline code point
  # history and have new information.
  # This is defined using a Unicode escape sequence so it is unambiguously readable, regardless of
  # what font the user is viewing this source code in. Do not replace the
  # escape sequence with a single literal character.
  # Do not change this! Do not make it '\u2b80'; that is the old, wrong code point.
  SEGMENT_SEPARATOR=$'\ue0b0'
}

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg whitespace separator
  local show_prefix=true
  local bold_prefix=""
  local bold_suffix=""
  #[[ -n $1 ]] && bg="%{$BG[$bg_red]%}" || bg="%k"
  bg="$BG[$1]"
  fg="$FG[$2]"
  [[ -n $4 ]] && show_prefix=$4
  [[ -n $5 ]] && bold_prefix="%B" && bold_suffix="%b"
  [[ $show_prefix == false ]] && whitespace="" || whitespace=" "
  [[ $show_prefix == false ]] && separator="" || separator="$SEGMENT_SEPARATOR"
  
  echo -n "%{$BG[$CURRENT_BG]%}$whitespace%{$bg%}%{$FG[$CURRENT_BG]%}$separator$bold_prefix%{$fg%}"
  #echo -n "%B****%{$fg%}====%b"
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3$bold_suffix
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n "%{$BG[$CURRENT_BG]%} %{%k%{$FG[$CURRENT_BG]%}%}$SEGMENT_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}"
  CURRENT_BG=''
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
prompt_context() {
  local show_prefix=false
  local context_prefix=""
  [[ $HAVE_STATUS_ICON == true ]] && show_prefix=true && context_prefix=" "
  if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment $bg_dark_grey $bg_white "$context_prefix%B%(!.%{$FG[$fg_red]%}.%{$FG[$fg_light_green]%})%n%{%F{blue}%}@%{%(!.%{$FG[$fg_red]%}.%{$FG[$fg_light_green]%})%}%M%b" $show_prefix
  fi
}

# Git: branch/detached head, dirty status
prompt_git() {
  (( $+commands[git] )) || return
  if [[ "$(git config --get oh-my-zsh.hide-status 2>/dev/null)" = 1 ]]; then
    return
  fi
  local PL_BRANCH_CHAR
  () {
    local LC_ALL="" LC_CTYPE="en_US.UTF-8"
    PL_BRANCH_CHAR=$'\ue0a0'         # 
  }
  local ref dirty mode repo_path

  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    repo_path=$(git rev-parse --git-dir 2>/dev/null)
    dirty=$(parse_git_dirty)
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git rev-parse --short HEAD 2> /dev/null)"

    if [[ -n $dirty ]]; then
      prompt_segment $bg_yellow $fg_black "" true true
    else
      if [[ -n $(git status | grep -o 'branch is ahead') ]]; then # if up to date
        prompt_segment $bg_green $fg_black "" true true
      else # if has the commits ahead
        prompt_segment $bg_light_green $fg_white "" true true
      fi
    fi

    if [[ -e "${repo_path}/BISECT_LOG" ]]; then
      mode=" <B>"
    elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
      mode=" >M<"
    elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
      mode=" >R>"
    fi

    setopt promptsubst
    autoload -Uz vcs_info

    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*' get-revision true
    zstyle ':vcs_info:*' check-for-changes true
    zstyle ':vcs_info:*' stagedstr '✚'
    zstyle ':vcs_info:*' unstagedstr '●'
    zstyle ':vcs_info:*' formats ' %u%c'
    zstyle ':vcs_info:*' actionformats ' %u%c'
    vcs_info
    echo -n "${ref/refs\/heads\//$PL_BRANCH_CHAR }${vcs_info_msg_0_%% }${mode}%b"
  fi
}

prompt_bzr() {
    (( $+commands[bzr] )) || return
    if (bzr status >/dev/null 2>&1); then
        status_mod=`bzr status | head -n1 | grep "modified" | wc -m`
        status_all=`bzr status | head -n1 | wc -m`
        revision=`bzr log | head -n2 | tail -n1 | sed 's/^revno: //'`
        if [[ $status_mod -gt 0 ]] ; then
            prompt_segment $bg_yellow $fg_black
            echo -n "bzr@"$revision "✚ "
        else
            if [[ $status_all -gt 0 ]] ; then
                prompt_segment $bg_yellow $fg_black
                echo -n "bzr@"$revision
            else
                prompt_segment $bg_green $fg_black
                echo -n "bzr@"$revision
            fi
        fi
    fi
}

prompt_hg() {
  (( $+commands[hg] )) || return
  local rev st branch
  if $(hg id >/dev/null 2>&1); then
    if $(hg prompt >/dev/null 2>&1); then
      if [[ $(hg prompt "{status|unknown}") = "?" ]]; then
        # if files are not added
        prompt_segment $bg_red $fg_white
        st='±'
      elif [[ -n $(hg prompt "{status|modified}") ]]; then
        # if any modification
        prompt_segment $bg_yellow $fg_black
        st='±'
      else
        # if working copy is clean
        prompt_segment $bg_green $CURRENT_FG
      fi
      echo -n $(hg prompt "☿ {rev}@{branch}") $st
    else
      st=""
      rev=$(hg id -n 2>/dev/null | sed 's/[^-0-9]//g')
      branch=$(hg id -b 2>/dev/null)
      if `hg st | grep -q "^\?"`; then
        prompt_segment $bg_red $fg_black
        st='±'
      elif `hg st | grep -q "^[MA]"`; then
        prompt_segment $bg_yellow $fg_black
        st='±'
      else
        prompt_segment $bg_green $CURRENT_FG
      fi
      echo -n "☿ $rev@$branch" $st
    fi
  fi
}

# Dir: current working directory
prompt_dir() {
  prompt_segment $bg_light_light_blue $fg_light_grey " %~" true true
}

# Virtualenv: current working virtualenv
prompt_virtualenv() {
  local virtualenv_path="$VIRTUAL_ENV"
  if [[ -n $virtualenv_path && -n $VIRTUAL_ENV_DISABLE_PROMPT ]]; then
    prompt_segment $bg_blue $fg_black "(`basename $virtualenv_path`)"
  fi
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  local -a symbols

  [[ $RETVAL -ne 0 ]] && symbols+=" %{$FG[$fg_red]%}✘"
  [[ $UID -eq 0 ]] && symbols+=" %{$FG[$fg_red]%}⚡"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+=" %{%F{cyan}%}⚙"

  [[ -n "$symbols" ]] && prompt_segment $bg_black default "$symbols" false && HAVE_STATUS_ICON=true
}

#AWS Profile:
# - display current AWS_PROFILE name
# - displays yellow on red if profile name contains 'production' or
#   ends in '-prod'
# - displays black on green otherwise
prompt_aws() {
  [[ -z "$AWS_PROFILE" ]] && return
  case "$AWS_PROFILE" in
    *-prod|*production*) prompt_segment $bg_red $fg_yellow  "AWS: $AWS_PROFILE" ;;
    *) prompt_segment $bg_green $fg_black "AWS: $AWS_PROFILE" ;;
  esac
}

## Main prompt
build_prompt() {
  RETVAL=$?
  prompt_status
  prompt_virtualenv
  prompt_aws
  prompt_context
  prompt_dir
  prompt_git
  prompt_bzr
  prompt_hg
  prompt_end
}

PROMPT='%{%f%b%k%}$(build_prompt) '
