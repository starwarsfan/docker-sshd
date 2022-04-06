#!/bin/bash
# ============================================================================
#
# Created: 2022-04-06 Y. Schumann
#
# Helper script for formated output messages
#
# ============================================================================

_init() {
    if [[ -n "${TERM}" && "${TERM}" != "dumb" ]]; then
#        GREEN=$(tput setaf 2) RED=$(tput setaf 1) BLUE="$(tput setaf 4)"
#        LTGREYBG="$(tput setab 7)"
#        NORMAL=$(tput sgr0) BLINK=$(tput blink)
        GREEN='\e[0;32m' RED='\e[0;31m' BLUE='\e[0;34m' NORMAL='\e[0m'
    else
        GREEN="" RED="" BLUE="" LTGREYBG="" NORMAL="" BLINK=""
    fi
}
die() {
    error=${1:-1}
    shift
    error "$*" >&2
    exit ${error}
}
info() {
    printf "${GREEN}%-7s: %s${NORMAL}\n" "Info" "$*"
}
error() {
    printf "${RED}%-7s: %s${NORMAL}\n" "Error" "$*"
}
warning() {
    printf "${BLUE}%-7s: %s${NORMAL}\n" "Warning" "$*"
}

executeCommand() {
    local _command="$1"
    local _returnCodeForError="$2"
    echo "Executing '${_command}'"
    eval "${_command}"
    evaluateRtc $? ${_returnCodeForError}
}

evaluateRtc(){
    local _givenRtc=$1
    local _returnCodeForError=$2
    if [[ ${_givenRtc} -ne 0 ]] ; then
        if [[ -z "$_returnCodeForError" ]] ; then
            die 80 "Error occurred!"
        else
            die ${_returnCodeForError} "Error occurred! (${_returnCodeForError})"
        fi
    fi
}
