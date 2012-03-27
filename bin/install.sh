#!/bin/bash

shopt -s compat31

# include the other modules
SCRIPT_DIR=$(dirname $0)
source "${SCRIPT_DIR}/utils.sh"
source "${SCRIPT_DIR}/apache_downloader.sh"
source "${SCRIPT_DIR}/pre_install.sh"
source "${SCRIPT_DIR}/hadoop.sh"
source "${SCRIPT_DIR}/zookeeper.sh"
source "${SCRIPT_DIR}/accumulo.sh"
source "${SCRIPT_DIR}/post_install.sh"

# setup some variables
ARCHIVE_DIR="${HOME}/.accumulo-install-archive"
LOG_FILE="${ARCHIVE_DIR}/install-$(date +'%Y%m%d%H%M%S').log"
HADOOP_VERSION="0.20.2"
HADOOP_MIRROR="http://mirror.atlanticmetro.net/apache/hadoop/common/hadoop-${HADOOP_VERSION}"

set_config_file () {
    test -f $1 || abort "invalid config file, '$1' does not exist"
    CONFIG_FILE=$1
}

set_install_dir() {
    test ! -d $1 || abort "Directory '$1' already exists. You must install to a new directory."
    INSTALL_DIR=$1
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
    yellow "Review this install at ${LOG_FILE}" "  "
    setup_configs
    install_hadoop
    install_zookeeper
    install_accumulo
    post_install
}

# make sure archive directory exists
if [ ! -d "${ARCHIVE_DIR}" ]; then
    echo "Creating archive dir ${ARCHIVE_DIR}" "${INDENT}"
    mkdir "${ARCHIVE_DIR}"
fi

# parse args here
while test $# -ne 0; do
    arg=$1; shift
    case $arg in
        --no-run) NO_RUN=1; shift ;; # allows sourcing without a run
        -h) usage; exit 0 ;;
        -f) set_config_file $1; shift ;;
        -d|--directory) set_install_dir $1; shift ;;
        *)
            usage
            abort "ERROR - unknown option : ${arg}"
            ;;
    esac
done

if [ -z $NO_RUN ]; then
    install $*
else
    # useful for testing
    blue "--no-run passed in, dumping configs"
    blue "INSTALL_DIR: ${INSTALL_DIR}"
    blue "CONFIG_FILE: ${CONFIG_FILE}"
fi
