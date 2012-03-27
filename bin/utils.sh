# START utils.sh

cleanup_from_abort() {
    if [ ! -z $NO_RUN ]; then
        # no need to cleanup, user specified --no-run
        return
    fi
    # stop accumulo if running
    # stop zookeeper if running
    # stop hadoop if running
    if [ -d "${HADOOP_HOME}" ]; then
        red "Found hadoop, attempting to shutdown"
        "${HADOOP_HOME}/bin/stop-all.sh"
    fi
    # remove install directory (May have to pass this in)
    if [[ -d $INSTALL_DIR ]]; then
        red "Removing ${INSTALL_DIR}"
        rm -rf ${INSTALL_DIR}
    fi
    echo
}

log() {
    local MESSAGE=$1
    local INDENT=$2
    echo -e "${INDENT}${MESSAGE}" >> $LOG_FILE
    echo -e "${INDENT}${MESSAGE}"
}

color_log() {
    # TODO: test on linux, works on Mac OSX
    local COLOR=$1
    local MESSAGE=$2
    local INDENT=$3
    echo -n -e "\033[0;${COLOR}m"
    log "${MESSAGE}" "${INDENT}"
    echo -n -e "\033[0m"
}

yellow() {
    color_log "33" "$1" "$2"
}

red() {
    color_log "31" "$1" "$2"
}

green() {
    color_log "32" "$1" "$2"
}

blue() {
    color_log "34" "$1" "$2"
}

abort() {
    local MESSAGE=$1
    local INDENT=$2
    echo
    red "${INDENT}Aborting..."
    red "${INDENT}${MESSAGE}" 1>&2
    cleanup_from_abort
    exit 1
}

read_input() {
    local PROMPT=$1
    local INDENT=$2
    if [[ ! -n $PROMPT ]]; then
      abort "Script requested user input without a prompt message"
    fi
    read -p "${INDENT}${PROMPT}: " -e
    echo "${REPLY}"
}

check_curl() {
    if [ -z $CURL ]; then
        which curl > /dev/null && CURL=1
        if [ -z $CURL ]; then
          abort "Could not find curl on your path"
        fi
    fi
}

check_gpg() {
    if [ -z $GPG ]; then
        which gpg > /dev/null && GPG=1
        if [ -z $GPG ]; then
            abort "Could not find gpg on your path"
        fi
    fi
}

# END utils.sh
