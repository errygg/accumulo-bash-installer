#!/bin/bash

shopt -s compat31

# include the other modules
_script_dir() {
    if [ -z "${SCRIPT_DIR}" ]; then
    # even resolves symlinks, see
    # http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
        local SOURCE="${BASH_SOURCE[0]}"
        while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
        SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    fi
    echo "${SCRIPT_DIR}"
}
source "$(_script_dir)/utils.sh"
source "$(_script_dir)/pre_install.sh"
source "$(_script_dir)/hadoop.sh"
source "$(_script_dir)/zookeeper.sh"
source "$(_script_dir)/accumulo.sh"
source "$(_script_dir)/post_install.sh"

# setup some variables
ARCHIVE_DIR="${HOME}/.accumulo-install-archive" # default
LOG_FILE="${ARCHIVE_DIR}/install-$(date +'%Y%m%d%H%M%S').log"
APACHE_MIRROR="http://mirror.atlanticmetro.net/apache"
HADOOP_VERSION="0.20.2"
HADOOP_MIRROR="${APACHE_MIRROR}/hadoop/common/hadoop-${HADOOP_VERSION}"
ZOOKEEPER_VERSION="3.3.3"
ZOOKEEPER_MIRROR="${APACHE_MIRROR}/zookeeper/zookeeper-${ZOOKEEPER_VERSION}"
ACCUMULO_VERSION="1.4.0"
ACCUMULO_MIRROR="${APACHE_MIRROR}/accumulo/${ACCUMULO_VERSION}"

set_config_file() {
    test -f $1 || abort "invalid config file, '$1' does not exist"
    CONFIG_FILE=$1
}

set_install_dir() {
    test ! -d $1 || abort "Directory '$1' already exists. You must install to a new directory."
    INSTALL_DIR=$1
}

set_archive_dir() {
    ARCHIVE_DIR=$1
}

usage () {
  # TODO: add options here.  Make passed in options override -f options
  # TODO: add option to skip verification here, tests and args
    cat <<-EOF
  Usage:  ./$(basename $0) [options]

  Description: Installs Hadoop, Zookeeper and Accumulo in one directory
               and configures them for local development.  A log file is
               created and the location is displayed if you want to review
               the install.

  Options:

    -h                  display this message
    -f <config_file>    load configs from instead of prompting
    -d, --directory     sets install directory, must not exist
    -a, --archive-dir   sets the archive directory, defaults to
                        ${ARCHIVE_DIR}

EOF
}

install () {
    green "The Accumulo Installer Script...."
    INDENT="  "
    # TODO: remove from here and put in abort or post_install
    light_blue "Review this install at ${LOG_FILE}"
    pre_install
    install_hadoop
    install_zookeeper
    install_accumulo
    post_install
}

# parse args here
while test $# -ne 0; do
    arg=$1; shift
    case $arg in
        --no-run) NO_RUN=1 ;; # allows sourcing without a run
        -h) usage; exit 0 ;;
        -f) set_config_file $1; shift ;;
        -d|--directory) set_install_dir $1; shift ;;
        -a|--archive-dir) set_archive_dir $1; shift ;;
        *)
            usage
            abort "ERROR - unknown option : ${arg}"
            ;;
    esac
done

# make sure archive directory exists
if [ ! -d "${ARCHIVE_DIR}" ]; then
    echo "Creating archive dir ${ARCHIVE_DIR}"
    mkdir "${ARCHIVE_DIR}"
else
    echo "Archive dir ${ARCHIVE_DIR} exists"
fi

if [ -z $NO_RUN ]; then
    install $*
else
    # useful for testing
    blue "--no-run passed in, dumping configs"
    blue "ARCHIVE_DIR: ${ARCHIVE_DIR}"
    blue "INSTALL_DIR: ${INSTALL_DIR}"
    blue "CONFIG_FILE: ${CONFIG_FILE}"
fi
