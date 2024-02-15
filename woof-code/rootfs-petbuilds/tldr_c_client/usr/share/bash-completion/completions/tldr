# I don't use bash, but I remember this works.
# If anyone has an improved, and better version, go ahead, open a pull-request.
#
# Copyright (C) 2016 Arvid Gerstmann
#

# usage: _tldr_get_files [architecture] [semi-completed word to search]
_tldr_get_files() {
    find "$HOME"/.tldrc/tldr/pages/"$1" -name "$2"'*.md' -exec basename {} .md \;
}

_tldr_complete() {
    COMPREPLY=()
    local word="${COMP_WORDS[COMP_CWORD]}"
    local cmpl=""
    if [[ "$word" == "--"* ]] || [ -z "$word" ]; then
        cmpl=$'--help\n--color\n--platform\n--render\n--update\n--version\n--clear-cache\n--verbose\n--list'
    elif [[ "$word" == "-"* ]]; then
        cmpl=$'-h\n-C\n-p\n-r\n-u\n-v\n-c\n-V\n-l'
    elif [[ "$word" == *"/"* ]]; then # the file command will give an error if passed directly since this will be a directory name - an invalid command
        cmpl=""
    else
        if [ -d "$HOME/.tldrc/tldr/pages" ]; then
            local platform
            platform="$(uname)"
            cmpl="$(_tldr_get_files common "$word")"
            if [ "$platform" = "Darwin" ]; then
                cmpl="${cmpl}
$(_tldr_get_files osx "$word")"
            elif [ "$platform" = "Linux" ]; then
                cmpl="${cmpl}
$(_tldr_get_files linux "$word")"
            elif [ "$platform" = "SunOS" ]; then
                cmpl="${cmpl}
$(_tldr_get_files sunos "$word")"
            fi
        fi
    fi
    local cmpl_sorted_n_uniq
    cmpl_sorted_n_uniq=$(printf "%s" "$cmpl" | sort | uniq)
    COMPREPLY=( $(compgen -W "$cmpl_sorted_n_uniq" -- "$word") )
}
complete -F _tldr_complete tldr
