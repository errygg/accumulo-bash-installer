#!/bin/bash

ARCHIVE_DIR="${HOME}/.accumulo-install-archive"

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
    if [[ -n $INSTALL_DIR ]]; then
    #TODO test this with configs and options
        log "Install directory already set to ${INSTALL_DIR}" "${INDENT}"
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

download_file() {
    local DEST_LOC=$1
    local SOURCE_LOC=$2
    local SOURCE_ASC=$3
    local INDENT="      "
    log "Downloading ${SOURCE_LOC} to ${DEST_LOC}" "${INDENT}"
    log "Please wait..." "${INDENT}"
    # test to see if curl is installed
    # run curl script here
}

verify_file() {
    # add option to skip verification
    # test to see if gpg is install
    # yes
    #  try to verify key
    #    gpg ASC_FILE
    #  if return status 2
    #    grab key and install
    #      curl -l http://mirrors.ibiblio.org/apache/hadoop/common/KEYS ARCHIVE_DIR/KEYS
    #      gpg --import KEYS
    #    grab asc file
    #      curl -l ASC_FILE ARCHIVE_DIR/filename.asc
    #    verify again
    #      gpg ASC_FILE
    #      back to start
    #  if return status 0
    #    file is good
    #  else
    #    file is bad
    #    remove if signature fails and abort
    # no
    #  give warning
    # TOO MUCH
    # try once, give warning and link if fails, ask if want to continue and then do so
    # see http://www.apache.org/info/verification.html
    # gpg --verify asc_file data_file
}

install_hadoop() {
    local INDENT="  "
    local HADOOP_VERSION="0.20.2"
    local HADOOP_FILENAME="hadoop-${HADOOP_VERSION}.tar.gz"
    local HADOOP_MIRROR="http://mirrors.ibiblio.org/apache/hadoop/common/hadoop-0.20.2"
    local HADOOP_DOWNLOAD="${HADOOP_MIRROR}/${HADOOP_FILENAME}"
    local HADOOP_ASC="${HADOOP_DOWNLOAD}.asc"
    local ARCHIVE_FILE="${ARCHIVE_DIR}/${HADOOP_FILENAME}"
    log
    log "Installing Hadoop..." "${INDENT}"
    INDENT="    "
    # ensure file in archive directory
    log "Checking for install file ${HADOOP_FILENAME}" "${INDENT}"
    INDENT="      "
    if [ ! -e "${ARCHIVE_FILE}" ]; then
        download_file "${ARCHIVE_FILE}" "${HADOOP_DOWNLOAD}" "${HADOOP_ASC}"
    else
        log "Using ${ARCHIVE_FILE}" "${INDENT}"
    fi
    verify_file "${ARCHIVE_FILE}" "${HADOOP_ASC}"
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

  Options:

    -h                  display this message
    -f <config_file>    load configs from instead of prompting

EOF
}

main () {
    green "The Accumulo Installer Script...."
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
        -h) usage; exit 0 ;;
        -f) set_config_file $1; shift ;;
        *)
            usage
            abort "ERROR - unknown option : ${arg}"
            ;;
    esac
done

main $*
