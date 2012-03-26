#!/bin/bash

ARCHIVE_DIR="${HOME}/.accumulo-install-archive"
LOG_FILE="${ARCHIVE_DIR}/install-$(date +'%Y%m%d%H%M%S').log"

cleanup_from_abort() {
    # stop accumulo if running
    # stop zookeeper if running
    # stop hadoop if running
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
    echo -n -e "\033[1;${COLOR}m"
    log "${MESSAGE}"
    echo -n -e "\033[0m"
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

setup_configs () {
    log
    local INDENT="  "
    log "Setting up configuration and checking requirements..." "${INDENT}"
    INDENT="    "
  # check os
    local PLATFORM=`uname`
    case $PLATFORM in
        "Darwin") log "You are installing to OS: ${PLATFORM}" "${INDENT}";;
        *)
            abort "Installer does not support ${PLATFORM}" "${INDENT}"
    esac

  # check for a config file
    if [ -n "${CONFIG_FILE}" ]; then
        log "Using $CONFIG_FILE.  Here is the contents" "${INDENT}"
        cat $CONFIG_FILE
    else
        log "No config file found, we will get them from you now" "${INDENT}"
    fi

  # get install directory
    if [ -n $INSTALL_DIR ]; then
    #TODO test this with configs and options
        log "Install directory set to ${INSTALL_DIR} by command line option" "${INDENT}"
    else
        while [ "${INSTALL_DIR}x" == "x" ]; do
            INSTALL_DIR=$(read_input "Enter install directory" "${INDENT}")
        done
    fi

  # check install direcotry
    if [ -d $INSTALL_DIR ]; then
        abort "Directory '${INSTALL_DIR}' already exists. You must install to a new directory." "${INDENT}"
    else
        log "Creating directory ${INSTALL_DIR}" "${INDENT}"
        mkdir -p "${INSTALL_DIR}"
    fi

  # get java_home
    if [ ! -n $JAVA_HOME ]; then
        JAVA_HOME=$(read_input "Enter JAVA_HOME location" "${INDENT}")
    fi

  # check java_home
    if [ ! -d $JAVA_HOME ]; then
        abort "JAVA_HOME does not exist: ${JAVA_HOME}" "${INDENT}"
    else
        log "JAVA_HOME set to ${JAVA_HOME}" "${INDENT}"
    fi

  # check ssh localhost
    log "Checking passwordless SSH (for Hadoop)" "${INDENT}"
    local HOSTNAME=$(hostname)
    local SSH_HOST=$(ssh -o 'PreferredAuthentications=publickey' localhost "hostname")
    if [[ "${HOSTNAME}" == "${SSH_HOST}" ]]; then
        log "SSH appear good" "${INDENT}"
    else
        abort "Problem with SSH, expected ${HOSTNAME}, but got ${SSH_HOST}. Please see http://hadoop.apache.org/common/docs/r0.20.2/quickstart.html#Setup+passphraseless" "${INDENT}"
    fi

    if [ ! -d "${ARCHIVE_DIR}" ]; then
        log "Creating archive dir ${ARCHIVE_DIR}" "${INDENT}"
        mkdir "${ARCHIVE_DIR}"
    fi

  # TODO: ask which version of accumulo.  Need a good way to manage
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

verify_file() {
    local FILE=$1
    local SIG=$2
    local INDENT=$3
    log "Verifying the signature of ${FILE}" "${INDENT}"
    gpg --verify "${SIG}" "${FILE}"
    local verified=$?
    if [ "$verified" -gt 0 ]; then
        red "Verification failed" "${INDENT}"
        local loop=0
        local cont=""
        while [ "$loop" -lt 1 ]; do
            cont=$(read_input "Do you want to continue anyway [y/n]" "${INDENT}")
            if [ "${cont}" == "y" ] || [ "${cont}" == "n" ] || [ "${cont}" == "Y" ] || [ "${cont}" == "N"]; then
                loop=1
            fi
        done
        if [ "${cont}" == "y" ] || [ "${cont}" == "Y" ]; then
            log "Ok, installing unverified file" "${INDENT}"
        else
            abort "Review output above for more info on the verification failure.  You may also refer to http://www.apache.org/info/verification.html" "${INDENT}"
        fi
    else
        log "Verification passed" "${INDENT}"
    fi
}

