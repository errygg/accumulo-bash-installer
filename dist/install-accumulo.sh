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

<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> a9501cb... Dist command replacing files now
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
# START apache_downloader.sh

verify_file() {
    local FILE=$1
    local SIG=$2
    check_gpg
    light_blue "Verifying the signature of ${FILE}"
    $GPG --verify "${SIG}" "${FILE}"
    local verified=$?
    if [ "$verified" -gt 0 ]; then
        red "Verification failed"
        local loop=0
        local cont=""
        while [ "$loop" -lt 1 ]; do
            cont=$(read_input "Do you want to continue anyway [y/n]")
            if [ "${cont}" == "y" ] || [ "${cont}" == "n" ] || [ "${cont}" == "Y" ] || [ "${cont}" == "N" ]; then
                loop=1
            fi
        done
        if [ "${cont}" == "y" ] || [ "${cont}" == "Y" ]; then
            light_blue "Ok, installing unverified file"
        else
            abort "Review output above for more info on the verification failure.  You may also refer to http://www.apache.org/info/verification.html" "${INDENT}"
        fi
    else
        light_blue "Verification passed"
    fi
}

download_file() {
    local DEST=$1
    local SRC=$2
    check_curl
    # get the file
    light_blue "Downloading ${SRC} to ${DEST}"
    light_blue "Please wait..."
    if $CURL -L "${SRC}" -o "${DEST}"; then
        true
    else
        abort "Could not download ${SRC}"
    fi
}

<<<<<<< HEAD
=======
>>>>>>> a97c66c... Reorg folders
=======
ensure_file() {
    local FILE_DEST=$1
    local FILE_SRC=$2
    if [ ! -e "${FILE_DEST}" ]; then
        download_file "${FILE_DEST}" "${FILE_SRC}" "${INDENT}"
        if [ ! -e "${FILE_DEST}.asc" ]; then
            download_file "${FILE_DEST}.asc" "${FILE_SRC}.asc" "${INDENT}"
        fi
        light_blue "Verifying ${FILE_DEST}"
        verify_file "${FILE_DEST}" "${FILE_DEST}.asc"
    else
        light_blue "Using existing file ${FILE_DEST}"
    fi

}

# END apache_downloader.sh

# START pre_install.sh

<<<<<<< HEAD
setup_configs () {
>>>>>>> b86e42e... Reorg complete, for now
    log
    local INDENT="  "
    yellow "Setting up configuration and checking requirements..." "${INDENT}"
    INDENT="    "
=======
_uname() {
    # wrapper so I can replace in tests
    echo "$(uname)"
}

check_os() {
>>>>>>> eb44746... Update the dist file
  # check os
    local PLATFORM=`_uname`
    case $PLATFORM in
        "Darwin") light_blue "You are installing to OS: ${PLATFORM}" ;;
        *)
            abort "Installer does not support ${PLATFORM}"
    esac
}

check_config_file() {
    # check for a config file
    if [ -z $CONFIG_FILE ]; then
        light_blue  "No config file found, we will get them from you now"
    else
        light_blue "Using $CONFIG_FILE.  Here is the contents"
        cat "${CONFIG_FILE}"
        source "${CONFIG_FILE}"
    fi
}

get_install_dir() {
  # get install directory
    if [ -z $INSTALL_DIR ]; then
        while [ "${INSTALL_DIR}x" == "x" ]; do
            INSTALL_DIR=$(read_input "Enter install directory")
        done
    else
        light_blue "Install directory already set to ${INSTALL_DIR}"
    fi

  # check install direcotry
    if [ -d "$INSTALL_DIR" ]; then
        abort "Directory '${INSTALL_DIR}' already exists. You must install to a new directory."
    else
        light_blue "Creating directory ${INSTALL_DIR}"
        mkdir -p "${INSTALL_DIR}"
    fi
}

get_hdfs_dir() {
    if [ "${INSTALL_DIR}x" == "x" ]; then
        abort "INSTALL_DIR is not set"
    fi
    if [ ! -d "$INSTALL_DIR" ]; then
        abort "Install dir ${INSTALL_DIR} does not exist"
    fi
    # assign HDFS_DIR
    HDFS_DIR="${INSTALL_DIR}/hdfs"
    light_blue "Making HDFS directory ${HDFS_DIR}"
    mkdir "${HDFS_DIR}"
}

get_java_home() {
  # get java_home
    if [ -z $JAVA_HOME ]; then
        JAVA_HOME=$(read_input "Enter JAVA_HOME location")
    fi

  # check java_home
    if [ ! -d $JAVA_HOME ]; then
        abort "JAVA_HOME does not exist: ${JAVA_HOME}"
    else
        light_blue "JAVA_HOME set to ${JAVA_HOME}"
    fi
}

_hostname() {
    # wrapper so it can easily be replaced in testing
    echo $(hostname)
}

_ssh() {
    # wrapper so it can easily be replaced in testing
    # this function sets publickey as the only authentication, which is
    # the passwordless way Hadoop communicates in psuedo distributed mode
    echo $(ssh -o 'PreferredAuthentications=publickey' localhost "hostname")
}

check_ssh() {
  # check ssh localhost
    light_blue "Checking passwordless SSH (for Hadoop)"
    local HOSTNAME=$(_hostname)
    local SSH_HOST=$(_ssh)
    if [[ "${HOSTNAME}" == "${SSH_HOST}" ]]; then
        light_blue "SSH appears good"
    else
        abort "Problem with SSH, expected ${HOSTNAME}, but got ${SSH_HOST}. Please see http://hadoop.apache.org/common/docs/r0.20.2/quickstart.html#Setup+passphraseless"
    fi
}

