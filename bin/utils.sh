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
    log "User entered (${PROMPT}: ${input})" 1>&2 # so it doesn't end up in the return
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
    if [ -z "$CURL" ]; then
        CURL=$(_which_curl) || abort "Could not find curl on your path"
    fi
}

check_gpg() {
    if [ -z "$GPG" ]; then
        GPG=$(_which_gpg) || abort "Could not find gpg on your path"
    fi
}

cleanup_from_abort() {
    if [ ! -z $NO_RUN ]; then
        # no need to cleanup, user specified --no-run
        return
    fi
    stop_accumulo
    stop_zookeeper
    stop_hadoop
    move_log_file
    light_blue "Cleanup finished"
    log ""
}

_jps() {
    # moved out to help test
    # return 0 if $1 found, 1 otherwise
    jps -m | grep "$1"
}

check_java_process() {
    local to_check=$1
    local process=""
    if [ "${to_check}" == "NameNode" ]; then
        process="Hadoop"
    elif [ "${to_check}" == "zookeeper" ]; then
        process="Zookeeper"
    elif [ "${to_check}" == "accumulo" ]; then
        process="Accumulo"
    else
        abort "Don't know how to check_java_process for ${to_check}"
    fi
    local running="not running"
    _jps "${to_check}" > /dev/null && running="running"
    echo "${process} ${running}"
}

stop_accumulo() {
    # stop accumulo if running
    # TODO: update process name
    local running=$(check_java_process "accumulo")
    if  [ "${running}" == "Accumulo running" ]; then
        red "Accumulo running, attempting to shut it down"
        if [ -d "$ACCUMULO_HOME" ]; then
            sys "${ACCUMULO_HOME}/bin/stop-all.sh"
        else
            red "Directory ${ACCUMULO_HOME} not found, can't shut it down"
        fi
    else
        red "Accumulo not running, nothing to stop"
    fi
}

stop_zookeeper() {
    # stop zookeeper if running
    # TODO: update process name
    local running=$(check_java_process "zookeeper")
    if  [ "${running}" == "Zookeeper running" ]; then
        red "Zookeeper running, attempting to shut it down"
        if [ -d "$ZOOKEEPER_HOME" ]; then
            sys "${ZOOKEEPER_HOME}/bin/zkStop.sh"
        else
            red "Directory ${ZOOKEEPER_HOME} not found, can't shut it down"
        fi
    else
        red "Zookeeper not running, nothing to stop"
    fi
}

stop_hadoop() {
    # stop hadoop if running
    local running=$(check_java_process "NameNode")
    if  [ "${running}" == "Hadoop running" ]; then
        red "Hadoop running, attempting to shut it down"
        if [ -d "$HADOOP_HOME" ]; then
            sys "${HADOOP_HOME}/bin/stop-all.sh"
        else
            red "Directory ${HADOOP_HOME} not found, can't shut it down"
        fi
    else
        red "Hadoop not running, nothing to stop"
    fi
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

_tee() {
    # move out to help test
    tee -a $1
}

sys() {
    local CMD=$1
    light_blue "Running system command '${CMD}'"
    # execute a system command, tee'ing the results to the log file
    ORIG_INDENT="${INDENT}" && INDENT=""
    log "---------------------system command output-----------------------"
    if [ -f "$LOG_FILE" ]; then
        ${CMD} 2>&1 | _tee "$LOG_FILE"
    else
        ${CMD} 2>&1
    fi
    log "---------------------end system command output-------------------"
    INDENT="${ORIG_INDENT}"
}

check_archive_file() {
    if [ $# -ne 2 ]; then
        abort "You must pass in both FILE_DEST and FILE_SRC"
    fi
    local FILE_DEST=$1
    local FILE_SRC=$2
    if [ ! -e "${FILE_DEST}" ]; then
        download_apache_file "${FILE_DEST}" "${FILE_SRC}" && \
        download_apache_file "${FILE_DEST}.asc" "${FILE_SRC}.asc" && \
        verify_apache_file "${FILE_DEST}" "${FILE_DEST}.asc"
    else
        light_blue "Using existing file ${FILE_DEST}"
    fi
}

_curl() {
    # wrapper for curl
    $CURL -L "$2" -o "$1"
}

download_apache_file() {
    local DEST=$1
    local SRC=$2
    if [ $# -ne 2 ]; then
        abort "You need a DEST and a SRC to call download_apache_file"
    fi
    if [ -f "${DEST}" ]; then
        abort "${DEST} already exists, not downloading"
    fi
    check_curl
    light_blue "Downloading ${SRC} to ${DEST}"
    light_blue "Please wait..."
    if $(_curl "${DEST}" "${SRC}"); then
        true
    else
        abort "Could not download ${SRC}"
    fi
}

_gpg() {
    local SIG=$1
    local FILE=$2
    $GPG --verify "$1" "$2"
}

verify_apache_file() {
    local FILE=$1
    local SIG=$2
    if [ $# -ne 2 ]; then
        abort "You must pass in both file and signature locations"
    fi
    if [ ! -z "$SKIP_VERIFY" ]; then
        light_blue "Verification skipped by user option"
        return 0
    fi
    if [ ! -f "$FILE" ]; then
        abort "${FILE} not found, verification failed"
    fi
    if [ ! -f "${SIG}" ]; then
        abort "${SIG} not found, verification failed"
    fi
    check_gpg
    light_blue "Verifying the signature of ${FILE}"
    if $(_gpg "${SIG} ${FILE}"); then
        light_blue "Verification passed"
    else
        red "Verification failed"
        local cont=""
        while [[ ! "${cont}" =~ "[ynYN]" ]]; do
            cont=$(read_input "Do you want to continue anyway [y/n]")
        done
        if [ "${cont}" == "y" ] || [ "${cont}" == "Y" ]; then
            light_blue "Ok, installing unverified file"
        else
            abort "Review output above for more info on the verification failure.  You may also refer to http://www.apache.org/info/verification.html.  You may also use the --skip-verify option at your own risk" "${INDENT}"
        fi
    fi
}

# END utils.sh