download_file() {
    local DEST=$1
    local SRC=$2
    local INDENT=$3
    check_curl
    # get the file
    log "Downloading ${SRC} to ${DEST}" "${INDENT}"
    log "Please wait..." "${INDENT}"
    if curl -L "${SRC}" -o "${DEST}"; then
        true
    else
        abort "Could not download ${SRC}"
    fi
}

ensure_file() {
    local FILE_DEST=$1
    local FILE_SRC=$2
    local INDENT=$3
    if [ ! -e "${FILE_DEST}" ]; then
        download_file "${FILE_DEST}" "${FILE_SRC}" "${INDENT}"
        if [ ! -e "${FILE_DEST}.asc" ]; then
            download_file "${FILE_DEST}.asc" "${FILE_SRC}.asc" "${INDENT}"
        fi
        log "Verifying ${FILE_DEST}"
        verify_file "${FILE_DEST}" "${FILE_DEST}.asc" "${INDENT}"
    else
        log "Using file ${FILE_DEST}" "${INDENT}"
    fi

}


install_hadoop() {
    local INDENT="  "
    local HADOOP_VERSION="0.20.2"
    local MIRROR="http://mirrors.ibiblio.org/apache/hadoop/common/hadoop-${HADOOP_VERSION}"

    # hadoop archive file
    local HADOOP_FILENAME="hadoop-${HADOOP_VERSION}.tar.gz"
    local HADOOP_SOURCE="${MIRROR}/${HADOOP_FILENAME}"
    local HADOOP_DEST="${ARCHIVE_DIR}/${HADOOP_FILENAME}"

    log
    log "Installing Hadoop..." "${INDENT}"
    INDENT="    "
    ensure_file "${HADOOP_DEST}" "${HADOOP_SOURCE}" "${INDENT}"
    # install from archive
    # configure properties
    # start hadoop
    # test installation
}

install_zookeeper() {
    log
    local INDENT="  "
    log "Installing Zookeeper..." "${INDENT}"
    INDENT="    "
    # ensure file in archive directory
    # install from archive
    # configure properties
    # start zookeeper
    # test installation
}

install_accumulo() {
    log
    local INDENT="  "
    log "Installing Accumulo..." "${INDENT}"
    INDENT="    "
    # ensure file in archive directory
    # install from archive
    # configure properties
    # start zookeeper
    # test installation
}

post_install() {
    log
    local INDENT="  "
    log "Running post install...." "${INDENT}"
    INDENT="    "
    # setup bin directory
    # add helpers
    # message about sourcing accumulo-env
    cleanup_from_abort #TODO: remove once this script is working
}

set_config_file () {
    test -f $1 || abort "invalid config file, '$1' does not exist"
    CONFIG_FILE=$1
}

usage () {
  # TODO: add options here.  Make passed in options override -f options
    cat <<-EOF
  Usage:  ./install-accumulo.sh [options]

  Description: Installs Hadoop, Zookeeper and Accumulo in one directory
               and configures them for local development.  A log file is
               stored in ${ARCHIVE_DIR}
               if you want to review the install

  Options:

    -h                  display this message
    -f <config_file>    load configs from instead of prompting
    -d, --directory     sets install directory, must not exist

EOF
}

install () {
    green "The Accumulo Installer Script...."
    log "Review this install at ${LOG_FILE}" "  "
    setup_configs
    install_hadoop
    install_zookeeper
    install_accumulo
    post_install
}

# parse args here
while test $# -ne 0; do
    arg=$1; shift
    case $arg in
        --no-run) NO_RUN=1; shift ;; # allows sourcing without a run
        -h) usage; exit 0 ;;
        -f) set_config_file $1; shift ;;
        -d|--directory) INSTALL_DIR=$1; shift ;;
        *)
            usage
            abort "ERROR - unknown option : ${arg}"
            ;;
    esac
done

if [ -z $NO_RUN ]; then
  install $*
fi
