#!/bin/bash

shopt -s compat31

ARCHIVE_DIR="${HOME}/.accumulo-install-archive"
LOG_FILE="${ARCHIVE_DIR}/install-$(date +'%Y%m%d%H%M%S').log"
HADOOP_VERSION="0.20.2"
HADOOP_MIRROR="http://mirror.atlanticmetro.net/apache/hadoop/common/hadoop-${HADOOP_VERSION}"

cleanup_from_abort() {
    if [ ! -z NO_RUN ]; then
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

setup_configs () {

    log
    local INDENT="  "
    yellow "Setting up configuration and checking requirements..." "${INDENT}"
    INDENT="    "
  # check os
    local PLATFORM=`uname`
    case $PLATFORM in
        "Darwin") yellow "You are installing to OS: ${PLATFORM}" "${INDENT}";;
        *)
            abort "Installer does not support ${PLATFORM}" "${INDENT}"
    esac

  # check for a config file
    if [ -n "${CONFIG_FILE}" ]; then
        yellow "Using $CONFIG_FILE.  Here is the contents" "${INDENT}"
        cat $CONFIG_FILE
    else
        yellow  "No config file found, we will get them from you now" "${INDENT}"
    fi

  # get install directory
    if [ -n "${INSTALL_DIR}" ]; then
    #TODO test this with configs and options
        yellow "Install directory set to ${INSTALL_DIR} by command line option" "${INDENT}"
    else
        while [ "${INSTALL_DIR}x" == "x" ]; do
            INSTALL_DIR=$(read_input "Enter install directory" "${INDENT}")
        done
    fi

  # check install direcotry
    if [ -d $INSTALL_DIR ]; then
        abort "Directory '${INSTALL_DIR}' already exists. You must install to a new directory." "${INDENT}"
    else
        yellow "Creating directory ${INSTALL_DIR}" "${INDENT}"
        mkdir -p "${INSTALL_DIR}"
    fi

  # assign HDFS_DIR
    HDFS_DIR="${INSTALL_DIR}/hdfs"
    yellow "Making HDFS directory ${HDFS_DIR}" "${INDENT}"
    mkdir -p "${HDFS_DIR}"

  # get java_home
    if [ ! -n "${JAVA_HOME}" ]; then
        JAVA_HOME=$(read_input "Enter JAVA_HOME location" "${INDENT}")
    fi

  # check java_home
    if [ ! -d $JAVA_HOME ]; then
        abort "JAVA_HOME does not exist: ${JAVA_HOME}" "${INDENT}"
    else
        yellow "JAVA_HOME set to ${JAVA_HOME}" "${INDENT}"
    fi

  # check ssh localhost
    yellow "Checking passwordless SSH (for Hadoop)" "${INDENT}"
    local HOSTNAME=$(hostname)
    local SSH_HOST=$(ssh -o 'PreferredAuthentications=publickey' localhost "hostname")
    if [[ "${HOSTNAME}" == "${SSH_HOST}" ]]; then
        yellow "SSH appears good" "${INDENT}"
    else
        abort "Problem with SSH, expected ${HOSTNAME}, but got ${SSH_HOST}. Please see http://hadoop.apache.org/common/docs/r0.20.2/quickstart.html#Setup+passphraseless" "${INDENT}"
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
    yellow "Verifying the signature of ${FILE}" "${INDENT}"
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
            yellow "Ok, installing unverified file" "${INDENT}"
        else
            abort "Review output above for more info on the verification failure.  You may also refer to http://www.apache.org/info/verification.html" "${INDENT}"
        fi
    else
        yellow "Verification passed" "${INDENT}"
    fi
}

download_file() {
    local DEST=$1
    local SRC=$2
    local INDENT=$3
    check_curl
    # get the file
    yellow "Downloading ${SRC} to ${DEST}" "${INDENT}"
    yellow "Please wait..." "${INDENT}"
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
        yellow "Verifying ${FILE_DEST}"
        verify_file "${FILE_DEST}" "${FILE_DEST}.asc" "${INDENT}"
    else
        yellow "Using existing file ${FILE_DEST}" "${INDENT}"
    fi

}