pre_install () {
    log
    INDENT="  "
    light_blue "Setting up configuration and checking requirements..."
    INDENT="    "

    check_os
    check_config_file
    get_install_dir
    get_hdfs_dir
    get_java_home
    check_ssh
  # TODO: ask which version of accumulo.  Need a good way to manage
}

# END pre_install.sh
# START hadoop.sh

install_hadoop() {
    INDENT="  "

    # hadoop archive file
    local HADOOP_FILENAME="hadoop-${HADOOP_VERSION}.tar.gz"
    local HADOOP_SOURCE="${HADOOP_MIRROR}/${HADOOP_FILENAME}"
    local HADOOP_DEST="${ARCHIVE_DIR}/${HADOOP_FILENAME}"

    log
    light_blue "Installing Hadoop..."
    INDENT="    "
    ensure_file "${HADOOP_DEST}" "${HADOOP_SOURCE}"

    # install from archive
    light_blue "Extracting ${HADOOP_DEST} to ${INSTALL_DIR}"
    sys "tar -xzf ${HADOOP_DEST} -C ${INSTALL_DIR}"

    # setup directory
    local HADOOP_DIR="${INSTALL_DIR}/hadoop-${HADOOP_VERSION}"
    local HADOOP_HOME="${INSTALL_DIR}/hadoop"
    light_blue "Setting up ${HADOOP_HOME}" "${INDENT}"
    sys "ln -s ${HADOOP_DIR} ${HADOOP_HOME}"

    # configure properties, these are very specific to the version
    light_blue "Configuring hadoop"
    INDENT="      "
    local HADOOP_CONF="${HADOOP_HOME}/conf"

    light_blue "Setting up core-site.xml"
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

    light_blue "Setting up mapred-site.xml"
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

    light_blue "Setting up hdfs-site.xml"
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

    light_blue "Setting up hadoop-env.sh"
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
    light_blue "Formatting namenode"
    sys "${HADOOP_HOME}/bin/hadoop namenode -format"

    # start hadoop
    log ""
    light_blue "Starting hadoop"
    sys "${HADOOP_HOME}/bin/start-all.sh"

    # test installation
    log ""
    light_blue "Testing hadoop"
    INDENT="        "
    light_blue "Creating a /user/test directory in hdfs"
    sys "${HADOOP_HOME}/bin/hadoop fs -mkdir /user/test"

    light_blue "Ensure the directory was created with 'fs -ls /user'"
    local hadoop_check=$("${HADOOP_HOME}/bin/hadoop" fs -ls /user)
    if [[ "${hadoop_check}" =~ .*/user/test ]]; then
        light_blue "Check looks good, removing directory"
        sys "${HADOOP_HOME}/bin/hadoop fs -rmr /user/test"
    else
        abort "Unable to create the directory in HDFS"
    fi

    INDENT="  "
    green "Hadoop is installed and running"
}

# END hadoop.sh
# START zookeeper.sh

install_zookeeper() {
    log
    INDENT="  "
    light_blue "Installing Zookeeper..."
    INDENT="    "
    # ensure file in archive directory
    # install from archive
    # configure properties
    # start zookeeper
    # test installation
}

# END zookeeper.sh
# START accumulo.sh

install_accumulo() {
    log
    INDENT="  "
    light_blue "Installing Accumulo..."
    INDENT="    "
    # ensure file in archive directory
    # install from archive
    # configure properties
    # start zookeeper
    # test installation
}

# END accumulo.sh
# START post_install.sh

post_install() {
    log
    INDENT="  "
    light_blue "Running post install...."
    INDENT="    "
    # setup bin directory
    # add helpers
    # message about sourcing accumulo-env
    # add timestamp to running and user
    move_log_file
}

# END post_install.sh

# setup some variables
ARCHIVE_DIR="${HOME}/.accumulo-install-archive"
LOG_FILE="${ARCHIVE_DIR}/install-$(date +'%Y%m%d%H%M%S').log"
HADOOP_VERSION="0.20.2"
HADOOP_MIRROR="http://mirror.atlanticmetro.net/apache/hadoop/common/hadoop-${HADOOP_VERSION}"

set_config_file() {
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
    INDENT="  "
    # TODO: remove from here and put in abort or post_install
    light_blue "Review this install at ${LOG_FILE}"
    pre_install
    install_hadoop
    install_zookeeper
    install_accumulo
    post_install
}

# make sure archive directory exists
if [ ! -d "${ARCHIVE_DIR}" ]; then
    echo "Creating archive dir ${ARCHIVE_DIR}"
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
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
# built 12.03.27 15:55:45 by Michael Wall
=======
# built 12.03.27 13:33:47 by Michael Wall
>>>>>>> a97c66c... Reorg folders
=======
# built 12.03.27 15:55:45 by Michael Wall
>>>>>>> a9501cb... Dist command replacing files now
=======
# built 12.03.27 17:49:48 by Michael Wall
>>>>>>> b86e42e... Reorg complete, for now
=======
# built 12.03.27 22:08:34 by Michael Wall
>>>>>>> 1c53b47... Start refactoring test
=======
# built 12.03.27 22:09:38 by Michael Wall
>>>>>>> 913a4d0... Finish reorg of code and tests.
=======
# built 12.04.04 21:31:09 by Michael Wall
>>>>>>> eb44746... Update the dist file
