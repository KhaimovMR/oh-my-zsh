# "#CUR" (without the quotes) in the ealias is where the cursor will move on expand
typeset -a ealiases
ealiases=()

function ealias()
{
    alias $1
    ealiases+=(${1%%\=*})
}

function expand-ealias()
{
    if [[ $LBUFFER =~ "\<(${(j:|:)ealiases})\$" ]]; then
        zle _expand_alias
        zle expand-word
    fi
    
    if [[ $BUFFER =~ '#CUR' ]]; then
        while [[ ! $RBUFFER =~ '#CUR' ]]; do
            zle backward-char
        done

        zle delete-char
        zle delete-char
        zle delete-char
        zle delete-char
    else
        zle magic-space
    fi
}

zle -N expand-ealias

bindkey -M main ' '        expand-ealias
bindkey -M main '^ '       magic-space     # control-space to bypass completion
bindkey -M isearch " "      magic-space     # normal space during searches