install_hadoop() {
    local INDENT="  "

    # hadoop archive file
    local HADOOP_FILENAME="hadoop-${HADOOP_VERSION}.tar.gz"
    local HADOOP_SOURCE="${HADOOP_MIRROR}/${HADOOP_FILENAME}"
    local HADOOP_DEST="${ARCHIVE_DIR}/${HADOOP_FILENAME}"

    log
    yellow "Installing Hadoop..." "${INDENT}"
    INDENT="    "
    ensure_file "${HADOOP_DEST}" "${HADOOP_SOURCE}" "${INDENT}"

    # install from archive
    yellow "Extracting ${HADOOP_DEST} to ${INSTALL_DIR}" "${INDENT}"
    tar -xzf "${HADOOP_DEST}" -C "${INSTALL_DIR}"

    # setup directory
    local HADOOP_DIR="${INSTALL_DIR}/hadoop-${HADOOP_VERSION}"
    local HADOOP_HOME="${INSTALL_DIR}/hadoop"
    yellow "Setting up ${HADOOP_HOME}" "${INDENT}"
    ln -s "${HADOOP_DIR}" "${HADOOP_HOME}"

    # configure properties, these are very specific to the version
    yellow "Configuring hadoop" "${INDENT}"
    INDENT="      "
    local HADOOP_CONF="${HADOOP_HOME}/conf"

    yellow "Setting up core-site.xml" "${INDENT}"
    local CORE_SITE=$( cat <<-EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<!-- Put site-specific property overrides in this file. -->

<configuration>
    <property>
        <name>fs.default.name</name>
        <value>hdfs://localhost:9000</value>
    </property>
</configuration>
EOF
)
    echo "${CORE_SITE}" > "${HADOOP_CONF}/core-site.xml"

    yellow "Setting up mapred-site.xml" "${INDENT}"
    local MAPRED_SITE=$( cat <<-EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<!-- Put site-specific property overrides in this file. -->

<configuration>
    <property>
        <name>mapred.job.tracker</name>
        <value>localhost:9001</value>
    </property>
</configuration>
EOF
)
    echo "${MAPRED_SITE}" > "${HADOOP_CONF}/mapred-site.xml"

    yellow "Setting up hdfs-site.xml" "${INDENT}"
    local HDFS_SITE=$( cat <<-EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<!-- Put site-specific property overrides in this file. -->

<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
    <property>
        <name>dfs.name.dir</name>
        <value>${HDFS_DIR}/name</value>
        <final>true</final>
    </property>
    <property>
        <name>dfs.data.dir</name>
        <value>${HDFS_DIR}/data</value>
        <final>true</final>
    </property>
</configuration>

EOF
)
    echo "${HDFS_SITE}" > "${HADOOP_CONF}/hdfs-site.xml"

    yellow "Setting up hadoop-env.sh" "${INDENT}"
    local HADOOP_ENV=$( cat <<-EOF
# Set Hadoop-specific environment variables here.

# The only required environment variable is JAVA_HOME.  All others are
# optional.  When running a distributed configuration it is best to
# set JAVA_HOME in this file, so that it is correctly defined on
# remote nodes.

# The java implementation to use.  Required.
export JAVA_HOME=${JAVA_HOME}
# export JAVA_HOME=/usr/lib/j2sdk1.5-sun

# Extra Java CLASSPATH elements.  Optional.
# export HADOOP_CLASSPATH=

# The maximum amount of heap to use, in MB. Default is 1000.
export HADOOP_HEAPSIZE=2000

# Extra Java runtime options.  Empty by default.
# export HADOOP_OPTS=-server

# Command specific options appended to HADOOP_OPTS when specified
export HADOOP_NAMENODE_OPTS="-Dcom.sun.management.jmxremote $HADOOP_NAMENODE_OPTS"
export HADOOP_SECONDARYNAMENODE_OPTS="-Dcom.sun.management.jmxremote $HADOOP_SECONDARYNAMENODE_OPTS"
export HADOOP_DATANODE_OPTS="-Dcom.sun.management.jmxremote $HADOOP_DATANODE_OPTS"
export HADOOP_BALANCER_OPTS="-Dcom.sun.management.jmxremote $HADOOP_BALANCER_OPTS"
export HADOOP_JOBTRACKER_OPTS="-Dcom.sun.management.jmxremote $HADOOP_JOBTRACKER_OPTS"
# export HADOOP_TASKTRACKER_OPTS=
# The following applies to multiple commands (fs, dfs, fsck, distcp etc)
# export HADOOP_CLIENT_OPTS

# Extra ssh options.  Empty by default.
# export HADOOP_SSH_OPTS="-o ConnectTimeout=1 -o SendEnv=HADOOP_CONF_DIR"

# Where log files are stored.  $HADOOP_HOME/logs by default.
# export HADOOP_LOG_DIR=${HADOOP_HOME}/logs

# File naming remote slave hosts.  $HADOOP_HOME/conf/slaves by default.
# export HADOOP_SLAVES=${HADOOP_HOME}/conf/slaves

# host:path where hadoop code should be rsync'd from.  Unset by default.
# export HADOOP_MASTER=master:/home/$USER/src/hadoop

# Seconds to sleep between slave commands.  Unset by default.  This
# can be useful in large clusters, where, e.g., slave rsyncs can
# otherwise arrive faster than the master can service them.
# export HADOOP_SLAVE_SLEEP=0.1

# The directory where pid files are stored. /tmp by default.
# export HADOOP_PID_DIR=/var/hadoop/pids

# A string representing this instance of hadoop. $USER by default.
# export HADOOP_IDENT_STRING=$USER

# The scheduling priority for daemon processes.  See 'man nice'.
# export HADOOP_NICENESS=10

EOF
)
    echo "${HADOOP_ENV}" > "${HADOOP_CONF}/hadoop-env.sh"

    # format hdfs
    yellow "Formatting namenode" "${INDENT}"
    "${HADOOP_HOME}/bin/hadoop" namenode -format

    # start hadoop
    log ""
    yellow "Starting hadoop" "${INDENT}"
    "${HADOOP_HOME}/bin/start-all.sh"

    # test installation
    log ""
    yellow "Testing hadoop" "${INDENT}"
    INDENT="        "
    yellow "Creating a /user/test directory in hdfs" "${INDENT}"
    "${HADOOP_HOME}/bin/hadoop" fs -mkdir /user/test

    yellow "Ensure the directory was created" "${INDENT}"
    local hadoop_check=$("${HADOOP_HOME}/bin/hadoop" fs -ls /user)
    if [[ "${hadoop_check}" =~ .*/user/test ]]; then
         yellow "Check looks good, removing directory" "${INDENT}"
        "${HADOOP_HOME}/bin/hadoop" fs -rmr /user/test
    else
        abort "Unable to create the directory in HDFS" "$INDENT"
    fi

    green "Hadoop is installed and running" "  "
}

install_zookeeper() {
    log
    local INDENT="  "
    yellow "Installing Zookeeper..." "${INDENT}"
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
    yellow "Installing Accumulo..." "${INDENT}"
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
    yellow "Running post install...." "${INDENT}"
    INDENT="    "
    # setup bin directory
    # add helpers
    # message about sourcing accumulo-env
    #cleanup_from_abort #TODO: remove once this script is working
}

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
