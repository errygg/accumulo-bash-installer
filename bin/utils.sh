# START utils.sh

log() {
    local MESSAGE=$1
    local COLOR=$2
    if [ "${LOG_FILE}x" != "x" ] && [ -e "${LOG_FILE}" ]; then
        echo -e "${INDENT}${MESSAGE}" >> $LOG_FILE
    fi
    if [ "${COLOR}x" == "x" ]; then
        echo -e "${INDENT}${MESSAGE}"
    else
       # TODO: test on linux, works on Mac OSX
        echo -n -e "\033[0;${COLOR}m"
        echo -e  "${INDENT}${MESSAGE}"
        echo -n -e "\033[0m"
    fi
}

yellow() {
    log "$1" "33"
}

red() {
    log "$1" "31"
}

green() {
    log "$1" "32"
}

blue() {
    log "$1" "34"
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

# END utils.sh
