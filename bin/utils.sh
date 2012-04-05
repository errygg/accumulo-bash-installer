# START utils.sh

# helpers to handle setting colors in the term
_blue=$(tput setaf 4)
_green=$(tput setaf 2)
_red=$(tput setaf 1)
_yellow=$(tput setaf 3)
_light_blue=$(tput setaf 6)
_normal=$(tput sgr0)

log() {
    local MESSAGE=$1
    if [ ! -z "$LOG_FILE" ] && [ -d "$(dirname $LOG_FILE)" ]; then
        echo -e "${INDENT}${MESSAGE}" >> $LOG_FILE
    fi
    echo -e "${INDENT}${MESSAGE}"
}

yellow() {
    # to alert the user to do something, like enter info
    log "${_yellow}$1${_normal}"
}

red() {
    # error message, something bad happened
    log "${_red}$1${_normal}"
}

green() {
    # everything is good
    log "${_green}$1${_normal}"
}

blue() {
    # doesn't mean anything, and hard to see.  Currently only used for debugging info
    log "${_blue}$1${_normal}"
}

light_blue() {
    # information log, different from system output
    log "${_light_blue}$1${_normal}"
}

abort() {
    local MESSAGE=$1
    echo
    red "Aborting..." 1>&2
    red "${MESSAGE}" 1>&2
    cleanup_from_abort
    exit 1
}

read_input() {
    local PROMPT=$1
    if [[ ! -n $PROMPT ]]; then
      abort "Script requested user input without a prompt message"
    fi
    local IPROMPT="${INDENT}${PROMPT}"
    read -p "${_yellow}${IPROMPT}:${_normal} " -e
    local input="${REPLY}"
    log "User entered (${PROMPT} : ${input})" 1>&2 # so it doesn't end up in the return
    echo "${input}"
}

_which_curl() {
    # pulled out to make it easier to test
    which curl
}

_which_gpg() {
    # pulled out to make it easier to test
    which gpg
}

check_curl() {
    if [ -z $CURL ]; then
        CURL=$(_which_curl) || abort "Could not find curl on your path"
    fi
}

check_gpg() {
    if [ -z $GPG ]; then
        GPG=$(_which_gpg) || abort "Could not find gpg on your path"
    fi
}

cleanup_from_abort() {
    if [ ! -z $NO_RUN ]; then
        # no need to cleanup, user specified --no-run
        return
    fi
    # stop accumulo if running
    # stop zookeeper if running
    # stop hadoop if running
    if [ -d "${HADOOP_HOME}" ] && [ $(jps -m | grep NameNode) ]; then
        red "Found hadoop, attempting to shutdown"
        sys "${HADOOP_HOME}/bin/stop-all.sh"
    fi
    move_log_file
    echo
}

move_log_file() {
    if [ -d "$INSTALL_DIR" ] && [ -e "$LOG_FILE" ]; then
        yellow "Review the log file in ${INSTALL_DIR}.  It is colored, so try the following command"
        log "less -R ${INSTALL_DIR}/$(basename $LOG_FILE)"
        mv "$LOG_FILE" "$INSTALL_DIR"
    elif [ -e "$LOG_FILE" ]; then
        yellow "Review the log file in ${LOG_FILE}.  It is colored, so try the following command"
        log "less -R ${LOG_FILE}"
    fi
}

sys() {
    local CMD=$1
    light_blue "Running system command '${CMD}'"
    # execute a system command, tee'ing the results to the log file
    ORIG_INDENT="${INDENT}" && INDENT=""
    log "---------------------system command output-----------------------"
    ${CMD} 2>&1 | tee -a "$LOG_FILE"
    log "---------------------end system command output-------------------"
    INDENT="${ORIG_INDENT}"
}

# END utils.sh
