# START utils.sh

log() {
    local MESSAGE=$1
    if [ "${LOG_FILE}x" != "x" ] && [ -e "${LOG_FILE}" ]; then
        echo -e "${INDENT}${MESSAGE}" >> $LOG_FILE
    fi
    echo -e "${INDENT}${MESSAGE}"
}

yellow() {
   log "${_yellow}$1${_normal}"
}

red() {
   log "${_red}$1${_normal}"
}

green() {
   log "${_green}$1${_normal}"
}

blue() {
   log "${_blue}$1${_normal}"
}

light_blue() {
   log "${_light_blue}$1${_normal}"
}

_blue=$(tput setaf 4)
_green=$(tput setaf 2)
_red=$(tput setaf 1)
_yellow=$(tput setaf 3)
_light_blue=$(tput setaf 6)
_normal=$(tput sgr0)

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
    if [ "${LOG_FILE}x" != "x" ] && [ -e "${LOG_FILE}" ]; then
        echo -e "${INDENT}${PROMPT}: ${input}" >> $LOG_FILE
    fi
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
